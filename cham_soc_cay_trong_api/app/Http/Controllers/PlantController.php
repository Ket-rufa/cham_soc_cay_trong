<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Plant;
use Illuminate\Support\Facades\DB; // <--- 1. Thêm dòng này để sửa lỗi gạch đỏ
use Illuminate\Support\Facades\File;

class PlantController extends Controller
{
    // API: GET /plants
    public function index(Request $request)
    {
        // 1. Lấy danh sách cây trong vườn (Mới nhất lên đầu)
        $myPlants = Plant::orderBy('id', 'desc')->get();

        // 2. Lấy danh sách thư viện để tra cứu
        $library = DB::table('plant_libraries')->get();

        // 3. Ghép thông tin (Magic Step ✨)
        $enrichedPlants = $myPlants->map(function ($plant) use ($library, $request) {
            // Ép kiểu sang chuỗi (string) để tránh lỗi nếu tên cây bị null
            $plantName = (string) $plant->name;

            // Tìm xem tên cây này có trong thư viện không?
            $libraryInfo = $library->first(function ($item) use ($plantName) {
                $itemName = (string) $item->name;
                // So sánh không phân biệt hoa thường
                return stripos($plantName, $itemName) !== false 
                    || stripos($itemName, $plantName) !== false;
            });

            // Nếu tìm thấy, chuyển đổi object Plant thành mảng và ghép thêm thông tin thư viện
            if ($libraryInfo) {
                $plantData = $plant->toArray(); // Dữ liệu gốc
                
                // Bổ sung các cột từ thư viện (Dùng ?? '' để tránh lỗi nếu dữ liệu trống)
                $plantData['scientific_name'] = $libraryInfo->scientific_name ?? '';
                $plantData['description']     = $libraryInfo->description ?? '';
                $plantData['care_tips']       = $libraryInfo->care_tips ?? '';
                $plantData['light']           = $libraryInfo->light ?? '';
                $plantData['water']           = $libraryInfo->water ?? '';
                $plantData['temp']            = $libraryInfo->temp ?? '';
                $plantData['difficulty']      = $libraryInfo->difficulty ?? '';
                $plantData['hardiness']       = $libraryInfo->hardiness ?? '';
                $plantData['soil']            = $libraryInfo->soil ?? '';
                $plantData['fertilizer']      = $libraryInfo->fertilizer ?? '';
                $plantData['planting_time']   = $libraryInfo->planting_time ?? '';
                $plantData['pruning']         = $libraryInfo->pruning ?? '';
                $plantData['propagation']     = $libraryInfo->propagation ?? '';
                $plantData['pests']           = $libraryInfo->pests ?? '';
                $plantImage = $plant->image_url ?? $plant->image ?? null;
                $plantData['image_url'] = $this->resolveImageUrl(
                    $plantImage ?: ($libraryInfo->image_url ?? null),
                    $request
                );
                $plantData['image'] = $plantData['image_url'];
                
                return $plantData;
            }

            $plantData = $plant->toArray();
            $plantData['image_url'] = $this->resolveImageUrl(
                $plant->image_url ?? $plant->image ?? null,
                $request
            );
            $plantData['image'] = $plantData['image_url'];

            return $plantData; // Nếu không thấy thì trả về nguyên bản
        });

        return response()->json([
            'status' => 200,
            'data' => $enrichedPlants
        ], 200);
    }

    // API: DELETE /plants/{id}
    public function destroy($id)
    {
        $plant = Plant::find($id);
        if ($plant) {
            // Xóa file ảnh nếu cần (tùy chọn, đang comment lại cho an toàn)
            // if (file_exists(public_path($plant->image))) { unlink(public_path($plant->image)); }
            
            $plant->delete();
            return response()->json(['status' => 200, 'message' => 'Đã xóa cây thành công'], 200);
        } else {
            return response()->json(['status' => 404, 'message' => 'Không tìm thấy cây'], 404);
        }
    }

    public function store(Request $request)
    {
        try {
            // 1. Khởi tạo
            $plant = new Plant();
            $plant->name = $request->name;
            $plant->location = $request->input('location', 'Sân vườn');

            // --- QUAN TRỌNG: Để null để tránh lỗi khóa ngoại user_id ---
            $plant->user_id = null; 
            // -----------------------------------------------------------

            // 2. Xử lý ảnh
            if ($request->hasFile('image')) {
                $file = $request->file('image');
                $filename = time() . '_' . $file->getClientOriginalName();
                $uploadDirectory = public_path('uploads/plants');
                if (!File::exists($uploadDirectory)) {
                    File::makeDirectory($uploadDirectory, 0755, true);
                }
                $file->move($uploadDirectory, $filename);
                $plant->image_url = 'uploads/plants/' . $filename;
            } elseif ($request->filled('image_url')) {
                // Lưu link ảnh từ thư viện
                $plant->image_url = $request->image_url;
            } else {
                $plant->image_url = null;
            }

            // 3. Lưu
            $plant->save();

            // 4. Tạo lịch chăm sóc mặc định
            \App\Models\PlantCareSchedule::insert([
                [
                    'plant_id' => $plant->id,
                    'task_type' => 'water',
                    'frequency_days' => 2,
                    'last_done_at' => null,
                    'next_due_at' => now(), // Hôm nay
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'plant_id' => $plant->id,
                    'task_type' => 'fertilize',
                    'frequency_days' => 14,
                    'last_done_at' => null,
                    'next_due_at' => now()->addDays(3),
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
                [
                    'plant_id' => $plant->id,
                    'task_type' => 'prune',
                    'frequency_days' => 30,
                    'last_done_at' => null,
                    'next_due_at' => now()->addDays(10),
                    'is_active' => true,
                    'created_at' => now(),
                    'updated_at' => now(),
                ],
            ]);

            return response()->json([
                'status' => 200,
                'message' => 'Lưu thành công',
                'data' => [
                    'id' => $plant->id,
                    'name' => $plant->name,
                    'image_url' => $this->resolveImageUrl($plant->image_url, $request),
                ],
            ], 200);

        } catch (\Exception $e) {
            // Trả về lỗi chi tiết
            return response()->json(['status' => 500, 'message' => $e->getMessage()], 500);
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
