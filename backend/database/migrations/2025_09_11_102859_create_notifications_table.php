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
        Schema::create('notifications', function (Blueprint $table) {
            $table->id();
            $table->string('type'); // 'order_created', 'order_status_changed', 'reservation_created'
            $table->string('title');
            $table->text('message');
            $table->json('data')->nullable(); // Additional data like order_id, department_id, etc.
            $table->unsignedBigInteger('user_id')->nullable(); // Target user (null for broadcast)
            $table->string('user_role')->nullable(); // Target role (superadmin, admin, student)
            $table->unsignedBigInteger('department_id')->nullable(); // For department-specific notifications
            $table->boolean('is_read')->default(false);
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
            
            $table->index(['user_id', 'is_read']);
            $table->index(['user_role', 'is_read']);
            $table->index(['department_id', 'is_read']);
            $table->index('type');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('notifications');
    }
};
