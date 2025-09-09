<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Order extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_number',
        'user_id',
        'email',
        'listing_id',
        'department_id',
        'quantity',
        'size',
        'total_amount',
        'status', // pending, confirmed, ready_for_pickup, completed, cancelled
        'pickup_date',
        'notes',
        'payment_method',
        'email_sent',
    ];

    protected $casts = [
        'pickup_date' => 'datetime',
        'email_sent' => 'boolean',
        'user_id' => 'integer',
    ];

    // Generate unique order number
    public static function generateOrderNumber()
    {
        do {
            $orderNumber = 'ORD-' . date('Ymd') . '-' . strtoupper(Str::random(6));
        } while (self::where('order_number', $orderNumber)->exists());

        return $orderNumber;
    }

    // Relationships
    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function listing()
    {
        return $this->belongsTo(Listing::class);
    }

    public function department()
    {
        return $this->belongsTo(Department::class);
    }

    // Get status display name
    public function getStatusDisplayAttribute()
    {
        return match($this->status) {
            'pending' => 'Pending',
            'confirmed' => 'Confirmed',
            'ready_for_pickup' => 'Ready for Pickup',
            'completed' => 'Completed',
            'cancelled' => 'Cancelled',
            default => 'Unknown'
        };
    }

    // Check if order can be cancelled
    public function canBeCancelled()
    {
        return in_array($this->status, ['pending', 'confirmed']);
    }

    // Check if order is ready for pickup
    public function isReadyForPickup()
    {
        return $this->status === 'ready_for_pickup';
    }
}
