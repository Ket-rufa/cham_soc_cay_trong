<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\File;

class PlantLibraryController extends Controller
{
    private const LIBRARY_IMAGE_DIR = 'uploads/library';

    // API lấy danh sách thư viện (có tìm kiếm)
    public function index(Request $request)
    {
        $keyword = $request->query('keyword');
        $type = $request->query('type');
        $query = DB::table('plant_libraries');

        // Nếu có từ khóa thì lọc, không thì lấy hết
        if ($keyword) {
            $query->where('name', 'LIKE', "%{$keyword}%");
        }

        if ($type) {
            $query->where(function ($builder) use ($type) {
                $builder->where('type', $type)
                    ->orWhereNull('type')
                    ->orWhere('type', '');
            });
        }

        // Lấy danh sách (giới hạn 50 cây để load cho nhanh)
        $plants = $query->limit(50)->get()->map(function ($plant) use ($request) {
            $rawImage = $plant->image_url ?? null;
            $plant->remote_image_url = $this->isRemoteUrl((string) $rawImage)
                ? $this->resolveImageUrl($rawImage, $request)
                : null;
            $plant->image_url = $this->resolveLibraryImageUrl($plant, $request);
            $plant->image_source = $this->isLibraryImageCached($plant)
                ? 'local'
                : 'remote';
            return $plant;
        });

        return response()->json([
            'status' => 200,
            'data' => $plants
        ], 200);
    }

    public function cacheImages(Request $request)
    {
        @set_time_limit(0);

        $plants = DB::table('plant_libraries')
            ->select('id', 'name', 'image_url')
            ->orderBy('id')
            ->get();

        $results = [];
        $cached = 0;
        $failed = 0;
        $skipped = 0;

        foreach ($plants as $plant) {
            usleep(350000);

            $existingPath = $this->findCachedLibraryImagePath((int) $plant->id);
            if ($existingPath !== null) {
                DB::table('plant_libraries')
                    ->where('id', $plant->id)
                    ->update(['image_url' => $existingPath]);

                $skipped++;
                $results[] = [
                    'id' => $plant->id,
                    'name' => $plant->name,
                    'status' => 'already_cached',
                    'path' => $existingPath,
                    'url' => $this->resolveImageUrl($existingPath, $request),
                ];
                continue;
            }

            $rawUrl = trim((string) ($plant->image_url ?? ''));
            if (!$this->isRemoteUrl($rawUrl)) {
                $skipped++;
                $results[] = [
                    'id' => $plant->id,
                    'name' => $plant->name,
                    'status' => 'skipped_not_remote',
                    'path' => $rawUrl,
                ];
                continue;
            }

            $cachedPath = $this->cacheRemoteLibraryImage($plant, $rawUrl);
            if ($cachedPath === null) {
                $failed++;
                $results[] = [
                    'id' => $plant->id,
                    'name' => $plant->name,
                    'status' => 'failed',
                    'remote_url' => $rawUrl,
                ];
                continue;
            }

            DB::table('plant_libraries')
                ->where('id', $plant->id)
                ->update(['image_url' => $cachedPath]);

            $cached++;
            $results[] = [
                'id' => $plant->id,
                'name' => $plant->name,
                'status' => 'cached',
                'path' => $cachedPath,
                'url' => $this->resolveImageUrl($cachedPath, $request),
            ];
        }

        return response()->json([
            'status' => 200,
            'message' => 'Library image cache finished',
            'cached' => $cached,
            'failed' => $failed,
            'skipped' => $skipped,
            'data' => $results,
        ], 200);
    }

    public function imageProxy(Request $request)
    {
        $url = trim((string) $request->query('url', ''));
        if ($url === '' || !preg_match('/^https?:\/\//i', $url)) {
            return response('Invalid image URL', 400);
        }

        try {
            $response = Http::withHeaders([
                'User-Agent' => 'ChamSocCayTrong/1.0 image proxy',
                'Accept' => 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
                'Referer' => 'https://commons.wikimedia.org/',
            ])->timeout(15)->get($url);

            if (!$response->successful()) {
                return response('Image fetch failed', $response->status());
            }

            $contentType = $response->header('Content-Type', 'image/jpeg');
            if (!str_starts_with(strtolower($contentType), 'image/')) {
                return response('URL is not an image', 415);
            }

            return response($response->body(), 200, [
                'Content-Type' => $contentType,
                'Cache-Control' => 'public, max-age=86400',
            ]);
        } catch (\Throwable $e) {
            return response('Image proxy error: ' . $e->getMessage(), 502);
        }
    }

    private function resolveImageUrl(?string $url, Request $request): ?string
    {
        $trimmed = trim((string) $url);
        if ($trimmed === '' || strtolower($trimmed) === 'null') {
            return null;
        }

        $trimmed = str_replace('\\', '/', $trimmed);
        $baseUrl = $request->getSchemeAndHttpHost();

        if (str_starts_with($trimmed, '//')) {
            return $request->getScheme() . ':' . $trimmed;
        }

        if (preg_match('/^https?:\/\//i', $trimmed)) {
            return preg_replace(
                '/^http:\/\/(localhost|127\.0\.0\.1|0\.0\.0\.0)(:\d+)?/i',
                $baseUrl,
                $trimmed
            );
        }

        $path = $this->normalizeRelativeImagePath($trimmed);
        if ($path === '') {
            return null;
        }

        return $baseUrl . '/' . ltrim($path, '/');
    }

