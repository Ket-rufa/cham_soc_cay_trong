<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\PestDiseaseGuide;
use Illuminate\Support\Facades\DB;

class PestDiseaseGuideController extends Controller
{
    public function getGuideByPlant(Request $request)
    {
        $plantName = $request->query('plant_name');

        if (!$plantName || $plantName == 'Tất cả') {
            $guides = PestDiseaseGuide::all();
        } else {
            // Tìm bệnh riêng cho cây + bệnh chung (Tất cả)
            $guides = PestDiseaseGuide::where('plant_name', 'like', '%' . $plantName . '%')
                ->orWhere('plant_name', 'Tất cả')
                ->get();
        }

        if ($guides->isEmpty()) {
            return response()->json([
                'status' => 404,
                'message' => 'No pest and disease guide is currently available for this species.'
            ], 404);
        }

        return response()->json([
            'status' => 200,
            'data' => $guides
        ], 200);
    }
}

