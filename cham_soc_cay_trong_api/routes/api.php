<?php
use App\Http\Controllers\AuthController;
use App\Http\Controllers\PlantController;
// use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\PlantLibraryController;
use App\Http\Controllers\PlantInfoController;
use App\Http\Controllers\CareScheduleController;
use App\Http\Controllers\PestDiseaseGuideController;
use App\Http\Controllers\ArticleController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Tạm thời tắt 2 dòng đăng ký/đăng nhập bị lỗi này đi
// Route::post('/register', [AutKontroller::class, 'register']); // <--- THÊM //
// Route::post('/login', [AutKontroller::class, 'login']);       // <--- THÊM //

// === GIỮ NGUYÊN PHẦN CÂY TRỒNG BÊN DƯỚI ===
Route::get('/plants', [PlantController::class, 'index']);
Route::post('/plants', [PlantController::class, 'store']);
Route::get('/plants/{id}', [PlantController::class, 'show']); // Route chi tiết cây
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);
Route::post('/profile/update', [AuthController::class, 'updateProfile']);
Route::post('/profile/change-password', [AuthController::class, 'changePassword']);
Route::get('/profile/avatar/{userId}', [AuthController::class, 'showAvatar']);
Route::get('/library', [PlantLibraryController::class, 'index']);
Route::post('/library/cache-images', [PlantLibraryController::class, 'cacheImages']);
Route::get('/image-proxy', [PlantLibraryController::class, 'imageProxy']);
Route::post('/plants', [PlantController::class, 'store']);
Route::get('/plant-info', [PlantInfoController::class, 'search']);
Route::delete('/plants/{id}', [PlantController::class, 'destroy']);
Route::get('/schedules', [CareScheduleController::class, 'index']);
Route::post('/schedules', [CareScheduleController::class, 'store']);
Route::put('/schedules/{id}', [CareScheduleController::class, 'update']);
Route::delete('/schedules/{id}', [CareScheduleController::class, 'destroy']);
Route::post('/schedules/{id}/complete', [CareScheduleController::class, 'complete']);
Route::get('/guides', [PestDiseaseGuideController::class, 'getGuideByPlant']);
Route::get('/articles', [ArticleController::class, 'index']);
Route::get('/articles/{id}', [ArticleController::class, 'show']);
