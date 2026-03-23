<?php
namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PlantLibraryController extends Controller
{
    // API lấy danh sách thư viện (có tìm kiếm)
    public function index(Request $request)
    {
        $keyword = $request->query('keyword');
        $query = DB::table('plant_libraries');

        // Nếu có từ khóa thì lọc, không thì lấy hết
        if ($keyword) {
            $query->where('name', 'LIKE', "%{$keyword}%");
        }

        // Lấy danh sách (giới hạn 50 cây để load cho nhanh)
        $plants = $query->limit(50)->get();

        return response()->json([
            'status' => 200,
            'data' => $plants
        ], 200);
    }
}