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

    public function store(Request $request)
    {
        $validated = $request->validate([
            'plant_id' => 'required|exists:plants,id',
            'task_type' => 'nullable|string|max:50',
            'next_due_at' => 'required|date',
            'note' => 'nullable|string',
            'frequency_days' => 'nullable|integer|min:0',
        ]);

        $schedule = PlantCareSchedule::create([
            'plant_id' => $validated['plant_id'],
            'task_type' => $validated['task_type'] ?? 'note',
            'frequency_days' => $validated['frequency_days'] ?? 0,
            'last_done_at' => null,
            'next_due_at' => Carbon::parse($validated['next_due_at']),
            'note' => $validated['note'] ?? null,
            'is_active' => true,
        ]);

        return response()->json([
            'status' => 201,
            'message' => 'Đã tạo lịch chăm sóc',
            'data' => $schedule->load('plant'),
        ], 201);
    }

    public function complete($id)
    {
        $schedule = PlantCareSchedule::find($id);
        if (!$schedule) {
            return response()->json(['status' => 404, 'message' => 'Không tìm thấy nhiệm vụ'], 404);
        }

        $now = Carbon::now();
        $schedule->last_done_at = $now;
        if ((int) $schedule->frequency_days <= 0) {
            $schedule->is_active = false;
        } else {
            $schedule->next_due_at = $now->copy()->addDays($schedule->frequency_days);
        }
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

    public function update(Request $request, $id)
    {
        $schedule = PlantCareSchedule::find($id);
        if (!$schedule) {
            return response()->json(['status' => 404, 'message' => 'Không tìm thấy nhiệm vụ'], 404);
        }

        $validated = $request->validate([
            'next_due_at' => 'nullable|date',
            'note' => 'nullable|string',
        ]);

        if (isset($validated['next_due_at'])) {
            $schedule->next_due_at = Carbon::parse($validated['next_due_at']);
        }
        if (isset($validated['note'])) {
            $schedule->note = $validated['note'];
        }
        $schedule->save();

        return response()->json([
            'status' => 200,
            'message' => 'Đã cập nhật',
            'data' => $schedule->load('plant'),
        ], 200);
    }

    public function destroy($id)
    {
        $schedule = PlantCareSchedule::find($id);
        if (!$schedule) {
            return response()->json(['status' => 404, 'message' => 'Không tìm thấy nhiệm vụ'], 404);
        }

        $schedule->delete();
        return response()->json(['status' => 200, 'message' => 'Đã xoá'], 200);
    }

    private function translateTask($task)
    {
        switch ($task) {
            case 'water': return 'Tưới nước';
            case 'fertilize': return 'Bón phân';
            case 'prune': return 'Cắt tỉa';
            case 'note': return 'Ghi chú';
            default: return $task;
        }
    }
}
