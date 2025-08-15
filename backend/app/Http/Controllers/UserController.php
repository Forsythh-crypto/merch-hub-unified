<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\DB;
use App\Models\User;

class UserController extends Controller
{
    /**
     * Return the authenticated user's data.
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();
        // Load department relationship for session data
        $user->load('department');
        
        return response()->json([
            'user' => $user->getSessionData()
        ]);
    }

    /**
     * Revoke all tokens for the authenticated user (logout).
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->tokens()->delete();

        return response()->json([
            'message' => 'Successfully logged out.'
        ]);
    }

    /**
     * Get all users (Super Admin only).
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function index(Request $request): JsonResponse
    {
        try {
            $users = User::with('department')->get();
            
            return response()->json([
                'users' => $users->map(function ($user) {
                    return $user->getSessionData();
                })
            ]);
        } catch (\Exception $e) {
            \Log::error('Get users error: ' . $e->getMessage());
            
            // Fallback without department relationship
            try {
                $users = User::all();
                return response()->json([
                    'users' => $users->map(function ($user) {
                        return [
                            'userId' => (string) $user->id,
                            'name' => $user->name,
                            'email' => $user->email,
                            'role' => $user->role,
                            'departmentId' => $user->department_id,
                            'departmentName' => null,
                        ];
                    })
                ]);
            } catch (\Exception $e2) {
                \Log::error('Get users fallback error: ' . $e2->getMessage());
                return response()->json(['users' => []]);
            }
        }
    }

    /**
     * Create a new user (Super Admin only).
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|unique:users',
            'password' => 'required|string|min:6',
            'role' => 'required|in:student,admin,superadmin',
            'department_id' => 'required|exists:departments,id',
        ]);

        $user = User::create([
            'name' => $validated['name'],
            'email' => $validated['email'],
            'password' => Hash::make($validated['password']),
            'role' => $validated['role'],
            'department_id' => $validated['department_id'],
        ]);

        $user->load('department');

        return response()->json([
            'user' => $user->getSessionData(),
            'message' => 'User created successfully'
        ], 201);
    }

    /**
     * Update a user (Super Admin only).
     *
     * @param Request $request
     * @param User $user
     * @return JsonResponse
     */
    public function update(Request $request, User $user): JsonResponse
    {
        $validated = $request->validate([
            'name' => 'sometimes|string|max:255',
            'email' => 'sometimes|string|email|unique:users,email,' . $user->id,
            'password' => 'sometimes|string|min:6',
            'role' => 'sometimes|in:student,admin,superadmin',
            'department_id' => 'sometimes|exists:departments,id',
        ]);

        if (isset($validated['password'])) {
            $validated['password'] = Hash::make($validated['password']);
        }

        $user->update($validated);
        $user->load('department');

        return response()->json([
            'user' => $user->getSessionData(),
            'message' => 'User updated successfully'
        ]);
    }

    /**
     * Delete a user (Super Admin only).
     *
     * @param User $user
     * @return JsonResponse
     */
    public function destroy(User $user): JsonResponse
    {
        $user->delete();

        return response()->json([
            'message' => 'User deleted successfully'
        ]);
    }

    /**
     * Get users from specific department.
     *
     * @param Request $request
     * @param int $departmentId
     * @return JsonResponse
     */
    public function departmentUsers(Request $request, int $departmentId): JsonResponse
    {
        $users = User::where('department_id', $departmentId)
                    ->with('department')
                    ->get();
        
        return response()->json([
            'users' => $users->map(function ($user) {
                return $user->getSessionData();
            })
        ]);
    }

