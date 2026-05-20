<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class PestDiseaseGuide extends Model
{
    use HasFactory;

    protected $fillable = [
        'plant_name',
        'disease_name',
        'type',
        'symptoms',
        'causes',
        'prevention',
        'treatment',
        'image_url',
        'affected_plants',
        'top_affected_flowers',
    ];

    protected $casts = [
        'top_affected_flowers' => 'array',
    ];
}

