<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\ListingController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\DepartmentController;
use Illuminate\Support\Facades\File;


Route::get('/ping', function () {
    return response()->json(['message' => 'pong']);
});

// Simple test endpoint
Route::get('/test', function () {
    try {
        $userCount = \App\Models\User::count();
        return response()->json([
            'status' => 'success',
            'user_count' => $userCount,
            'message' => 'Basic test working'
        ]);
    } catch (\Exception $e) {
        return response()->json([
            'status' => 'error',
            'message' => $e->getMessage(),
            'line' => $e->getLine(),
            'file' => $e->getFile()
        ], 500);
    }
});
Route::get('/departments', [DepartmentController::class, 'index']);

// Public file serving for uploaded assets (avoids 403 on /storage symlink)
Route::get('/files/{path}', function ($path) {
    $fullPath = storage_path('app/public/' . $path);
    if (!File::exists($fullPath)) {
        return response()->json(['message' => 'File not found'], 404);
    }
    return response()->file($fullPath);
})->where('path', '.*');

Route::post('/login', [AuthController::class, 'login'])->name('login');
Route::post('/register', [AuthController::class, 'register']);

Route::middleware('auth:sanctum')->group(function () {
    // Basic authenticated routes
    Route::get('/user', [UserController::class, 'show']);
    Route::get('/user/permissions', [UserController::class, 'permissions']);
    Route::post('/logout', [UserController::class, 'logout']);
    Route::get('/categories', [CategoryController::class, 'index']);
    
    // Student routes
    Route::middleware('role:student')->group(function () {
        Route::post('/listings', [ListingController::class, 'store']);
        Route::get('/listings', [ListingController::class, 'index']);
    });
    
    // Admin routes (can manage their department)
    Route::middleware('role:admin,superadmin')->group(function () {
        Route::get('/admin/listings', [ListingController::class, 'adminIndex']);
        Route::post('/listings', [ListingController::class, 'store']);  // Allow admins to create listings
        Route::put('/admin/listings/{listing}/approve', [ListingController::class, 'approve']);
        Route::delete('/admin/listings/{listing}', [ListingController::class, 'destroy']);
    });
    
    // Super Admin only routes
    Route::middleware('role:superadmin')->group(function () {
        Route::get('/admin/users', [UserController::class, 'index']);
        Route::post('/admin/users', [UserController::class, 'store']);
        Route::put('/admin/users/{user}', [UserController::class, 'update']);
        Route::put('/admin/users/{user}/grant-admin', [UserController::class, 'grantAdmin']);
        Route::put('/admin/users/{user}/revoke-admin', [UserController::class, 'revokeAdmin']);
        Route::delete('/admin/users/{user}', [UserController::class, 'destroy']);
        Route::get('/admin/departments', [DepartmentController::class, 'adminIndex']);
        Route::post('/admin/departments', [DepartmentController::class, 'store']);
        Route::put('/admin/departments/{department}', [DepartmentController::class, 'update']);
        Route::delete('/admin/departments/{department}', [DepartmentController::class, 'destroy']);
        Route::get('/admin/dashboard-stats', function () {
            try {
                return response()->json([
                    'stats' => [
                        'users' => [
                            'total' => \App\Models\User::count(),
                            'admins' => \App\Models\User::where('role', 'admin')->count(),
                            'students' => \App\Models\User::where('role', 'student')->count(),
                        ],
                        'listings' => [
                            'total' => \App\Models\Listing::count(),
                            'pending' => \App\Models\Listing::where('status', 'pending')->count(),
                            'approved' => \App\Models\Listing::where('status', 'approved')->count(),
                        ],
                        'departments' => \App\Models\Department::count(),
                        'totalStockValue' => \App\Models\Listing::where('status', 'approved')->sum(\DB::raw('price * stock_quantity')),
                    ]
                ]);
            } catch (\Exception $e) {
                return response()->json([
                    'error' => $e->getMessage(),
                    'line' => $e->getLine(),
                    'file' => basename($e->getFile())
                ], 500);
            }
        });
        Route::get('/admin/all-listings', [ListingController::class, 'superAdminIndex']);
        Route::put('/admin/listings/{listing}/update-stock', [ListingController::class, 'updateStock']);
    });
    
    // Department-specific routes (admin can only access their own department)
    Route::middleware('department.access')->group(function () {
        Route::get('/departments/{department_id}/listings', [ListingController::class, 'departmentListings']);
        Route::get('/departments/{department_id}/users', [UserController::class, 'departmentUsers']);
    });
});