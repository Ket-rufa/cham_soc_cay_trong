<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Plant extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'image_url',
        'note',
    ];

    public function careSchedules()
    {
        return $this->hasMany(PlantCareSchedule::class);
    }

    public function histories()
    {
        return $this->hasMany(PlantHistory::class);
    }
}
