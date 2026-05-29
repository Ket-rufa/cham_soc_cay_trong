<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use App\Models\PestDiseaseGuide;

class DiseaseIdentifyController extends Controller
{
    /**
     * Nhận ảnh upload, gọi Plant.id API v3 health_assessment,
     * trả về top 3 bệnh với thông tin chi tiết.
     */
    public function identify(Request $request)
    {
        $request->validate([
            'image' => 'required|image|max:10240', // max 10MB
        ]);

        $apiKey = config('services.plantid.key', '');

        // Kiểm tra API key đã được cấu hình chưa
        if (empty($apiKey) || $apiKey === 'YOUR_PLANTID_KEY_HERE') {
            return response()->json([
                'status'  => 503,
                'message' => 'Plant.id API key chưa được cấu hình. Vui lòng thêm PLANTID_API_KEY vào file .env.',
            ], 503);
        }

        $file = $request->file('image');

        // ----- 1. Encode ảnh sang base64 -----
        $imageContent = file_get_contents($file->getRealPath());
        if ($imageContent === false) {
            return response()->json([
                'status'  => 400,
                'message' => 'Không thể đọc file ảnh.',
            ], 400);
        }

        $mime     = $file->getMimeType();
        $base64   = base64_encode($imageContent);
        $dataUri  = "data:{$mime};base64,{$base64}";

        // ----- 2. Gọi Plant.id API v3 -----
        $url = config('services.plantid.url') . '?' . http_build_query([
            'details'  => 'description,treatment,classification,common_names',
            'language' => 'en',
        ]);

        $response = Http::withHeaders([
            'Api-Key'      => $apiKey,
            'Content-Type' => 'application/json',
        ])->timeout(30)->post($url, [
            'images'          => [$dataUri],
            'health'          => 'all',        // thay thành 'all' để lấy cả nhận diện và health
        ]);

        // ----- 3. Xử lý response lỗi từ Plant.id -----
        if ($response->failed()) {
            $errorBody = $response->json();
            $errorMsg  = $errorBody['error'] ?? $errorBody['message'] ?? 'Lỗi kết nối Plant.id API';
            return response()->json([
                'status'  => $response->status(),
                'message' => "Lỗi từ Plant.id: {$errorMsg}",
            ], $response->status());
        }

        $body = $response->json();

        // ----- 4. Kiểm tra cây có khỏe mạnh không -----
        $isHealthy      = $body['result']['is_healthy']['binary']      ?? true;
        $healthProb     = $body['result']['is_healthy']['probability']  ?? 1.0;
        $suggestions    = $body['result']['disease']['suggestions']     ?? [];

        // Nếu cây khỏe mạnh và không có bệnh → trả về thông báo
        if ($isHealthy && empty($suggestions)) {
            return response()->json([
                'status'        => 200,
                'message'       => 'Cây trông khỏe mạnh, không phát hiện dấu hiệu bệnh rõ ràng.',
                'is_healthy'    => true,
                'health_score'  => round($healthProb * 100, 1),
                'results'       => [],
            ]);
        }

        // ----- 5. Lấy top 3 bệnh, xử lý & dịch tên sang tiếng Việt -----
        $topDiseases = array_slice($suggestions, 0, 3);
        $results     = $this->formatResults($topDiseases);

        return response()->json([
            'status'        => 200,
            'message'       => 'Phân tích hoàn tất',
            'is_healthy'    => $isHealthy,
            'health_score'  => round((1 - $healthProb) * 100, 1), // % nguy cơ bệnh
            'results'       => $results,
        ]);
    }

    /**
     * Format kết quả từ Plant.id thành cấu trúc mà Flutter UI đang dùng.
     * Đồng thời làm giàu dữ liệu từ database nội bộ nếu có.
     */
    /**
     * Tự động dịch văn bản tiếng Anh sang tiếng Việt sử dụng Google Translate API miễn phí.
     */
    private function translateToVietnamese(string $text): string
    {
        if (empty(trim($text))) {
            return '';
        }

        try {
            $response = Http::get('https://translate.googleapis.com/translate_a/single', [
                'client' => 'gtx',
                'sl'     => 'en',
                'tl'     => 'vi',
                'dt'     => 't',
                'q'      => $text,
            ]);

            if ($response->successful()) {
                $result = $response->json();
                if (isset($result[0])) {
                    $translated = '';
                    foreach ($result[0] as $sentence) {
                        $translated .= $sentence[0] ?? '';
                    }
                    return trim($translated) ?: $text;
                }
            }
        } catch (\Exception $e) {
            // Ghi log lỗi nếu cần thiết và trả về văn bản gốc làm fallback
        }

        return $text;
    }

