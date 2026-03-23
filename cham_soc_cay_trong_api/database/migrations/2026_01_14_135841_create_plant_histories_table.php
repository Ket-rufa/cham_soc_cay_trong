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
        Schema::create('plant_histories', function (Blueprint $table) {
            $table->id();
            // Liên kết với cây nào trong bảng plants
            $table->foreignId('plant_id')->constrained()->onDelete('cascade');
        
            $table->string('action'); // Hành động: Tưới nước, Bón phân, Cắt tỉa...
            $table->text('note')->nullable(); // Ghi chú cho lần chăm sóc đó
        
            $table->timestamps(); // Sẽ tự động lưu thời gian thực hiện (created_at)
    });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('plant_histories');
    }
};
