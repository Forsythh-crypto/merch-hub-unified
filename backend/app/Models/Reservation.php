<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Reservation extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'department_id',
        'listing_id',
        'quantity',
        'size',
        'reservation_date',
        'status',
        'notes',
        'email',
    ];

    protected $casts = [
        'reservation_date' => 'datetime',
        'user_id' => 'integer',
        'department_id' => 'integer',
        'listing_id' => 'integer',
        'quantity' => 'integer',
    ];

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function department()
    {
        return $this->belongsTo(Department::class);
    }

    public function listing()
    {
        return $this->belongsTo(Listing::class);
    }
}
