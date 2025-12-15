<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\Listing;
use App\Models\User;
use App\Models\DiscountCode;
use App\Services\NotificationService;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;

class OrderController extends Controller
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }
    /**
     * Create a new order
     */
    public function store(Request $request)
    {
        try {
            $user = $request->user();

            $validated = $request->validate([
                'items' => 'required|array|min:1',
                'items.*.listing_id' => 'required|exists:listings,id',
                'items.*.quantity' => 'required|integer|min:1',
                'items.*.size' => 'nullable|string|max:10',
                'email' => 'required|email',
                'notes' => 'nullable|string|max:500',
                'discount_code' => 'nullable|string|max:50',
            ]);

            $totalOriginalAmount = 0;
            $orderItemsData = [];
            $departmentId = null;

            // Validate stock and calculate total for all items
            foreach ($validated['items'] as $itemData) {
                $listing = Listing::with(['sizeVariants'])->findOrFail($itemData['listing_id']);

                // Ensure all items belong to the same department (simplifies discount/order logic)
                if ($departmentId === null) {
                    $departmentId = $listing->department_id;
                } elseif ($departmentId !== $listing->department_id) {
                    // Ideally, frontend should group by department.
                    // If mixed, we might default to first or handle differently.
                    // For now, let's assume valid grouping.
                }

                $size = $itemData['size'] ?? null;
                $quantity = $itemData['quantity'];

                // Check Stock
                if ($size && $listing->sizeVariants->isNotEmpty()) {
                    $sizeVariant = $listing->sizeVariants->where('size', $size)->first();
                    if (!$sizeVariant) {
                        return response()->json(['message' => "Size {$size} not available for {$listing->title}"], 400);
                    }
                    // Allow pre-orders (stock 0), only block if stock > 0 but insufficient
                    if ($sizeVariant->stock_quantity > 0 && $sizeVariant->stock_quantity < $quantity) {
                        return response()->json(['message' => "Insufficient stock for {$listing->title} ({$size})"], 400);
                    }
                } else {
                    if ($listing->stock_quantity > 0 && $listing->stock_quantity < $quantity) {
                        return response()->json(['message' => "Insufficient stock for {$listing->title}"], 400);
                    }
                }

                $price = $listing->price;
                $subtotal = $price * $quantity;
                $totalOriginalAmount += $subtotal;

                $orderItemsData[] = [
                    'listing' => $listing,
                    'quantity' => $quantity,
                    'size' => $size,
                    'price' => $price,
                    'subtotal' => $subtotal,
                ];
            }

            // Calculate Discount
            $discountAmount = 0;
            $discountCodeId = null;

            if (!empty($validated['discount_code'])) {
                $discountCode = DiscountCode::where('code', $validated['discount_code'])
                    ->active()
                    ->valid()
                    ->first();

                if ($discountCode && $discountCode->canBeUsedBy($user, $departmentId)) {
                    $discountAmount = $discountCode->calculateDiscount($totalOriginalAmount);
                    $discountCodeId = $discountCode->id;
                }
            }

            $finalTotalAmount = $totalOriginalAmount - $discountAmount;
            $reservationFeeAmount = $finalTotalAmount * 0.35;

            // Create Order
            $order = Order::create([
                'order_number' => Order::generateOrderNumber(),
                'user_id' => $user->id,
                'email' => $validated['email'],
                'department_id' => $departmentId,
                'total_amount' => $finalTotalAmount,
                'original_amount' => $totalOriginalAmount,
                'discount_code_id' => $discountCodeId,
                'discount_amount' => $discountAmount,
                'reservation_fee_amount' => $reservationFeeAmount,
                'reservation_fee_paid' => false,
                'status' => 'pending',
                'notes' => $validated['notes'] ?? null,
                'payment_method' => 'cash_on_pickup',
            ]);

            // Create Order Items and Update Stock
            foreach ($orderItemsData as $item) {
                $order->items()->create([
                    'listing_id' => $item['listing']->id,
                    'quantity' => $item['quantity'],
                    'size' => $item['size'],
                    'price' => $item['price'],
                    'subtotal' => $item['subtotal'],
                ]);

                // Update Stock
                $listing = $item['listing'];
                if ($item['size'] && $listing->sizeVariants->isNotEmpty()) {
                    $sizeVariant = $listing->sizeVariants->where('size', $item['size'])->first();
                    if ($sizeVariant->stock_quantity > 0) {
                        $sizeVariant->decrement('stock_quantity', $item['quantity']);
                    }
                } else {
                    if ($listing->stock_quantity > 0) {
                        $listing->decrement('stock_quantity', $item['quantity']);
                    }
                }
            }

            if ($discountCodeId) {
                DiscountCode::where('id', $discountCodeId)->increment('usage_count');
            }

            $this->sendOrderConfirmationEmail($order, $validated['email']);
            $this->notificationService->notifyOrderCreated($order);

            return response()->json([
                'message' => 'Order created successfully',
                'order' => $order->load(['items.listing', 'department']),
            ], 201);

        } catch (\Exception $e) {
            Log::error('Order creation error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error creating order: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get user's orders
     */
    public function index(Request $request)
    {
        $user = $request->user();

        $orders = Order::with(['items.listing.images', 'listing.images', 'department'])
            ->where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json(['orders' => $orders]);
    }

    /**
     * Get order details
     */
    public function show(Request $request, $id)
    {
        $user = $request->user();

        $order = Order::with(['items.listing.images', 'listing.images', 'department'])
            ->where('user_id', $user->id)
            ->findOrFail($id);

        return response()->json(['order' => $order]);
    }

    /**
     * Cancel order
     */
    public function cancel(Request $request, $id)
    {
        $user = $request->user();

        $order = Order::with(['items.listing.sizeVariants', 'listing.sizeVariants', 'listing.images'])->where('user_id', $user->id)->findOrFail($id);

        if (!$order->canBeCancelled()) {
            return response()->json([
                'message' => 'Order cannot be cancelled at this stage'
            ], 400);
        }

        // Update order status
        $order->update(['status' => 'cancelled']);

        // Restore stock quantity
        if ($order->items && $order->items->count() > 0) {
            foreach ($order->items as $item) {
                if ($item->size && $item->listing->sizeVariants->isNotEmpty()) {
                    $sizeVariant = $item->listing->sizeVariants->where('size', $item->size)->first();
                    if ($sizeVariant) {
                        $sizeVariant->increment('stock_quantity', $item->quantity);
                    }
                } else {
                    $item->listing->increment('stock_quantity', $item->quantity);
                }
            }
        } elseif ($order->listing) {
            // Legacy support
            if ($order->size && $order->listing->sizeVariants->isNotEmpty()) {
                // Restore size-specific stock
                $sizeVariant = $order->listing->sizeVariants->where('size', $order->size)->first();
                if ($sizeVariant) {
                    $sizeVariant->increment('stock_quantity', $order->quantity);
                }
            } else {
                // Restore regular stock
                $order->listing->increment('stock_quantity', $order->quantity);
            }
        }

        // Send cancellation email
        $this->sendOrderCancellationEmail($order);

        return response()->json([
            'message' => 'Order cancelled successfully',
            'order' => $order->load(['items.listing', 'listing', 'department']),
        ]);
    }

    /**
     * Admin: Get all orders
     */
    public function adminIndex(Request $request)
    {
        $user = $request->user();

        $query = Order::with(['items.listing', 'listing.images', 'department', 'user']);

        // If admin (not superadmin), only show their department's orders
        if ($user->isAdmin() && !$user->isSuperAdmin()) {
            $query->where('department_id', $user->department_id);
        }

        $orders = $query->orderBy('created_at', 'desc')->get();

        return response()->json(['orders' => $orders]);
    }

    /**
     * Admin: Update order status
     */
    public function updateStatus(Request $request, $id)
    {
        $user = $request->user();

        $validated = $request->validate([
            'status' => 'required|in:pending,confirmed,ready_for_pickup,completed,cancelled',
            'pickup_date' => 'nullable|date',
            'notes' => 'nullable|string',
        ]);

        $query = Order::with(['items.listing', 'listing.images', 'department', 'user']);

        // If admin (not superadmin), only update their department's orders
        if ($user->isAdmin() && !$user->isSuperAdmin()) {
            $query->where('department_id', $user->department_id);
        }

        $order = $query->findOrFail($id);

        $oldStatus = $order->status;
        $order->update($validated);

        // Send email notifications for status changes
        if ($validated['status'] === 'ready_for_pickup' && $oldStatus !== 'ready_for_pickup') {
            $this->sendPickupReadyEmail($order);
        } elseif ($validated['status'] === 'confirmed' && $oldStatus !== 'confirmed') {
            $this->sendOrderConfirmedEmail($order);
        }

        // Send notification for status change
        if ($oldStatus !== $validated['status']) {
            $this->notificationService->notifyOrderStatusChanged($order, $oldStatus, $validated['status']);
        }

        return response()->json([
            'message' => 'Order status updated successfully',
            'order' => $order->load(['items.listing', 'listing', 'department', 'user']),
        ]);
    }

    /**
     * Apply discount code to an existing order
     */
    public function applyDiscount(Request $request, $id)
    {
        $user = $request->user();
        $request->validate([
            'discount_code' => 'required|string',
        ]);

        $order = Order::with(['items', 'department'])->where('user_id', $user->id)->findOrFail($id);

        if ($order->status !== 'pending' || $order->reservation_fee_paid) {
            return response()->json(['message' => 'Cannot apply discount to this order'], 400);
        }

        if ($order->discount_code_id) {
            return response()->json(['message' => 'A discount is already applied'], 400);
        }

        $code = strtoupper($request->discount_code);
        $discountCode = DiscountCode::where('code', $code)
            ->active()
            ->valid()
            ->first();

        if (!$discountCode) {
            return response()->json(['message' => 'Invalid or expired discount code'], 400);
        }

        if (!$discountCode->canBeUsedBy($user, $order->department_id)) {
            return response()->json(['message' => 'Discount code cannot be used for this order'], 400);
        }

        // Calculate discount based on original amount
        // Note: original_amount should be the sum of items subtotal before any previous discounts (which we just checked are null)
        $discountAmount = $discountCode->calculateDiscount($order->original_amount);

        // Ensure discount doesn't exceed total
        if ($discountAmount > $order->original_amount) {
            $discountAmount = $order->original_amount;
        }

        $newTotal = $order->original_amount - $discountAmount;
        $newReservationFee = $newTotal * 0.35;

        $order->update([
            'discount_code_id' => $discountCode->id,
            'discount_amount' => $discountAmount,
            'total_amount' => $newTotal,
            'reservation_fee_amount' => $newReservationFee,
        ]);

        $discountCode->increment('usage_count');

        return response()->json([
            'success' => true,
            'message' => 'Discount applied successfully',
            'order' => $order->fresh(['items.listing', 'department']),
        ]);
    }

    /**
     * Send order confirmation email
     */
    private function sendOrderConfirmationEmail($order, $email)
    {
        try {
            $data = [
                'order' => $order,
                'user' => $order->user,
                'listing' => $order->listing,
                'department' => $order->department,
            ];

            Mail::send('emails.order-confirmation', $data, function ($message) use ($order, $email) {
                $message->to($email)
                    ->subject('Order Confirmation - ' . $order->order_number);
            });

            $order->update(['email_sent' => true]);
        } catch (\Exception $e) {
            Log::error('Failed to send order confirmation email: ' . $e->getMessage());
        }
    }

    /**
     * Send pickup ready email
     */
    private function sendPickupReadyEmail($order)
    {
        try {
            // Use the email saved in the order (the one used during order creation)
            $emailToUse = $order->email ?? $order->user->email;

            Log::info('Attempting to send pickup ready email for order: ' . $order->order_number);
            Log::info('Order email: ' . $emailToUse);

            $data = [
                'order' => $order,
                'user' => $order->user,
                'listing' => $order->listing,
                'department' => $order->department,
            ];

            Log::info('Email data prepared: ' . json_encode($data));

            Mail::send('emails.pickup-ready', $data, function ($message) use ($order, $emailToUse) {
                $message->to($emailToUse)
                    ->subject('Your Order is Ready for Pickup - ' . $order->order_number);
            });

            Log::info('Pickup ready email sent successfully for order: ' . $order->order_number . ' to: ' . $emailToUse);
        } catch (\Exception $e) {
            Log::error('Failed to send pickup ready email: ' . $e->getMessage());
            Log::error('Stack trace: ' . $e->getTraceAsString());
        }
    }

    /**
     * Send order confirmed email
     */
    private function sendOrderConfirmedEmail($order)
    {
        try {
            // Use the email saved in the order (the one used during order creation)
            $emailToUse = $order->email ?? $order->user->email;

            $data = [
                'order' => $order,
                'user' => $order->user,
                'listing' => $order->listing,
                'department' => $order->department,
            ];

            Mail::send('emails.order-confirmed', $data, function ($message) use ($order, $emailToUse) {
                $message->to($emailToUse)
                    ->subject('Order Confirmed - ' . $order->order_number);
            });
        } catch (\Exception $e) {
            Log::error('Failed to send order confirmed email: ' . $e->getMessage());
        }
    }

    /**
     * Send order cancellation email
     */
    private function sendOrderCancellationEmail($order)
    {
        try {
            // Use the email saved in the order (the one used during order creation)
            $emailToUse = $order->email ?? $order->user->email;

            $data = [
                'order' => $order,
                'user' => $order->user,
                'listing' => $order->listing,
                'department' => $order->department,
            ];

            Mail::send('emails.order-cancelled', $data, function ($message) use ($order, $emailToUse) {
                $message->to($emailToUse)
                    ->subject('Order Cancelled - ' . $order->order_number);
            });
        } catch (\Exception $e) {
            Log::error('Failed to send order cancellation email: ' . $e->getMessage());
        }
    }





    /**
     * Upload payment receipt for reservation fee
     */
    public function uploadReceipt(Request $request, $id)
    {
        try {
            $user = $request->user();

            $order = Order::where('user_id', $user->id)->findOrFail($id);

            if ($order->reservation_fee_paid) {
                return response()->json([
                    'message' => 'Reservation fee already paid for this order'
                ], 400);
            }

            $validated = $request->validate([
                'receipt' => 'required|image|mimes:jpeg,png,jpg,gif|max:2048',
            ]);

            // Store the receipt image
            $receiptPath = $request->file('receipt')->store('receipts', 'public');

            // Update order with receipt path
            $order->update([
                'payment_receipt_path' => $receiptPath,
            ]);

            // Send notification to admin/superadmin about new receipt
            $this->notificationService->notifyReceiptUploaded($order);

            return response()->json([
                'message' => 'Receipt uploaded successfully',
                'order' => $order->load(['listing', 'department']),
            ]);
        } catch (\Exception $e) {
            Log::error('Receipt upload error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error uploading receipt: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Admin: Confirm reservation fee payment
     */
    public function confirmReservationFee(Request $request, $id)
    {
        try {
            $user = $request->user();

            $query = Order::with(['listing.images', 'department', 'user']);

            // If admin (not superadmin), only update their department's orders
            if ($user->isAdmin() && !$user->isSuperAdmin()) {
                $query->where('department_id', $user->department_id);
            }

            $order = $query->findOrFail($id);

            if ($order->reservation_fee_paid) {
                return response()->json([
                    'message' => 'Reservation fee already confirmed for this order'
                ], 400);
            }

            if (!$order->payment_receipt_path) {
                return response()->json([
                    'message' => 'No receipt uploaded for this order'
                ], 400);
            }

            // Update order to mark reservation fee as paid and confirm order
            $order->update([
                'reservation_fee_paid' => true,
                'status' => 'confirmed',
            ]);

            // Send confirmation email
            $this->sendOrderConfirmedEmail($order);

            // Send notification to user about order confirmation
            $this->notificationService->notifyOrderStatusChanged($order, 'pending', 'confirmed');

            return response()->json([
                'message' => 'Reservation fee confirmed and order confirmed successfully',
                'order' => $order->load(['listing', 'department', 'user']),
            ]);
        } catch (\Exception $e) {
            Log::error('Reservation fee confirmation error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error confirming reservation fee: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Rate an order
     */
    public function rateOrder(Request $request, $id)
    {
        try {
            $user = $request->user();

            // Find the order and ensure it belongs to the user
            $order = Order::where('user_id', $user->id)
                ->where('id', $id)
                ->where('status', 'completed')
                ->firstOrFail();

            $validated = $request->validate([
                'rating' => 'required|integer|min:1|max:5',
                'review' => 'nullable|string|max:500',
            ]);

            // Update order with rating and review
            $order->update([
                'rating' => $validated['rating'],
                'review' => $validated['review'] ?? null,
            ]);

            return response()->json([
                'message' => 'Rating submitted successfully',
                'order' => $order->load(['listing', 'department']),
            ]);
        } catch (\Exception $e) {
            Log::error('Order rating error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error submitting rating: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Get sales report data
     */
    public function getSalesReport(Request $request)
    {
        try {
            $user = $request->user();

            // Only allow superadmin to access sales report
            if ($user->role !== 'superadmin') {
                return response()->json(['message' => 'Unauthorized'], 403);
            }

            $department = $request->query('department');
            $dateRange = $request->query('dateRange');
            $startDate = $request->query('startDate');
            $endDate = $request->query('endDate');

            // Build the query
            $query = Order::with(['listing', 'department'])
                ->where('status', 'completed');

            // Filter by department if specified
            if ($department && $department !== 'all') {
                $query->where('department_id', $department);
            }

            // Apply date filters
            if ($dateRange === 'weekly') {
                $query->where('created_at', '>=', now()->subWeek());
            } elseif ($dateRange === 'monthly') {
                $query->where('created_at', '>=', now()->subMonth());
            } elseif ($dateRange === 'custom' && $startDate && $endDate) {
                $query->whereBetween('created_at', [$startDate, $endDate]);
            }
            // If dateRange is 'all' or null, don't apply any date filter

            $orders = $query->get();

            // Calculate summary statistics
            $totalSales = $orders->sum('total_amount');
            $totalOrders = $orders->count();
            $averageOrder = $totalOrders > 0 ? $totalSales / $totalOrders : 0;

            // Group by department for department breakdown
            $departmentBreakdown = $orders->groupBy('department_id')->map(function ($departmentOrders) {
                return [
                    'department_name' => $departmentOrders->first()->department->name ?? 'Unknown',
                    'total_sales' => $departmentOrders->sum('total_amount'),
                    'total_orders' => $departmentOrders->count(),
                    'average_order' => $departmentOrders->count() > 0 ? $departmentOrders->sum('total_amount') / $departmentOrders->count() : 0,
                ];
            })->values();

            // Group by date for trend analysis
            $dailySales = $orders->groupBy(function ($order) {
                return $order->created_at->format('Y-m-d');
            })->map(function ($dayOrders, $date) {
                return [
                    'date' => $date,
                    'total_sales' => $dayOrders->sum('total_amount'),
                    'total_orders' => $dayOrders->count(),
                ];
            })->values();

            return response()->json([
                'summary' => [
                    'total_sales' => $totalSales,
                    'total_orders' => $totalOrders,
                    'average_order' => round($averageOrder, 2),
                ],
                'department_breakdown' => $departmentBreakdown,
                'daily_sales' => $dailySales,
                'orders' => $orders->map(function ($order) {
                    return [
                        'id' => $order->id,
                        'order_number' => $order->order_number,
                        'total_amount' => $order->total_amount,
                        'quantity' => $order->quantity,
                        'created_at' => $order->created_at,
                        'department' => $order->department->name ?? 'Unknown',
                        'listing_title' => $order->listing->title ?? 'Unknown',
                    ];
                }),
            ]);
        } catch (\Exception $e) {
            Log::error('Sales report error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error generating sales report: ' . $e->getMessage()
            ], 500);
        }
    }


}