<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\ListingController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\DepartmentController;
use App\Http\Controllers\OrderController;
use App\Http\Controllers\NotificationController;
use App\Http\Controllers\DiscountCodeController;
use Illuminate\Support\Facades\File;


Route::get('/ping', function () {
    return response()->json(['message' => 'pong']);
});

// Test email route
Route::get('/test-email', function () {
    try {
        \Illuminate\Support\Facades\Mail::raw('Test email from Laravel', function ($message) {
            $message->to('test@example.com')
                    ->subject('Test Email');
        });
        return response()->json(['message' => 'Email sent successfully']);
    } catch (\Exception $e) {
        return response()->json(['error' => $e->getMessage()], 500);
    }
});

// Test pickup ready email
Route::get('/test-pickup-email/{orderId}', function ($orderId) {
    try {
        $order = \App\Models\Order::with(['user', 'listing', 'department'])->findOrFail($orderId);
        
        if (!$order->user) {
            return response()->json(['error' => 'Order has no user associated'], 400);
        }
        
        \Illuminate\Support\Facades\Log::info('Testing pickup email for order: ' . $order->order_number);
        \Illuminate\Support\Facades\Log::info('User email: ' . $order->user->email);
        
        // Test the actual pickup ready email template
        $data = [
            'order' => $order,
            'user' => $order->user,
            'listing' => $order->listing,
            'department' => $order->department,
        ];
        
        \Illuminate\Support\Facades\Log::info('Email data: ' . json_encode($data));
        
        \Illuminate\Support\Facades\Mail::send('emails.pickup-ready', $data, function ($message) use ($order) {
            $message->to($order->user->email)
                    ->subject('Your Order is Ready for Pickup - ' . $order->order_number);
        });
        
        return response()->json(['message' => 'Pickup ready email sent successfully']);
    } catch (\Exception $e) {
        \Illuminate\Support\Facades\Log::error('Email test failed: ' . $e->getMessage());
        \Illuminate\Support\Facades\Log::error('Stack trace: ' . $e->getTraceAsString());
        return response()->json(['error' => $e->getMessage()], 500);
    }
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

// Public listings endpoint for guest users
Route::get('/public/listings', [ListingController::class, 'index']);

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

// Simple order creation without authentication (for testing)
Route::post('/simple-orders', [OrderController::class, 'simpleStore']);
Route::get('/simple-orders', [OrderController::class, 'simpleIndex']);

Route::middleware('auth:sanctum')->group(function () {
    // Basic authenticated routes
    Route::get('/user', [UserController::class, 'show']);
    Route::get('/user/permissions', [UserController::class, 'permissions']);
    Route::post('/logout', [UserController::class, 'logout']);
    Route::get('/categories', [CategoryController::class, 'index']);
    
    // User routes (for all authenticated users)
    Route::get('/listings', [ListingController::class, 'index']);
    Route::get('/user/listings', [ListingController::class, 'userListings']);
    
    // Order routes (for all authenticated users)
    Route::post('/orders', [OrderController::class, 'store']);
    Route::get('/orders', [OrderController::class, 'index']);
    Route::get('/orders/{id}', [OrderController::class, 'show']);
    Route::post('/orders/{id}/cancel', [OrderController::class, 'cancel']);
    Route::post('/orders/{id}/upload-receipt', [OrderController::class, 'uploadReceipt']);
    
    // Discount code validation route
    Route::post('/discount-codes/validate', [DiscountCodeController::class, 'validate']);
    Route::post('/discount-codes/calculate', [DiscountCodeController::class, 'calculate']);
    
    // Notification routes (for all authenticated users)
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::get('/notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('/notifications/mark-read', [NotificationController::class, 'markAsRead']);
    Route::post('/notifications/{id}/mark-read', [NotificationController::class, 'markAsReadSingle']);
    Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);
    Route::delete('/notifications', [NotificationController::class, 'clearAll']);
    
    // Student routes
    Route::middleware('role:student')->group(function () {
        Route::post('/listings', [ListingController::class, 'store']);
    });
    
    // Admin routes (can manage their department)
    Route::middleware('role:admin,superadmin')->group(function () {
        Route::get('/admin/listings', [ListingController::class, 'adminIndex']);
        Route::post('/listings', [ListingController::class, 'store']);  // Allow admins to create listings
        
        // Admin order routes
        Route::get('/admin/orders', [OrderController::class, 'adminIndex']);
        Route::put('/admin/orders/{id}/status', [OrderController::class, 'updateStatus']);
        Route::post('/admin/orders/{id}/confirm-reservation-fee', [OrderController::class, 'confirmReservationFee']);
        
        // Allow admins to update their own listings (but not status)
        Route::put('/admin/listings/{listing}', [ListingController::class, 'update']);
        Route::put('/admin/listings/{listing}/size-variants', [ListingController::class, 'updateSizeVariants']);
        Route::delete('/admin/listings/{listing}', [ListingController::class, 'destroy']);
        
        // Discount code routes for admins (department-restricted)
        Route::get('/admin/discount-codes', [DiscountCodeController::class, 'index']);
        Route::post('/admin/discount-codes', [DiscountCodeController::class, 'store']);
        Route::put('/admin/discount-codes/{discountCode}', [DiscountCodeController::class, 'update']);
        Route::delete('/admin/discount-codes/{discountCode}', [DiscountCodeController::class, 'destroy']);
        Route::get('/admin/discount-codes/stats', [DiscountCodeController::class, 'stats']);
    });
    
    // Super Admin only routes
    Route::middleware('role:superadmin')->group(function () {
        Route::get('/admin/users', [UserController::class, 'index']);
        Route::post('/admin/users', [UserController::class, 'store']);
        Route::put('/admin/users/{user}', [UserController::class, 'update']);
        Route::put('/admin/users/{user}/grant-admin', [UserController::class, 'grantAdmin']);
        Route::put('/admin/users/{user}/grant-superadmin', [UserController::class, 'grantSuperAdmin']);
        Route::put('/admin/users/{user}/revoke-admin', [UserController::class, 'revokeAdmin']);
        Route::put('/admin/users/{user}/revoke-superadmin', [UserController::class, 'revokeSuperAdmin']);
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
                        'orders' => [
                            'total' => \App\Models\Order::count(),
                            'pending' => \App\Models\Order::where('status', 'pending')->count(),
                            'confirmed' => \App\Models\Order::where('status', 'confirmed')->count(),
                            'ready_for_pickup' => \App\Models\Order::where('status', 'ready_for_pickup')->count(),
                            'completed' => \App\Models\Order::where('status', 'completed')->count(),
                            'cancelled' => \App\Models\Order::where('status', 'cancelled')->count(),
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
        Route::put('/admin/listings/{listing}/approve', [ListingController::class, 'approve']);
        
        // Additional discount code routes for superadmins (all departments)
        Route::get('/admin/discount-codes/all', [DiscountCodeController::class, 'superAdminIndex']);
    });
    
    // Department-specific routes (admin can only access their own department)
    Route::middleware('department.access')->group(function () {
        Route::get('/departments/{department_id}/listings', [ListingController::class, 'departmentListings']);
        Route::get('/departments/{department_id}/users', [UserController::class, 'departmentUsers']);
    });
});