    private function resolveLibraryImageUrl(object $plant, Request $request): ?string
    {
        $rawImage = trim((string) ($plant->image_url ?? ''));

        if ($rawImage !== '' && !$this->isRemoteUrl($rawImage)) {
            $path = $this->normalizeRelativeImagePath($rawImage);
            if ($path !== '' && File::isFile(public_path($path))) {
                return $this->resolveImageUrl($path, $request);
            }
        }

        $cachedPath = $this->findCachedLibraryImagePath((int) $plant->id);
        if ($cachedPath !== null) {
            return $this->resolveImageUrl($cachedPath, $request);
        }

        return $this->resolveImageUrl($rawImage, $request);
    }

    private function isLibraryImageCached(object $plant): bool
    {
        $rawImage = trim((string) ($plant->image_url ?? ''));
        if ($rawImage !== '' && !$this->isRemoteUrl($rawImage)) {
            $path = $this->normalizeRelativeImagePath($rawImage);
            if ($path !== '' && File::isFile(public_path($path))) {
                return true;
            }
        }

        return $this->findCachedLibraryImagePath((int) $plant->id) !== null;
    }

    private function cacheRemoteLibraryImage(object $plant, string $url): ?string
    {
        $directory = public_path(self::LIBRARY_IMAGE_DIR);
        if (!File::exists($directory)) {
            File::makeDirectory($directory, 0755, true);
        }

        foreach ($this->imageDownloadCandidates($url) as $candidateUrl) {
            try {
                $response = Http::withHeaders([
                    'User-Agent' => 'ChamSocCayTrong/1.0 library image cache',
                    'Accept' => 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
                    'Referer' => 'https://commons.wikimedia.org/',
                ])->timeout(25)->get($candidateUrl);

                if ($response->status() === 429) {
                    usleep(1200000);
                    $response = Http::withHeaders([
                        'User-Agent' => 'ChamSocCayTrong/1.0 library image cache',
                        'Accept' => 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
                        'Referer' => 'https://commons.wikimedia.org/',
                    ])->timeout(25)->get($candidateUrl);
                }

                if (!$response->successful()) {
                    continue;
                }

                $contentType = $response->header('Content-Type', 'image/jpeg');
                if (!str_starts_with(strtolower($contentType), 'image/')) {
                    continue;
                }

                $extension = $this->imageExtension($contentType, $candidateUrl);
                $fileName = 'plant_' . (int) $plant->id . '.' . $extension;
                $absolutePath = $directory . DIRECTORY_SEPARATOR . $fileName;

                File::put($absolutePath, $response->body());
                if (!File::isFile($absolutePath) || File::size($absolutePath) === 0) {
                    File::delete($absolutePath);
                    continue;
                }

                return self::LIBRARY_IMAGE_DIR . '/' . $fileName;
            } catch (\Throwable $e) {
                report($e);
            }
        }

        return null;
    }

    private function findCachedLibraryImagePath(int $plantId): ?string
    {
        $pattern = public_path(self::LIBRARY_IMAGE_DIR . '/plant_' . $plantId . '.*');
        $files = glob($pattern) ?: [];

        foreach ($files as $file) {
            if (File::isFile($file) && File::size($file) > 0) {
                return self::LIBRARY_IMAGE_DIR . '/' . basename($file);
            }
        }

        return null;
    }

    private function imageExtension(string $contentType, string $url): string
    {
        $urlPath = (string) parse_url($url, PHP_URL_PATH);
        $urlExtension = strtolower(pathinfo($urlPath, PATHINFO_EXTENSION));
        $urlExtension = preg_replace('/[^a-z0-9]/', '', $urlExtension);

        if (in_array($urlExtension, ['jpg', 'jpeg', 'png', 'webp', 'gif'], true)) {
            return $urlExtension === 'jpeg' ? 'jpg' : $urlExtension;
        }

        $mimeType = strtolower(trim(explode(';', $contentType)[0]));
        return match ($mimeType) {
            'image/png' => 'png',
            'image/webp' => 'webp',
            'image/gif' => 'gif',
            default => 'jpg',
        };
    }

    private function imageDownloadCandidates(string $url): array
    {
        $candidates = [];

        foreach ([500, 330] as $width) {
            $thumbnailUrl = $this->wikimediaThumbnailUrl($url, $width);
            if ($thumbnailUrl !== null) {
                $candidates[] = $thumbnailUrl;
            }
        }

        $candidates[] = $url;

        return array_values(array_unique($candidates));
    }

    private function wikimediaThumbnailUrl(string $url, int $width): ?string
    {
        $parts = parse_url($url);
        $host = strtolower((string) ($parts['host'] ?? ''));
        $path = (string) ($parts['path'] ?? '');

        if ($host !== 'upload.wikimedia.org') {
            return null;
        }

        $prefix = '/wikipedia/commons/';
        if (!str_starts_with($path, $prefix) || str_starts_with($path, $prefix . 'thumb/')) {
            return null;
        }

        $relativePath = substr($path, strlen($prefix));
        $fileName = basename($relativePath);
        if ($relativePath === '' || $fileName === '') {
            return null;
        }

        $scheme = $parts['scheme'] ?? 'https';
        return $scheme . '://' . $host . $prefix . 'thumb/' . $relativePath . '/' . $width . 'px-' . $fileName;
    }

    private function isRemoteUrl(string $url): bool
    {
        return preg_match('/^https?:\/\//i', trim($url)) === 1;
    }

    private function normalizeRelativeImagePath(string $path): string
    {
        $path = trim($path);
        $publicIndex = stripos($path, '/public/');
        if ($publicIndex !== false) {
            $path = substr($path, $publicIndex + strlen('/public/'));
        }

        $path = preg_replace('/^public\/+/i', '', $path);
        $path = preg_replace('/^storage\/app\/public\/+/i', 'storage/', $path);
        $path = preg_replace('/^public\/storage\/+/i', 'storage/', $path);

        return ltrim((string) $path, '/');
    }
}