    /**
     * Format kết quả từ Plant.id thành cấu trúc mà Flutter UI đang dùng.
     * Đồng thời làm giàu dữ liệu từ database nội bộ nếu có.
     */
    private function formatResults(array $suggestions): array
    {
        $results = [];

        foreach ($suggestions as $suggestion) {
            $englishName = $suggestion['name'] ?? 'Unknown Disease';
            $probability = $suggestion['probability'] ?? 0;
            $details     = $suggestion['details'] ?? [];

            // Lấy mô tả từ Plant.id và tự động dịch sang tiếng Việt
            $descriptionRaw = $details['description']['value'] ?? '';
            $description = $this->translateToVietnamese($descriptionRaw);

            // Lấy hướng dẫn điều trị từ Plant.id và tự động dịch sang tiếng Việt
            $treatment = $this->extractTreatment($details['treatment'] ?? []);

            // Tìm tên tiếng Việt
            $vietnameseName = $this->findVietnameseName($englishName);

            if (empty($vietnameseName)) {
                // Thử tìm theo common names
                $commonNames = $details['common_names'] ?? [];
                foreach ($commonNames as $cn) {
                    $vietnameseName = $this->findVietnameseName($cn);
                    if (!empty($vietnameseName)) {
                        break;
                    }
                }
            }

            if (empty($vietnameseName)) {
                if (strtolower($englishName) === 'feeding damage by insects') {
                    $vietnameseName = 'Thiệt hại do côn trùng cắn phá';
                } else {
                    $translatedName = $this->translateToVietnamese($englishName);
                    // Khử các lỗi dịch nhầm của Google Translate
                    if (str_contains($translatedName, 'nội mạc tử cung') || str_contains($translatedName, 'tử cung')) {
                        $vietnameseName = 'Sâu ong hại hoa hồng';
                    } else {
                        $vietnameseName = $translatedName;
                    }
                }
            }

            // Tra DB nội bộ để làm giàu thêm thông tin
            $dbGuide = $this->findInDatabase($englishName, $vietnameseName);

            $results[] = [
                'disease_key'     => $this->toKey($englishName),
                'confidence'      => round($probability * 100, 1),
                'name'            => $dbGuide ? $dbGuide->disease_name : ($vietnameseName ?: $englishName),
                'english_name'    => $englishName,
                'type'            => $dbGuide ? $dbGuide->type : $this->guessType($englishName),
                'symptoms'        => $dbGuide ? $dbGuide->symptoms  : $description,
                'causes'          => $dbGuide ? $dbGuide->causes    : '',
                'prevention'      => $dbGuide ? $dbGuide->prevention : ($treatment['prevention'] ?? ''),
                'treatment'       => $dbGuide ? $dbGuide->treatment  : ($treatment['chemical'] ?? ''),
                'image_url'       => $dbGuide ? $dbGuide->image_url  : '',
                'affected_plants' => $dbGuide ? $dbGuide->affected_plants : '',
                'top_affected_flowers' => $dbGuide ? $dbGuide->top_affected_flowers : null,
                'guide_id'        => $dbGuide ? $dbGuide->id : null,
                // Dữ liệu bổ sung từ Plant.id
                'plantid_details' => [
                    'description'   => $description,
                    'treatment'     => $treatment,
                    'common_names'  => $details['common_names'] ?? [],
                ],
            ];
        }

        return $results;
    }

    /**
     * Trích xuất thông tin điều trị từ Plant.id response.
     */
    private function extractTreatment(array $treatment): array
    {
        // Trong Plant.id v3, chemical/biological/prevention là các mảng chuỗi phẳng (flat array of strings)
        $chemical   = implode('; ', $treatment['chemical'] ?? []);
        $biological = implode('; ', $treatment['biological'] ?? []);
        $prevention = implode('; ', $treatment['prevention'] ?? []);

        return [
            'chemical'   => $this->translateToVietnamese($chemical),
            'biological' => $this->translateToVietnamese($biological),
            'prevention' => $this->translateToVietnamese($prevention),
        ];
    }

