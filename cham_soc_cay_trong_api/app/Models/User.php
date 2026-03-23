<?php

namespace App\Models;

// use Laravel\Sanctum\HasApiTokens;  <-- XÓA DÒNG NÀY (HOẶC COMMENT LẠI)
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    // use HasApiTokens, HasFactory, Notifiable; <-- XÓA CÁI HasApiTokens ĐI
    use HasFactory, Notifiable; // <-- CHỈ ĐỂ LẠI NHƯ NÀY

    protected $fillable = [
        'name',
        'email',
        'password',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
    ];
}