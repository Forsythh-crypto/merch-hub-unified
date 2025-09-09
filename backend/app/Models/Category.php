<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasFactory;

    // Allow mass assignment for 'name'
    protected $fillable = ['name'];

    /**
     * A category has many listings.
     */
    public function listings()
    {
        return $this->hasMany(Listing::class);
    }
}