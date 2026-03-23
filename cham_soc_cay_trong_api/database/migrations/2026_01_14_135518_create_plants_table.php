<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('plants', function (Blueprint $table) {
            $table->id();
        
            $table->unsignedBigInteger('user_id');
        
            // --- SỬA DÒNG NÀY ---
            // Thêm 'fk_user_plant_new_v2' để tránh trùng tên cũ bị lỗi
            $table->foreign('user_id', 'fk_user_plant_new_v2')->references('id')->on('users')->onDelete('cascade');
            // --------------------

            $table->string('name');
            $table->string('image_url')->nullable();
            $table->string('location')->default('Trong nhà');
            $table->text('note')->nullable();
        
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('plants');
    }
};
