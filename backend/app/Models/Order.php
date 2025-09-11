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
        'reservation_fee_amount',
        'reservation_fee_paid',
        'payment_receipt_path',
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
        'reservation_fee_paid' => 'boolean',
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

    // Check if reservation fee is paid
    public function hasPaidReservationFee()
    {
        return $this->reservation_fee_paid;
    }

    // Get reservation fee amount (35% of total)
    public function getReservationFeeAmount()
    {
        return $this->total_amount * 0.35;
    }

    // Check if order can be confirmed (reservation fee must be paid)
    public function canBeConfirmed()
    {
        return $this->hasPaidReservationFee() && $this->status === 'pending';
    }
}
