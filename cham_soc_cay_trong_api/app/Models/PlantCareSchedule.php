<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PlantCareSchedule extends Model
{
    use HasFactory;

    protected $fillable = [
        'plant_id',
        'task_type',
        'frequency_days',
        'last_done_at',
        'next_due_at',
        'is_active',
    ];

    protected $casts = [
        'last_done_at' => 'datetime',
        'next_due_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    public function plant()
    {
        return $this->belongsTo(Plant::class);
    }
}