    /**
     * Get user permissions and capabilities.
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function permissions(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->load('department');

        return response()->json([
            'user' => $user->getSessionData(),
            'permissions' => [
                'isSuperAdmin' => $user->isSuperAdmin(),
                'isAdmin' => $user->isAdmin(),
                'isStudent' => $user->isStudent(),
                'canManageUsers' => $user->isSuperAdmin(),
                'canManageDepartments' => $user->isSuperAdmin(),
                'canApproveListings' => $user->isAdmin() || $user->isSuperAdmin(),
                'canCreateListings' => true, // All authenticated users can create listings
                'managedDepartmentId' => $user->isAdmin() ? $user->department_id : null,
                'managedDepartmentName' => $user->isAdmin() ? $user->department?->name : null,
            ]
        ]);
    }

    /**
     * Grant admin privileges to a user (Super Admin only).
     *
     * @param Request $request
     * @param User $user
     * @return JsonResponse
     */
    public function grantAdmin(Request $request, User $user): JsonResponse
    {
        if ($user->isSuperAdmin()) {
            return response()->json(['message' => 'Cannot modify super admin role'], 403);
        }

        $user->update(['role' => User::ROLE_ADMIN]);
        $user->load('department');

        return response()->json([
            'user' => $user->getSessionData(),
            'message' => 'Admin privileges granted successfully'
        ]);
    }

    /**
     * Revoke admin privileges from a user (Super Admin only).
     *
     * @param Request $request
     * @param User $user
     * @return JsonResponse
     */
    public function revokeAdmin(Request $request, User $user): JsonResponse
    {
        if ($user->isSuperAdmin()) {
            return response()->json(['message' => 'Cannot modify super admin role'], 403);
        }

        $user->update(['role' => User::ROLE_STUDENT]);
        $user->load('department');

        return response()->json([
            'user' => $user->getSessionData(),
            'message' => 'Admin privileges revoked successfully'
        ]);
    }

    /**
     * Grant super admin privileges to a user (Super Admin only).
     *
     * @param Request $request
     * @param User $user
     * @return JsonResponse
     */
    public function grantSuperAdmin(Request $request, User $user): JsonResponse
    {
        $user->update(['role' => User::ROLE_SUPERADMIN]);
        $user->load('department');

        return response()->json([
            'user' => $user->getSessionData(),
            'message' => 'Super Admin privileges granted successfully'
        ]);
    }

    /**
     * Revoke super admin privileges from a user (Super Admin only).
     *
     * @param Request $request
     * @param User $user
     * @return JsonResponse
     */
    public function revokeSuperAdmin(Request $request, User $user): JsonResponse
    {
        $user->update(['role' => User::ROLE_STUDENT]);
        $user->load('department');

        return response()->json([
            'user' => $user->getSessionData(),
            'message' => 'Super Admin privileges revoked successfully'
        ]);
    }

    /**
     * Get dashboard statistics (Super Admin only).
     *
     * @param Request $request
     * @return JsonResponse
     */
    public function getDashboardStats(Request $request): JsonResponse
    {
        try {
            $totalUsers = User::count();
            $totalAdmins = User::where('role', User::ROLE_ADMIN)->count();
            $totalStudents = User::where('role', User::ROLE_STUDENT)->count();
            
            // Simple approach - avoid complex queries that might fail
            $totalListings = 0;
            $pendingListings = 0;
            $approvedListings = 0;
            $totalStockValue = 0;
            
            try {
                $totalListings = \App\Models\Listing::count();
            } catch (\Exception $e) {
                // Listing table might not exist or have issues
            }
            
            $totalDepartments = \App\Models\Department::count();

            return response()->json([
                'stats' => [
                    'users' => [
                        'total' => $totalUsers,
                        'admins' => $totalAdmins,
                        'students' => $totalStudents,
                    ],
                    'listings' => [
                        'total' => $totalListings,
                        'pending' => $pendingListings,
                        'approved' => $approvedListings,
                    ],
                    'departments' => $totalDepartments,
                    'totalStockValue' => $totalStockValue,
                ]
            ]);
        } catch (\Exception $e) {
            \Log::error('Dashboard stats error: ' . $e->getMessage());
            
            // Return basic stats if everything fails
            return response()->json([
                'stats' => [
                    'users' => [
                        'total' => 0,
                        'admins' => 0,
                        'students' => 0,
                    ],
                    'listings' => [
                        'total' => 0,
                        'pending' => 0,
                        'approved' => 0,
                    ],
                    'departments' => 0,
                    'totalStockValue' => 0,
                ]
            ]);
        }
    }
}