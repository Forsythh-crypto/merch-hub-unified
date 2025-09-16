<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Carbon\Carbon;

class DiscountCode extends Model
{
    use HasFactory;

    protected $fillable = [
        'code',
        'type',
        'value',
        'description',
        'created_by',
        'department_id',
        'is_udd_official',
        'usage_limit',
        'usage_count',
        'minimum_order_amount',
        'valid_from',
        'valid_until',
        'is_active',
    ];

    protected $casts = [
        'value' => 'decimal:2',
        'minimum_order_amount' => 'decimal:2',
        'valid_from' => 'datetime',
        'valid_until' => 'datetime',
        'is_active' => 'boolean',
        'is_udd_official' => 'boolean',
    ];

    // Relationships
    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function department()
    {
        return $this->belongsTo(Department::class);
    }

    public function orders()
    {
        return $this->hasMany(Order::class, 'discount_code_id');
    }

    // Scopes
    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }

    public function scopeValid($query)
    {
        $now = Carbon::now();
        return $query->where('is_active', true)
                    ->where(function ($q) use ($now) {
                        $q->whereNull('valid_from')
                          ->orWhere('valid_from', '<=', $now);
                    })
                    ->where(function ($q) use ($now) {
                        $q->whereNull('valid_until')
                          ->orWhere('valid_until', '>=', $now);
                    });
    }

    public function scopeForDepartment($query, $departmentId)
    {
        return $query->where(function ($q) use ($departmentId) {
            $q->whereNull('department_id') // Available for all departments (superadmin codes)
              ->orWhere('department_id', $departmentId); // Department-specific codes
        });
    }

    public function scopeForUser($query, User $user)
    {
        if ($user->isSuperAdmin()) {
            return $query; // Superadmin can see all codes
        }
        
        if ($user->isAdmin()) {
            return $query->where('created_by', $user->id)
                        ->orWhere('department_id', $user->department_id);
        }
        
        // Students can only see codes applicable to their department
        return $query->forDepartment($user->department_id);
    }

    // Methods
    public function isValid(): bool
    {
        if (!$this->is_active) {
            return false;
        }

        $now = Carbon::now();
        
        // Check date validity
        if ($this->valid_from && $this->valid_from->gt($now)) {
            return false;
        }
        
        if ($this->valid_until && $this->valid_until->lt($now)) {
            return false;
        }
        
        // Check usage limit
        if ($this->usage_limit && $this->usage_count >= $this->usage_limit) {
            return false;
        }
        
        return true;
    }

    public function canBeUsedForOrder($orderAmount, $departmentId): bool
    {
        if (!$this->isValid()) {
            return false;
        }
        
        // Check minimum order amount
        if ($this->minimum_order_amount && $orderAmount < $this->minimum_order_amount) {
            return false;
        }
        
        // Check department restriction
        if ($this->department_id && $this->department_id != $departmentId) {
            return false;
        }
        
        return true;
    }

    public function calculateDiscount($orderAmount): float
    {
        if ($this->type === 'percentage') {
            return $orderAmount * ($this->value / 100);
        }
        
        // Fixed amount discount
        return min($this->value, $orderAmount); // Don't exceed order amount
    }

    public function incrementUsage(): void
    {
        $this->increment('usage_count');
    }

    public function canBeCreatedBy(User $user, $departmentId = null): bool
    {
        if ($user->isSuperAdmin()) {
            return true; // Superadmin can create codes for any department
        }
        
        if ($user->isAdmin()) {
            // Admin can only create codes for their department
            return $departmentId === null || $departmentId == $user->department_id;
        }
        
        return false; // Students cannot create discount codes
    }

    public function canBeEditedBy(User $user): bool
    {
        if ($user->isSuperAdmin()) {
            return true; // Superadmin can edit all codes
        }
        
        if ($user->isAdmin()) {
            // Admin can only edit codes they created or codes for their department
            return $this->created_by == $user->id || $this->department_id == $user->department_id;
        }
        
        return false;
    }

    public function canBeUsedBy(User $user, $departmentId = null): bool
    {
        // Check if discount code is valid
        if (!$this->isValid()) {
            return false;
        }

        // Check department restrictions
        if ($this->department_id !== null && $this->department_id != $departmentId) {
            return false;
        }

        // Check usage limit
        if ($this->usage_limit !== null && $this->usage_count >= $this->usage_limit) {
            return false;
        }

        return true;
    }
}