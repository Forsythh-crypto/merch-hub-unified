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

    protected static function boot()
    {
        parent::boot();

        static::created(function ($listing) {
            // Auto-create size variants for clothing items
            if ($listing->category_id && !$listing->sizeVariants()->exists()) {
                $category = Category::find($listing->category_id);
                if ($category) {
                    $categoryName = strtolower($category->name);
                    $isClothing = str_contains($categoryName, 'clothing') ||
                        str_contains($categoryName, 'shirt') ||
                        str_contains($categoryName, 'tee') ||
                        str_contains($categoryName, 'apparel');

                    if ($isClothing) {
                        $sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
                        $stockPerSize = max(0, floor($listing->stock_quantity / 6));
                        $remaining = $listing->stock_quantity - ($stockPerSize * 6);

                        foreach ($sizes as $index => $size) {
                            $stock = $stockPerSize + ($index == 2 ? $remaining : 0); // Add remaining to M size
                            $listing->sizeVariants()->create([
                                'size' => $size,
                                'stock_quantity' => $stock,
                            ]);
                        }
                        \Log::info("Auto-created size variants for clothing item: {$listing->title}");
                    }
                }
            }
        });
    }

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

    public function images()
    {
        return $this->hasMany(ListingImage::class)->orderBy('sort_order');
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

    public function orders()
    {
        return $this->hasMany(Order::class);
    }

    public function getReviewsAttribute()
    {
        return $this->orders()
            ->whereNotNull('rating')
            ->with('user:id,name,email') // Eager load user for reviews
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($order) {
                return [
                    'id' => $order->id,
                    'rating' => $order->rating,
                    'review' => $order->review,
                    'user_name' => $order->user ? $order->user->name : 'Unknown User',
                    'created_at' => $order->created_at,
                ];
            });
    }

    public function getAverageRatingAttribute()
    {
        return round($this->orders()->whereNotNull('rating')->avg('rating') ?? 0, 1);
    }

    public function getReviewCountAttribute()
    {
        return $this->orders()->whereNotNull('rating')->count();
    }
}