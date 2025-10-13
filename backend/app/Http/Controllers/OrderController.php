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
                'listing_id' => 'required|exists:listings,id',
                'quantity' => 'required|integer|min:1',
                'email' => 'required|email',
                'notes' => 'nullable|string|max:500',
                'size' => 'nullable|string|max:10',
                'discount_code' => 'nullable|string|max:50',
            ]);

        // Get the listing with size variants
        $listing = Listing::with(['sizeVariants', 'images'])->findOrFail($validated['listing_id']);

        // Check stock based on whether it's a size variant or regular stock
        // Allow pre-orders when stock is 0
        if (isset($validated['size']) && $listing->sizeVariants->isNotEmpty()) {
            // Check size-specific stock
            $sizeVariant = $listing->sizeVariants->where('size', $validated['size'])->first();
            if (!$sizeVariant) {
                return response()->json([
                    'message' => 'Selected size not available'
                ], 400);
            }
            
            // Allow pre-orders when stock is 0, but check if trying to order more than available when stock > 0
            if ($sizeVariant->stock_quantity > 0 && $sizeVariant->stock_quantity < $validated['quantity']) {
                return response()->json([
                    'message' => 'Insufficient stock for size ' . $validated['size'] . '. Available: ' . $sizeVariant->stock_quantity
                ], 400);
            }
        } else {
            // Check regular stock - allow pre-orders when stock is 0
            if ($listing->stock_quantity > 0 && $listing->stock_quantity < $validated['quantity']) {
                return response()->json([
                    'message' => 'Insufficient stock. Available: ' . $listing->stock_quantity
                ], 400);
            }
        }

        // Calculate original amount
        $originalAmount = $listing->price * $validated['quantity'];
        $discountAmount = 0;
        $discountCodeId = null;
        
        // Apply discount code if provided
        if (!empty($validated['discount_code'])) {
            $discountCode = DiscountCode::where('code', $validated['discount_code'])
                ->active()
                ->valid()
                ->first();
                
            if ($discountCode && $discountCode->canBeUsedBy($user, $listing->department_id)) {
                $discountAmount = $discountCode->calculateDiscount($originalAmount);
                $discountCodeId = $discountCode->id;
            }
        }
        
        // Calculate final amount after discount
        $totalAmount = $originalAmount - $discountAmount;
        $reservationFeeAmount = $totalAmount * 0.35; // 35% reservation fee

        // Create order
        $order = Order::create([
            'order_number' => Order::generateOrderNumber(),
            'user_id' => $user->id,
            'email' => $validated['email'], // Save the email used in order
            'listing_id' => $validated['listing_id'],
            'department_id' => $listing->department_id,
            'quantity' => $validated['quantity'],
            'total_amount' => $totalAmount,
            'original_amount' => $originalAmount,
            'discount_code_id' => $discountCodeId,
            'discount_amount' => $discountAmount,
            'reservation_fee_amount' => $reservationFeeAmount,
            'reservation_fee_paid' => false,
            'status' => 'pending',
            'notes' => $validated['notes'] ?? null,
            'payment_method' => 'cash_on_pickup',
            'size' => $validated['size'] ?? null,
        ]);
        
        // Increment discount code usage if applied
        if ($discountCodeId) {
            DiscountCode::where('id', $discountCodeId)->increment('usage_count');
        }

        // Update stock quantity - only decrement if stock is available (not for pre-orders)
        if (isset($validated['size']) && $listing->sizeVariants->isNotEmpty()) {
            // Decrement size-specific stock only if available
            $sizeVariant = $listing->sizeVariants->where('size', $validated['size'])->first();
            if ($sizeVariant->stock_quantity > 0) {
                $sizeVariant->decrement('stock_quantity', $validated['quantity']);
            }
        } else {
            // Decrement regular stock only if available
            if ($listing->stock_quantity > 0) {
                $listing->decrement('stock_quantity', $validated['quantity']);
            }
        }

        // Send confirmation email to the provided email address
        $this->sendOrderConfirmationEmail($order, $validated['email']);

        // Send notifications
        $this->notificationService->notifyOrderCreated($order);

        return response()->json([
            'message' => 'Order created successfully',
            'order' => $order->load(['listing', 'department']),
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
        
        $orders = Order::with(['listing.images', 'department'])
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
        
        $order = Order::with(['listing.images', 'department'])
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
        
        $order = Order::with(['listing.sizeVariants', 'listing.images'])->where('user_id', $user->id)->findOrFail($id);

        if (!$order->canBeCancelled()) {
            return response()->json([
                'message' => 'Order cannot be cancelled at this stage'
            ], 400);
        }

        // Update order status
        $order->update(['status' => 'cancelled']);

        // Restore stock quantity
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

        // Send cancellation email
        $this->sendOrderCancellationEmail($order);

        return response()->json([
            'message' => 'Order cancelled successfully',
            'order' => $order->load(['listing', 'department']),
        ]);
    }

    /**
     * Admin: Get all orders
     */
    public function adminIndex(Request $request)
    {
        $user = $request->user();
        
        $query = Order::with(['listing.images', 'department', 'user']);

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

        $query = Order::with(['listing.images', 'department', 'user']);
        
        // If admin (not superadmin), only update their department's orders
        if ($user->isAdmin() && !$user->isSuperAdmin()) {
            $query->where('department_id', $user->department_id);
        }

        $order = $query->findOrFail($id);

        $oldStatus = $order->status;
        // $order->update($validated);

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
            'order' => $order->load(['listing', 'department', 'user']),
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


}
