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

        // Handle multiple image uploads
        $imagePaths = [];
        
        // Handle images array (if sent as array)
        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $image) {
                $imagePaths[] = $image->store('listings', 'public');
            }
        }
        
        // Handle individual image fields (image, image_1, image_2, etc.)
        foreach ($request->allFiles() as $key => $file) {
            if (preg_match('/^image(_\d+)?$/', $key)) {
                if (is_array($file)) {
                    foreach ($file as $img) {
                        $imagePaths[] = $img->store('listings', 'public');
                    }
                } else {
                    $imagePaths[] = $file->store('listings', 'public');
                }
            }
        }
        
        // Keep the first image as the main image_path for backward compatibility
        $imagePath = !empty($imagePaths) ? $imagePaths[0] : null;
        
        // Store all images in the images column as JSON
        $imagesJson = !empty($imagePaths) ? json_encode($imagePaths) : null;

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

        // Save multiple images to listing_images table
        if (!empty($imagePaths)) {
            foreach ($imagePaths as $index => $path) {
                $listing->images()->create([
                    'image_path' => $path,
                    'sort_order' => $index,
                ]);
            }
        }

        // Handle size variants if provided
        $sizeVariantsCreated = false;
        if (isset($validated['size_variants']) && !empty($validated['size_variants'])) {
            \Log::info('Size variants received: ' . $validated['size_variants']);
            $sizeVariants = json_decode($validated['size_variants'], true);
            \Log::info('Decoded size variants: ' . print_r($sizeVariants, true));
            
            if (is_array($sizeVariants) && !empty($sizeVariants)) {
                // Check if listing already has any size variants
                $existingVariantsCount = $listing->sizeVariants()->count();
                \Log::info("Existing size variants count for listing {$listing->id}: {$existingVariantsCount}");
                
                if ($existingVariantsCount == 0) {
                    // Only create size variants if none exist
                    foreach ($sizeVariants as $variant) {
                        if (isset($variant['size']) && isset($variant['stock_quantity']) && $variant['stock_quantity'] >= 0) {
                            $listing->sizeVariants()->create([
                                'size' => $variant['size'],
                                'stock_quantity' => $variant['stock_quantity'],
                            ]);
                            \Log::info("Created size variant: {$variant['size']} with stock {$variant['stock_quantity']}");
                            $sizeVariantsCreated = true;
                        }
                    }
                } else {
                    \Log::info("Skipping size variant creation - listing already has {$existingVariantsCount} variants");
                    $sizeVariantsCreated = true; // Mark as created to prevent auto-creation
                }
            }
        }
        
        // Auto-create size variants for clothing items ONLY if none were provided or created
        if (!$sizeVariantsCreated) {
            $category = \App\Models\Category::find($validated['category_id']);
            if ($category) {
                $categoryName = strtolower($category->name);
                $isClothing = str_contains($categoryName, 'clothing') || 
                             str_contains($categoryName, 'shirt') || 
                             str_contains($categoryName, 'tee') ||
                             str_contains($categoryName, 'apparel');
                
                if ($isClothing) {
                    $sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
                    $stockPerSize = max(0, floor(($validated['stock_quantity'] ?? 1) / 6));
                    $remaining = ($validated['stock_quantity'] ?? 1) - ($stockPerSize * 6);
                    
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

        return response()->json($listing->load(['category', 'user', 'department', 'sizeVariants', 'images']));
    }

    /**
     * Get all listings for students
     */
    public function index(Request $request)
    {
        $listings = Listing::with(['category', 'user', 'department', 'sizeVariants', 'images'])
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
        $query = Listing::with(['category', 'user', 'department', 'sizeVariants', 'images']);

        // If admin (not superadmin), only show their department's listings
        if ($user->isAdmin() && !$user->isSuperAdmin()) {
            $query->where('department_id', $user->department_id);
        }

        $listings = $query->latest()->get();

        return response()->json(['listings' => $listings]);
    }

    /**
     * Approve a listing (Super Admin only)
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

        // Only Super Admin can approve listings
        if (!$user->isSuperAdmin()) {
            return response()->json(['message' => 'Only Super Admin can approve listings'], 403);
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
        $listings = Listing::with(['category', 'user', 'department', 'sizeVariants', 'images'])
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
        $listings = Listing::with(['category', 'user', 'department', 'sizeVariants', 'images'])
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

        // Check if user can manage this listing\'s department
        if (!$user->canManageDepartment($listing->department_id)) {
            return response()->json(['message' => 'Cannot update listings from this department'], 403);
        }

        $validated = $request->validate([
            'title' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'image' => 'nullable|image|mimes:jpeg,jpg,png,webp,heic,heif|max:5120',
            'image_*' => 'nullable|image|mimes:jpeg,jpg,png,webp,heic,heif|max:5120',
            'price' => 'nullable|numeric|min:0',
            'status' => 'nullable|in:pending,approved,rejected', // Optional for admins
            'stock_quantity' => 'nullable|integer|min:0', // Optional for stock updates
            'category_id' => 'nullable|exists:categories,id',
            'department_id' => 'nullable|exists:departments,id',
            'images_to_remove' => 'nullable|array',
            'images_to_remove.*' => 'integer|exists:listing_images,id',
            'remove_all_images' => 'nullable|boolean',
        ]);

        // Handle multiple image removals
        if ($request->has('remove_all_images') && $request->input('remove_all_images') === 'true') {
            // Remove all existing images
            foreach ($listing->images as $image) {
                \Storage::disk('public')->delete($image->image_path);
                $image->delete();
            }
        } elseif ($request->has('images_to_remove')) {
            // Remove specific images
            $imagesToRemove = $request->input('images_to_remove');
            foreach ($imagesToRemove as $imageId) {
                $image = $listing->images()->find($imageId);
                if ($image) {
                    \Storage::disk('public')->delete($image->image_path);
                    $image->delete();
                }
            }
        }

        // Handle new image uploads
        $uploadedFiles = [];
        
        // Handle single image (legacy support)
        if ($request->hasFile('image')) {
            $uploadedFiles[] = $request->file('image');
        }
        
        // Handle multiple images
        foreach ($request->allFiles() as $key => $file) {
            if (preg_match('/^image_\d+$/', $key) && $file) {
                $uploadedFiles[] = $file;
            }
        }
        
        // Store new images
        foreach ($uploadedFiles as $file) {
            $imagePath = $file->store('listings', 'public');
            $listing->images()->create([
                'image_path' => $imagePath,
                'is_primary' => $listing->images()->count() === 0, // First image is primary
            ]);
        }

        // Handle legacy single image removal
        if ($request->has('remove_image') && $request->input('remove_image') === 'true') {
            if ($listing->image_path) {
                \Storage::disk('public')->delete($listing->image_path);
                $listing->image_path = null;
            }
        }

        // Only allow status changes for superadmins
        if (isset($validated['status']) && !$user->isSuperAdmin()) {
            unset($validated['status']); // Remove status from update for non-superadmins
        }

        $listing->fill($validated);
        $listing->save();

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

    /**
     * Get current user's own listings (regardless of status)
     */
    public function userListings(Request $request)
    {
        $user = $request->user();
        
        $listings = Listing::with(['category', 'user', 'department', 'sizeVariants', 'images'])
                          ->where('user_id', $user->id)
                          ->latest()
                          ->get();

        return response()->json(['listings' => $listings]);
    }
}