    private function findVietnameseName(string $englishName): string
    {
        // Map tên bệnh phổ biến sang tiếng Việt
        $map = [
            'powdery mildew'   => 'Bệnh phấn trắng',
            'black spot'       => 'Bệnh đốm đen',
            'rust'             => 'Bệnh gỉ sắt',
            'gray mold'        => 'Bệnh mốc xám',
            'botrytis'         => 'Bệnh mốc xám (Botrytis)',
            'anthracnose'      => 'Bệnh thán thư',
            'leaf spot'        => 'Bệnh đốm lá',
            'blight'           => 'Bệnh cháy lá',
            'wilt'             => 'Bệnh héo',
            'root rot'         => 'Bệnh thối rễ',
            'soft rot'         => 'Bệnh thối nhũn',
            'chlorosis'        => 'Bệnh vàng lá',
            'mosaic'           => 'Bệnh khảm virus',
            'downy mildew'     => 'Bệnh sương mai',
            'scab'             => 'Bệnh ghẻ',
            'canker'           => 'Bệnh loét thân',
            'fire blight'      => 'Bệnh cháy bìa lá vi khuẩn',
            'leaf roller'      => 'Sâu cuốn lá',
            'leaf rollers'     => 'Sâu cuốn lá',
            'aphids'           => 'Rệp sáp/Rệp muội',
            'spider mites'     => 'Nhện đỏ',
            'thrips'           => 'Bọ trĩ',
            'scale insects'    => 'Rệp vảy',
            'whitefly'         => 'Bọ phấn trắng',
            'caterpillar'      => 'Sâu ăn lá',
            'stem borer'       => 'Sâu đục thân',
            'slug'             => 'Sên/Sâu nhớt',
            'endelomyia'       => 'Sâu ong hại hoa hồng (Endelomyia)',
            'sawfly'           => 'Sâu ong hại lá',
            'sawflies'         => 'Sâu ong hại lá',
            'rose slug'        => 'Sâu ong hại hoa hồng (Rose slug)',
            'feeding damage'   => 'Thiệt hại do côn trùng cắn phá',
            'insect damage'    => 'Thiệt hại do côn trùng',
        ];

        $lower = strtolower(trim($englishName));
        foreach ($map as $en => $vi) {
            if (str_contains($lower, $en)) {
                return $vi;
            }
        }

        return ''; // Không tìm thấy → giữ tiếng Anh
    }

    /**
     * Tra database nội bộ để lấy thông tin chi tiết bằng tiếng Việt.
     */
    private function findInDatabase(string $englishName, string $vietnameseName): ?PestDiseaseGuide
    {
        // Thử tìm theo tên tiếng Việt trước
        if ($vietnameseName) {
            // Lấy từ khóa ngắn (ví dụ: "phấn trắng" từ "Bệnh phấn trắng")
            $keyword = preg_replace('/^(Bệnh|Sâu|Rệp|Bọ)\s+/iu', '', $vietnameseName);
            $guide = PestDiseaseGuide::where('disease_name', 'like', "%{$keyword}%")->first();
            if ($guide) return $guide;
        }

        // Thử tìm theo tên tiếng Anh
        $guide = PestDiseaseGuide::where('disease_name', 'like', "%{$englishName}%")->first();
        if ($guide) return $guide;

        return null;
    }

    /**
     * Đoán loại bệnh (nấm/vi khuẩn/virus/sâu hại) từ tên tiếng Anh.
     */
    private function guessType(string $englishName): string
    {
        $lower = strtolower($englishName);
        if (str_contains($lower, 'mildew') || str_contains($lower, 'rust') ||
            str_contains($lower, 'blight') || str_contains($lower, 'mold') ||
            str_contains($lower, 'anthracnose') || str_contains($lower, 'scab')) {
            return 'Bệnh nấm';
        }
        if (str_contains($lower, 'mosaic') || str_contains($lower, 'virus') ||
            str_contains($lower, 'yellowing')) {
            return 'Bệnh virus';
        }
        if (str_contains($lower, 'aphid') || str_contains($lower, 'mite') ||
            str_contains($lower, 'thrip') || str_contains($lower, 'fly') ||
            str_contains($lower, 'caterpillar') || str_contains($lower, 'worm') ||
            str_contains($lower, 'roller') || str_contains($lower, 'borer') ||
            str_contains($lower, 'scale') || str_contains($lower, 'bug')) {
            return 'Sâu hại';
        }
        if (str_contains($lower, 'rot') || str_contains($lower, 'canker') ||
            str_contains($lower, 'wilt') || str_contains($lower, 'spot')) {
            return 'Bệnh vi khuẩn';
        }
        return 'Bệnh hại';
    }

    /**
     * Chuyển tên bệnh thành snake_case key.
     */
    private function toKey(string $name): string
    {
        return strtolower(preg_replace('/[^a-z0-9]+/i', '_', $name));
    }
}
