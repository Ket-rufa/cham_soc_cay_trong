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
        Schema::create('pest_disease_guides', function (Blueprint $table) {
            $table->id();
            $table->string('plant_name'); 
            $table->string('disease_name');
            $table->string('type')->default('Sâu bệnh'); // Sâu hại hoặc Bệnh hại
            $table->text('symptoms')->nullable();
            $table->text('causes')->nullable();
            $table->text('prevention')->nullable();
            $table->text('treatment')->nullable();
            $table->string('image_url')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('pest_disease_guides');
    }
};
