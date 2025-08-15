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

}