<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Listing;
use App\Models\Category;
use App\Models\Department;

class ListingController extends Controller
{
    public function store(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            // Max is in kilobytes; allow common mobile formats
            'image' => 'nullable|image|mimes:jpeg,jpg,png,webp,heic,heif|max:5120',
            'price' => 'required|numeric|min:0',
            'size' => 'nullable|string|max:10',
            'category_id' => 'required|exists:categories,id',
            'department_id' => 'nullable|exists:departments,id',
            'status' => 'nullable|in:pending,approved,rejected',
            'stock_quantity' => 'nullable|integer|min:0',
            'size_variants' => 'nullable|string', // JSON string from frontend
        ]);

        // Handle image upload
        $imagePath = $request->hasFile('image')
            ? $request->file('image')->store('listings', 'public')
            : null;

        // Determine department_id based on user role and input
        $departmentId = $user->department_id; // Default to user's department
        
        // If superadmin and department_id is provided, use it
        if ($user->isSuperAdmin() && isset($validated['department_id'])) {
            $departmentId = $validated['department_id'];
        }
        // If admin and department_id is provided, validate they can manage that department
        elseif ($user->isAdmin() && isset($validated['department_id'])) {
            if ($user->canManageDepartment($validated['department_id'])) {
                $departmentId = $validated['department_id'];
            } else {
                return response()->json(['message' => 'Cannot create listings for this department'], 403);
            }
        }

        // Check if trying to create listing for Official UDD Merch department
        if (isset($validated['department_id'])) {
            $department = \App\Models\Department::find($validated['department_id']);
            if ($department && $department->name === 'Official UDD Merch' && !$user->isSuperAdmin()) {
                return response()->json(['message' => 'Only superadmins can create listings for Official UDD Merch'], 403);
            }
        }

        // Determine status based on role
        $initialStatus = 'pending';
        if (isset($validated['status']) && $user->isSuperAdmin()) {
            $initialStatus = $validated['status'];
        }

        // Create the listing
        $listing = Listing::create([
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'image_path' => $imagePath,
            'price' => $validated['price'],
            'size' => $validated['size'] ?? null,
            'category_id' => $validated['category_id'],
            'department_id' => $departmentId,
            'user_id' => $user->id,
            'stock_quantity' => $validated['stock_quantity'] ?? 1,
            'status' => $initialStatus,
        ]);

        // Handle size variants if provided
        if (isset($validated['size_variants']) && !empty($validated['size_variants'])) {
            \Log::info('Size variants received: ' . $validated['size_variants']);
            $sizeVariants = json_decode($validated['size_variants'], true);
            \Log::info('Decoded size variants: ' . print_r($sizeVariants, true));
            
            if (is_array($sizeVariants)) {
                foreach ($sizeVariants as $variant) {
                    if (isset($variant['size']) && isset($variant['stock_quantity']) && $variant['stock_quantity'] > 0) {
                        $listing->sizeVariants()->create([
                            'size' => $variant['size'],
                            'stock_quantity' => $variant['stock_quantity'],
                        ]);
                        \Log::info("Created size variant: {$variant['size']} with stock {$variant['stock_quantity']}");
                    }
                }
            }
        }

        return response()->json($listing->load(['category', 'user', 'department', 'sizeVariants']));
    }

    /**
     * Get all listings for students
     */
    public function index(Request $request)
    {
        $listings = Listing::with(['category', 'user', 'department', 'sizeVariants'])
                          ->where('status', 'approved')
                          ->latest()
                          ->get();

        return response()->json(['listings' => $listings]);
    }

    /**
     * Get all listings for admin review
     */
    public function adminIndex(Request $request)
    {
        $user = $request->user();
        $query = Listing::with(['category', 'user', 'department', 'sizeVariants']);

        // If admin (not superadmin), only show their department's listings
        if ($user->isAdmin() && !$user->isSuperAdmin()) {
            $query->where('department_id', $user->department_id);
        }

        $listings = $query->latest()->get();

        return response()->json(['listings' => $listings]);
    }

    /**
     * Approve a listing
     */
    public function approve(Request $request, Listing $listing)
    {
        $user = $request->user();

        // Log the approval request
        \Log::info('Approval request for listing ID: ' . $listing->id);
        \Log::info('Listing before approval: ' . json_encode([
            'id' => $listing->id,
            'title' => $listing->title,
            'price' => $listing->price,
            'stock_quantity' => $listing->stock_quantity,
            'status' => $listing->status,
        ]));

        // Check if user can manage this listing's department
        if (!$user->canManageDepartment($listing->department_id)) {
            return response()->json(['message' => 'Cannot approve listings from this department'], 403);
        }

        $listing->update(['status' => 'approved']);

        // Log the listing after approval
        \Log::info('Listing after approval: ' . json_encode([
            'id' => $listing->id,
            'title' => $listing->title,
            'price' => $listing->price,
            'stock_quantity' => $listing->stock_quantity,
            'status' => $listing->status,
        ]));

        return response()->json([
            'listing' => $listing->load(['category', 'user', 'department', 'sizeVariants']),
            'message' => 'Listing approved successfully'
        ]);
    }

    /**
     * Delete a listing
     */
    public function destroy(Listing $listing)
    {
        $user = request()->user();

        // Check if user can manage this listing's department
        if (!$user->canManageDepartment($listing->department_id)) {
            return response()->json(['message' => 'Cannot delete listings from this department'], 403);
        }

        $listing->delete();

        return response()->json(['message' => 'Listing deleted successfully']);
    }

    /**
     * Get listings from specific department
     */
    public function departmentListings(Request $request, int $departmentId)
    {
        $listings = Listing::with(['category', 'user', 'department', 'sizeVariants'])
                          ->where('department_id', $departmentId)
                          ->latest()
                          ->get();

        return response()->json(['listings' => $listings]);
    }

    /**
     * Get all listings for super admin (can see everything)
     */
    public function superAdminIndex(Request $request)
    {
        $listings = Listing::with(['category', 'user', 'department', 'sizeVariants'])
                          ->latest()
                          ->get();

        return response()->json(['listings' => $listings]);
    }

    /**
     * Update stock quantity for a listing (Super Admin only)
     */
    public function updateStock(Request $request, Listing $listing)
    {
        $validated = $request->validate([
            'stock_quantity' => 'required|integer|min:0',
        ]);

        $listing->update(['stock_quantity' => $validated['stock_quantity']]);

        return response()->json([
            'listing' => $listing->load(['category', 'user', 'department', 'sizeVariants']),
            'message' => 'Stock quantity updated successfully'
        ]);
    }

    /**
     * Update a listing (Admin and Super Admin)
     */
    public function update(Request $request, Listing $listing)
    {
        $user = $request->user();

        // Check if user can manage this listing's department
        if (!$user->canManageDepartment($listing->department_id)) {
            return response()->json(['message' => 'Cannot update listings from this department'], 403);
        }

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'price' => 'required|numeric|min:0',
            'status' => 'nullable|in:pending,approved,rejected', // Optional for admins
            'stock_quantity' => 'nullable|integer|min:0', // Optional for stock updates
        ]);

        // Only allow status changes for superadmins
        if (isset($validated['status']) && !$user->isSuperAdmin()) {
            unset($validated['status']); // Remove status from update for non-superadmins
        }

        $listing->update($validated);

        return response()->json([
            'listing' => $listing->load(['category', 'user', 'department', 'sizeVariants']),
            'message' => 'Listing updated successfully'
        ]);
    }

    /**
     * Update size variants for a listing (Admin and Super Admin)
     */
    public function updateSizeVariants(Request $request, Listing $listing)
    {
        $user = $request->user();

        // Check if user can manage this listing's department
        if (!$user->canManageDepartment($listing->department_id)) {
            return response()->json(['message' => 'Cannot update listings from this department'], 403);
        }

        $validated = $request->validate([
            'size_variants' => 'required|array',
            'size_variants.*.size' => 'required|string|max:10',
            'size_variants.*.stock_quantity' => 'required|integer|min:0',
        ]);

        // Delete existing size variants
        $listing->sizeVariants()->delete();

        // Create new size variants
        foreach ($validated['size_variants'] as $variant) {
            $listing->sizeVariants()->create([
                'size' => $variant['size'],
                'stock_quantity' => $variant['stock_quantity'],
            ]);
        }

        return response()->json([
            'listing' => $listing->load(['category', 'user', 'department', 'sizeVariants']),
            'message' => 'Size variants updated successfully'
        ]);
    }
}