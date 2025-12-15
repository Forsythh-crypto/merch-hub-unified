<?php

namespace App\Http\Controllers;

use App\Models\Department;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class DepartmentController extends Controller
{
    /**
     * Get all departments for public use
     */
    public function index(): JsonResponse
    {
        try {
            $departments = Department::select('id', 'name', 'description')
                ->orderBy('name')
                ->get();

            return response()->json($departments);
        } catch (\Exception $e) {
            \Log::error('Get departments error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to fetch departments'], 500);
        }
    }

    /**
     * Get all departments with full details (Super Admin only)
     */
    public function adminIndex(): JsonResponse
    {
        try {
            $departments = Department::withCount(['users', 'products'])
                ->orderBy('name')
                ->get();

            return response()->json(['departments' => $departments]);
        } catch (\Exception $e) {
            \Log::error('Get admin departments error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to fetch departments'], 500);
        }
    }

    /**
     * Create a new department (Super Admin only)
     */
    public function store(Request $request): JsonResponse
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string|max:255|unique:departments',
                'description' => 'nullable|string|max:1000',
                'logo' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
                'gcash_qr_image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            ]);

            $departmentData = [
                'name' => $validated['name'],
                'description' => $validated['description'] ?? null,
            ];

            // Handle logo upload
            if ($request->hasFile('logo')) {
                $logo = $request->file('logo');
                $logoName = time() . '_logo_' . $logo->getClientOriginalName();
                $logoPath = $logo->storeAs('department_logos', $logoName, 'public');
                $departmentData['logo_path'] = $logoPath;
            }

            // Handle QR code upload
            if ($request->hasFile('gcash_qr_image')) {
                $qr = $request->file('gcash_qr_image');
                $qrName = time() . '_qr_' . $qr->getClientOriginalName();
                $qrPath = $qr->storeAs('department_qr_codes', $qrName, 'public');
                $departmentData['gcash_qr_image_path'] = $qrPath;
            }

            $department = Department::create($departmentData);

            return response()->json([
                'department' => $department,
                'message' => 'Department created successfully'
            ], 201);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'error' => 'Validation failed',
                'details' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            \Log::error('Create department error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to create department'], 500);
        }
    }

    /**
     * Update a department (Super Admin only)
     */
    public function update(Request $request, Department $department): JsonResponse
    {
        try {
            $validated = $request->validate([
                'name' => 'required|string|max:255|unique:departments,name,' . $department->id,
                'description' => 'nullable|string|max:1000',
                'logo' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
                'gcash_qr_image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            ]);

            $departmentData = [
                'name' => $validated['name'],
                'description' => $validated['description'] ?? null,
            ];

            // Handle logo upload
            if ($request->hasFile('logo')) {
                // Delete old logo if exists
                if ($department->logo_path && \Storage::disk('public')->exists($department->logo_path)) {
                    \Storage::disk('public')->delete($department->logo_path);
                }

                $logo = $request->file('logo');
                $logoName = time() . '_logo_' . $logo->getClientOriginalName();
                $logoPath = $logo->storeAs('department_logos', $logoName, 'public');
                $departmentData['logo_path'] = $logoPath;
            }

            // Handle QR code removal
            if ($request->boolean('remove_gcash_qr_image')) {
                if ($department->gcash_qr_image_path && \Storage::disk('public')->exists($department->gcash_qr_image_path)) {
                    \Storage::disk('public')->delete($department->gcash_qr_image_path);
                }
                $departmentData['gcash_qr_image_path'] = null;
            }

            // Handle QR code upload
            if ($request->hasFile('gcash_qr_image')) {
                // Delete old QR code if exists
                if ($department->gcash_qr_image_path && \Storage::disk('public')->exists($department->gcash_qr_image_path)) {
                    \Storage::disk('public')->delete($department->gcash_qr_image_path);
                }

                $qr = $request->file('gcash_qr_image');
                $qrName = time() . '_qr_' . $qr->getClientOriginalName();
                $qrPath = $qr->storeAs('department_qr_codes', $qrName, 'public');
                $departmentData['gcash_qr_image_path'] = $qrPath;
            }

            $department->update($departmentData);

            return response()->json([
                'department' => $department,
                'message' => 'Department updated successfully'
            ]);
        } catch (\Illuminate\Validation\ValidationException $e) {
            return response()->json([
                'error' => 'Validation failed',
                'details' => $e->errors()
            ], 422);
        } catch (\Exception $e) {
            \Log::error('Update department error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to update department'], 500);
        }
    }

    /**
     * Delete a department (Super Admin only)
     */
    public function destroy(Department $department): JsonResponse
    {
        try {
            // Check if department has users
            $userCount = $department->users()->count();
            if ($userCount > 0) {
                return response()->json([
                    'error' => 'Cannot delete department',
                    'message' => "Department has $userCount user(s). Please reassign or delete users first."
                ], 422);
            }

            // Check if department has products
            $productCount = $department->products()->count();
            if ($productCount > 0) {
                return response()->json([
                    'error' => 'Cannot delete department',
                    'message' => "Department has $productCount product(s). Please reassign or delete products first."
                ], 422);
            }

            // Delete logo file if exists
            if ($department->logo_path && \Storage::disk('public')->exists($department->logo_path)) {
                \Storage::disk('public')->delete($department->logo_path);
            }

            $department->delete();

            return response()->json([
                'message' => 'Department deleted successfully'
            ]);
        } catch (\Exception $e) {
            \Log::error('Delete department error: ' . $e->getMessage());
            return response()->json(['error' => 'Failed to delete department'], 500);
        }
    }
}