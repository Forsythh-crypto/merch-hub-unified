<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Listing extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'image_path',
        'department_id',
        'user_id',
        'price',
        'size',
        'status',
        'category_id',
        'stock_quantity',
    ];

    // Optional: relationships
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function department()
    {
        return $this->belongsTo(Department::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function sizeVariants()
    {
        return $this->hasMany(ListingSizeVariant::class);
    }

    // Helper method to get total stock across all sizes
    public function getTotalStockAttribute()
    {
        return $this->sizeVariants->sum('stock_quantity');
    }

    // Helper method to check if listing has multiple sizes
    public function getHasMultipleSizesAttribute()
    {
        return $this->sizeVariants->count() > 1;
    }
}