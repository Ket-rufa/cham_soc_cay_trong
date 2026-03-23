<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Plant;
use Illuminate\Support\Facades\DB; // <--- 1. Thêm dòng này để sửa lỗi gạch đỏ

class PlantController extends Controller
{
    // API: GET /plants
    public function index()
    {
        // 1. Lấy danh sách cây trong vườn (Mới nhất lên đầu)
        $myPlants = Plant::orderBy('id', 'desc')->get();

        // 2. Lấy danh sách thư viện để tra cứu
        $library = DB::table('plant_libraries')->get();

        // 3. Ghép thông tin (Magic Step ✨)
        $enrichedPlants = $myPlants->map(function ($plant) use ($library) {
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
                
                return $plantData;
            }

            return $plant; // Nếu không thấy thì trả về nguyên bản
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
                $file->move(public_path('uploads'), $filename);
                $plant->image = 'uploads/' . $filename;
            } elseif ($request->filled('image_url')) {
                // Lưu link ảnh từ thư viện
                $plant->image = $request->image_url;
            } else {
                $plant->image = 'uploads/default.png';
            }

            // 3. Lưu
            $plant->save();

            return response()->json(['status' => 200, 'message' => 'Lưu thành công'], 200);

        } catch (\Exception $e) {
            // Trả về lỗi chi tiết
            return response()->json(['status' => 500, 'message' => $e->getMessage()], 500);
        }
    }
}