<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('listings', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('image_path')->nullable(); // for uploaded image

            // Foreign keys
            $table->foreignId('department_id')->constrained()->onDelete('cascade');
            $table->unsignedBigInteger('category_id'); // ✅ fixed
            $table->foreign('category_id')->references('id')->on('categories')->onDelete('cascade'); // ✅ fixed
            $table->foreignId('user_id')->constrained()->onDelete('cascade'); // uploader

            $table->decimal('price', 8, 2);
            $table->string('size')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('listings');
    }
};