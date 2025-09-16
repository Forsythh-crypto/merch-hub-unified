<?php

namespace App\Http\Controllers;

use App\Models\DiscountCode;
use App\Models\Department;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Carbon\Carbon;

class DiscountCodeController extends Controller
{
    /**
     * Get discount codes (Admin/SuperAdmin only)
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $user = $request->user();
            
            $query = DiscountCode::with(['creator', 'department'])
                                ->forUser($user)
                                ->orderBy('created_at', 'desc');
            
            // Filter by status if requested
            if ($request->has('status')) {
                if ($request->status === 'active') {
                    $query->active();
                } elseif ($request->status === 'valid') {
                    $query->valid();
                }
            }
            
            // Filter by department if requested (superadmin only)
            if ($request->has('department_id') && $user->isSuperAdmin()) {
                $query->where('department_id', $request->department_id);
            }
            
            $discountCodes = $query->get();
            
            return response()->json([
                'discount_codes' => $discountCodes,
                'total' => $discountCodes->count()
            ]);
        } catch (\Exception $e) {
            \Log::error('Get discount codes error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to fetch discount codes'], 500);
        }
    }

    /**
     * Create a new discount code (Admin/SuperAdmin only)
     */
    public function store(Request $request): JsonResponse
    {
        try {
            $user = $request->user();
            
            $validated = $request->validate([
                'code' => 'required|string|max:50|unique:discount_codes,code',
                'type' => 'required|in:percentage',
                'value' => 'required|numeric|min:0',
                'description' => 'nullable|string|max:500',
                'department_id' => 'nullable|exists:departments,id',
                'is_udd_official' => 'boolean',
                'usage_limit' => 'nullable|integer|min:1',
                'minimum_order_amount' => 'nullable|numeric|min:0',
                'valid_from' => 'nullable|date|after_or_equal:today',
                'valid_until' => 'nullable|date|after:valid_from',
            ]);
            
            // Additional validation for percentage type
            if ($validated['type'] === 'percentage' && $validated['value'] > 100) {
                return response()->json([
                    'error' => 'Percentage discount cannot exceed 100%'
                ], 422);
            }
            
            // Check if user can create code for specified department
            $departmentId = $validated['department_id'] ?? null;
            $isUddOfficial = $validated['is_udd_official'] ?? false;
            
            if ($user->isAdmin()) {
                // Admin restrictions
                if ($departmentId && $departmentId != $user->department_id) {
                    return response()->json([
                        'error' => 'You can only create discount codes for your department'
                    ], 403);
                }
                
                if ($isUddOfficial) {
                    return response()->json([
                        'error' => 'Only super admins can create UDD official discount codes'
                    ], 403);
                }
                
                // Force department_id for admin
                $validated['department_id'] = $user->department_id;
            }
            
            // SuperAdmin can create codes for any department or UDD official
            if ($user->isSuperAdmin() && $isUddOfficial) {
                $validated['department_id'] = null; // UDD official codes are not department-specific
            }
            
            // Convert code to uppercase
            $validated['code'] = strtoupper($validated['code']);
            $validated['created_by'] = $user->id;
            
            // Convert dates
            if (isset($validated['valid_from'])) {
                $validated['valid_from'] = Carbon::parse($validated['valid_from']);
            }
            if (isset($validated['valid_until'])) {
                $validated['valid_until'] = Carbon::parse($validated['valid_until']);
            }
            
            $discountCode = DiscountCode::create($validated);
            $discountCode->load(['creator', 'department']);
            
            return response()->json([
                'discount_code' => $discountCode,
                'message' => 'Discount code created successfully'
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'error' => 'Validation failed',
                'details' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            \Log::error('Create discount code error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to create discount code'], 500);
        }
    }

    /**
     * Get a specific discount code
     */
    public function show(Request $request, DiscountCode $discountCode): JsonResponse
    {
        try {
            $user = $request->user();
            
            // Check if user can view this discount code
            if (!$user->isSuperAdmin() && !$discountCode->canBeEditedBy($user)) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }
            
            $discountCode->load(['creator', 'department']);
            
            return response()->json(['discount_code' => $discountCode]);
        } catch (\Exception $e) {
            \Log::error('Get discount code error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to fetch discount code'], 500);
        }
    }

    /**
     * Update a discount code
     */
    public function update(Request $request, DiscountCode $discountCode): JsonResponse
    {
        try {
            $user = $request->user();
            
            // Check if user can edit this discount code
            if (!$discountCode->canBeEditedBy($user)) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }
            
            $validated = $request->validate([
                'code' => [
                    'required',
                    'string',
                    'max:50',
                    Rule::unique('discount_codes')->ignore($discountCode->id)
                ],
                'type' => 'required|in:percentage',
                'value' => 'required|numeric|min:0',
                'description' => 'nullable|string|max:500',
                'department_id' => 'nullable|exists:departments,id',
                'is_udd_official' => 'boolean',
                'usage_limit' => 'nullable|integer|min:1',
                'minimum_order_amount' => 'nullable|numeric|min:0',
                'valid_from' => 'nullable|date',
                'valid_until' => 'nullable|date|after:valid_from',
                'is_active' => 'boolean',
            ]);
            
            // Additional validation for percentage type
            if ($validated['type'] === 'percentage' && $validated['value'] > 100) {
                return response()->json([
                    'error' => 'Percentage discount cannot exceed 100%'
                ], 422);
            }
            
            // Admin restrictions
            if ($user->isAdmin()) {
                $departmentId = $validated['department_id'] ?? null;
                $isUddOfficial = $validated['is_udd_official'] ?? false;
                
                if ($departmentId && $departmentId != $user->department_id) {
                    return response()->json([
                        'error' => 'You can only update discount codes for your department'
                    ], 403);
                }
                
                if ($isUddOfficial) {
                    return response()->json([
                        'error' => 'Only super admins can manage UDD official discount codes'
                    ], 403);
                }
            }
            
            // Convert code to uppercase
            $validated['code'] = strtoupper($validated['code']);
            
            // Convert dates
            if (isset($validated['valid_from'])) {
                $validated['valid_from'] = Carbon::parse($validated['valid_from']);
            }
            if (isset($validated['valid_until'])) {
                $validated['valid_until'] = Carbon::parse($validated['valid_until']);
            }
            
            $discountCode->update($validated);
            $discountCode->load(['creator', 'department']);
            
            return response()->json([
                'discount_code' => $discountCode,
                'message' => 'Discount code updated successfully'
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'error' => 'Validation failed',
                'details' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            \Log::error('Update discount code error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to update discount code'], 500);
        }
    }

    /**
     * Delete a discount code
     */
    public function destroy(Request $request, DiscountCode $discountCode): JsonResponse
    {
        try {
            $user = $request->user();
            
            // Check if user can delete this discount code
            if (!$discountCode->canBeEditedBy($user)) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }
            
            // Check if discount code has been used
            if ($discountCode->usage_count > 0) {
                return response()->json([
                    'error' => 'Cannot delete discount code that has been used',
                    'message' => "This discount code has been used {$discountCode->usage_count} time(s)"
                ], 422);
            }
            
            $discountCode->delete();
            
            return response()->json([
                'message' => 'Discount code deleted successfully'
            ]);
        } catch (\Exception $e) {
            \Log::error('Delete discount code error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to delete discount code'], 500);
        }
    }

    /**
     * Validate a discount code for an order (Public endpoint for students)
     */
    public function validate(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'code' => 'required|string',
                'order_amount' => 'required|numeric|min:0',
                'department_id' => 'required|exists:departments,id',
            ]);
            
            $code = strtoupper($validated['code']);
            $orderAmount = $validated['order_amount'];
            $departmentId = $validated['department_id'];
            
            $discountCode = DiscountCode::where('code', $code)
                                      ->valid()
                                      ->first();
            
            if (!$discountCode) {
                return response()->json([
                    'valid' => false,
                    'message' => 'Invalid or expired discount code'
                ], 404);
            }
            
            if (!$discountCode->canBeUsedForOrder($orderAmount, $departmentId)) {
                $message = 'Discount code cannot be used for this order';
                
                if ($discountCode->minimum_order_amount && $orderAmount < $discountCode->minimum_order_amount) {
                    $message = "Minimum order amount of ₱{$discountCode->minimum_order_amount} required";
                }
                
                if ($discountCode->department_id && $discountCode->department_id != $departmentId) {
                    $message = 'Discount code not valid for this department';
                }
                
                return response()->json([
                    'valid' => false,
                    'message' => $message
                ], 422);
            }
            
            $discountAmount = $discountCode->calculateDiscount($orderAmount);
            $finalAmount = $orderAmount - $discountAmount;
            
            return response()->json([
                'valid' => true,
                'discount_code' => [
                    'id' => $discountCode->id,
                    'code' => $discountCode->code,
                    'type' => $discountCode->type,
                    'value' => $discountCode->value,
                    'description' => $discountCode->description,
                ],
                'discount_amount' => $discountAmount,
                'final_amount' => $finalAmount,
                'message' => 'Discount code applied successfully'
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'error' => 'Validation failed',
                'details' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            \Log::error('Validate discount code error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to validate discount code'], 500);
        }
    }

    /**
     * Generate a random discount code
     */
    public function generateCode(Request $request): JsonResponse
    {
        try {
            $user = $request->user();
            
            if (!$user->isAdmin() && !$user->isSuperAdmin()) {
                return response()->json(['error' => 'Unauthorized'], 403);
            }
            
            $validated = $request->validate([
                'prefix' => 'nullable|string|max:10',
                'length' => 'nullable|integer|min:4|max:20',
            ]);
            
            $prefix = $validated['prefix'] ?? '';
            $length = $validated['length'] ?? 8;
            
            do {
                $randomPart = strtoupper(Str::random($length - strlen($prefix)));
                $code = $prefix . $randomPart;
            } while (DiscountCode::where('code', $code)->exists());
            
            return response()->json([
                'code' => $code
            ]);
        } catch (\Exception $e) {
            \Log::error('Generate discount code error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to generate code'], 500);
        }
    }

    /**
     * Get discount code statistics (Admin/SuperAdmin only)
     */
    public function statistics(Request $request): JsonResponse
    {
        try {
            $user = $request->user();
            
            $query = DiscountCode::forUser($user);
            
            $stats = [
                'total_codes' => $query->count(),
                'active_codes' => $query->active()->count(),
                'expired_codes' => $query->where('valid_until', '<', now())->count(),
                'used_codes' => $query->where('usage_count', '>', 0)->count(),
                'total_usage' => $query->sum('usage_count'),
            ];
            
            if ($user->isSuperAdmin()) {
                $stats['by_department'] = DiscountCode::selectRaw('department_id, COUNT(*) as count')
                                                    ->whereNotNull('department_id')
                                                    ->groupBy('department_id')
                                                    ->with('department:id,name')
                                                    ->get();
                $stats['udd_official_codes'] = DiscountCode::where('is_udd_official', true)->count();
            }
            
            return response()->json(['statistics' => $stats]);
        } catch (\Exception $e) {
            \Log::error('Get discount code statistics error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to fetch statistics'], 500);
        }
    }
}