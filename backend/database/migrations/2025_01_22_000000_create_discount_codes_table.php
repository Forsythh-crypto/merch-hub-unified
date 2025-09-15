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
        Schema::create('discount_codes', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique(); // Discount code (e.g., SAVE20, DEPT10)
            $table->enum('type', ['percentage', 'fixed']); // Discount type
            $table->decimal('value', 8, 2); // Discount value (percentage or fixed amount)
            $table->text('description')->nullable(); // Description of the discount
            
            // Admin/Department restrictions
            $table->foreignId('created_by')->constrained('users')->onDelete('cascade'); // Admin/SuperAdmin who created
            $table->foreignId('department_id')->nullable()->constrained('departments')->onDelete('cascade'); // Null for superadmin (all depts), specific for admin
            $table->boolean('is_udd_official')->default(false); // For UDD official merch (superadmin only)
            
            // Usage restrictions
            $table->integer('usage_limit')->nullable(); // Max number of uses (null = unlimited)
            $table->integer('usage_count')->default(0); // Current usage count
            $table->decimal('minimum_order_amount', 8, 2)->nullable(); // Minimum order amount to use code
            
            // Date restrictions
            $table->datetime('valid_from')->nullable(); // Start date
            $table->datetime('valid_until')->nullable(); // Expiry date
            
            // Status
            $table->boolean('is_active')->default(true);
            
            $table->timestamps();
            
            // Indexes
            $table->index(['code', 'is_active']);
            $table->index(['department_id', 'is_active']);
            $table->index(['created_by']);
            $table->index(['valid_from', 'valid_until']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('discount_codes');
    }
};