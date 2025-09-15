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
        Schema::table('orders', function (Blueprint $table) {
            $table->unsignedBigInteger('discount_code_id')->nullable()->after('total_amount');
            $table->decimal('discount_amount', 10, 2)->default(0)->after('discount_code_id');
            $table->decimal('original_amount', 10, 2)->nullable()->after('discount_amount');
            
            $table->foreign('discount_code_id')->references('id')->on('discount_codes')->onDelete('set null');
            $table->index('discount_code_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropForeign(['discount_code_id']);
            $table->dropIndex(['discount_code_id']);
            $table->dropColumn(['discount_code_id', 'discount_amount', 'original_amount']);
        });
    }
};