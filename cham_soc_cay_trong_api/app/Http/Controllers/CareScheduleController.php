<?php

namespace App\Http\Controllers;

use App\Models\PlantCareSchedule;
use Illuminate\Http\Request;
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;

class CareScheduleController extends Controller
{
    public function index()
    {
        // Require joining with 'plant' to get plant names
        $schedules = PlantCareSchedule::with('plant')
            ->where('is_active', true)
            ->whereNotNull('plant_id')
            ->orderBy('next_due_at', 'asc')
            ->get();

        $todayStart = Carbon::today();
        $todayEnd = Carbon::today()->endOfDay();

        $todayTasks = [];
        $upcomingTasks = [];

        foreach ($schedules as $schedule) {
            if (!$schedule->plant) continue; // safety check
            
            $due = Carbon::parse($schedule->next_due_at);
            if ($due->lte($todayEnd)) {
                $todayTasks[] = $schedule;
            } else {
                $upcomingTasks[] = $schedule;
            }
        }

        return response()->json([
            'status' => 200,
            'data' => [
                'today' => $todayTasks,
                'upcoming' => $upcomingTasks,
            ]
        ], 200);
    }

    public function complete($id)
    {
        $schedule = PlantCareSchedule::find($id);
        if (!$schedule) {
            return response()->json(['status' => 404, 'message' => 'Không tìm thấy nhiệm vụ'], 404);
        }

        $now = Carbon::now();
        $schedule->last_done_at = $now;
        $schedule->next_due_at = $now->copy()->addDays($schedule->frequency_days);
        $schedule->save();

        // Tạo lịch sử tự động
        DB::table('plant_histories')->insert([
            'plant_id' => $schedule->plant_id,
            'action' => 'Hoàn thành nhiệm vụ: ' . $this->translateTask($schedule->task_type),
            'note' => 'Cập nhật qua Lịch chăm sóc tự động',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return response()->json(['status' => 200, 'message' => 'Đã hoàn thành'], 200);
    }

    private function translateTask($task)
    {
        switch ($task) {
            case 'water': return 'Tưới nước';
            case 'fertilize': return 'Bón phân';
            case 'prune': return 'Cắt tỉa';
            default: return $task;
        }
    }
}
