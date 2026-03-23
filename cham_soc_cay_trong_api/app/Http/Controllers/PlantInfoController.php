<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class PlantInfoController extends Controller
{
    public function search(Request $request)
    {
        $name = $request->query('name'); // Tên từ App gửi lên (VD: Rosa chinensis)
        $plant = DB::table('plant_infos')->where('scientific_name', $name)->first();
        if (!$plant) {
            $genus = explode(' ', $name)[0];

            $plant = DB::table('plant_infos')
                ->where('scientific_name', 'LIKE', "%{$genus}%")
                ->orWhere('genus', 'LIKE', "%{$genus}%")
                ->first();
        }

        if ($plant) {
            return response()->json(['found' => true, 'data' => $plant]);
        } else {
            return response()->json(['found' => false]);
        }
    }
}
