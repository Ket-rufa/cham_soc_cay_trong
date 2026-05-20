<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Article extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'subtitle',
        'category',
        'read_time',
        'icon_name',
        'start_color',
        'end_color',
        'quick_tips',
        'sections',
        'is_published',
        'sort_order',
    ];

    protected $casts = [
        'quick_tips' => 'array',
        'sections' => 'array',
        'is_published' => 'boolean',
    ];
}
