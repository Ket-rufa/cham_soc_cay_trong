<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up()
    {
        Schema::create('plant_libraries', function (Blueprint $table) {
            $table->id();
            $table->string('name'); // Tên cây (Mai vàng)
            $table->string('type'); // Loại (Hoa, Cây ăn quả,...)
            $table->text('description')->nullable(); // Mô tả chi tiết
            $table->text('image_url'); // Link ảnh online
        // Các chỉ số như trong ảnh của bạn
            $table->string('difficulty')->default('Dễ'); // Mức độ khó
            $table->string('light')->default('Ánh sáng mạnh'); // Ánh sáng
            $table->string('water')->default('Trung bình'); // Nước

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('plant_libraries');
    }
};
