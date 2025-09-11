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
            $table->decimal('reservation_fee_amount', 10, 2)->nullable()->after('total_amount');
            $table->boolean('reservation_fee_paid')->default(false)->after('reservation_fee_amount');
            $table->string('payment_receipt_path')->nullable()->after('reservation_fee_paid');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn(['reservation_fee_amount', 'reservation_fee_paid', 'payment_receipt_path']);
        });
    }
};
