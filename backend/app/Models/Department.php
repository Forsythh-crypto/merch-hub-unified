<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Department extends Model
{
    use HasFactory;

    protected $fillable = ['name', 'description', 'logo_path'];

    // Relationships
    public function products()
    {
        return $this->hasMany(Product::class);
    }

    public function listings()
    {
        return $this->hasMany(Listing::class);
    }

    public function users()
    {
        return $this->hasMany(User::class);
    }
}