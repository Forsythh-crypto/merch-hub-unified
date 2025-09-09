<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\Listing;
use App\Models\User;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Facades\Log;

class OrderController extends Controller
{
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
            ]);

        // Get the listing with size variants
        $listing = Listing::with('sizeVariants')->findOrFail($validated['listing_id']);

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

        // Calculate total amount
        $totalAmount = $listing->price * $validated['quantity'];

        // Create order
        $order = Order::create([
            'order_number' => Order::generateOrderNumber(),
            'user_id' => $user->id,
            'email' => $validated['email'], // Save the email used in order
            'listing_id' => $validated['listing_id'],
            'department_id' => $listing->department_id,
            'quantity' => $validated['quantity'],
            'total_amount' => $totalAmount,
            'status' => 'pending',
            'notes' => $validated['notes'] ?? null,
            'payment_method' => 'cash_on_pickup',
            'size' => $validated['size'] ?? null,
        ]);

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
        
        $orders = Order::with(['listing', 'department'])
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
        
        $order = Order::with(['listing', 'department'])
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
        
        $order = Order::with('listing.sizeVariants')->where('user_id', $user->id)->findOrFail($id);

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
        
        $query = Order::with(['listing', 'department', 'user']);

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

        $query = Order::with(['listing', 'department', 'user']);
        
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
     * Get simple orders by email (no authentication required)
     */
    public function simpleIndex(Request $request)
    {
        try {
            $validated = $request->validate([
                'email' => 'required|email',
            ]);

            $orders = Order::with(['listing', 'department'])
                ->where('user_id', null) // Simple orders have null user_id
                ->where('email', $validated['email'])
                ->orderBy('created_at', 'desc')
                ->get();

            return response()->json(['orders' => $orders]);
        } catch (\Exception $e) {
            Log::error('Simple orders fetch error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error fetching orders: ' . $e->getMessage()
            ], 500);
        }
    }

    /**
     * Send simple order confirmation email
     */
    private function sendSimpleOrderConfirmationEmail($order, $email, $customerName)
    {
        try {
            $data = [
                'order' => $order,
                'customer_name' => $customerName,
                'listing' => $order->listing,
                'department' => $order->department,
            ];

            Mail::send('emails.simple-order-confirmation', $data, function ($message) use ($order, $email) {
                $message->to($email)
                    ->subject('Order Confirmation - ' . $order->order_number);
            });

            $order->update(['email_sent' => true]);
        } catch (\Exception $e) {
            Log::error('Failed to send simple order confirmation email: ' . $e->getMessage());
        }
    }

    /**
     * Simple order creation without authentication (for testing)
     */
    public function simpleStore(Request $request)
    {
        try {
            $validated = $request->validate([
                'listing_id' => 'required|exists:listings,id',
                'quantity' => 'required|integer|min:1',
                'email' => 'required|email',
                'notes' => 'nullable|string|max:500',
                'size' => 'nullable|string|max:10',
                'customer_name' => 'required|string|max:255',
            ]);

            // Get the listing with size variants
            $listing = Listing::with('sizeVariants')->findOrFail($validated['listing_id']);

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

            // Calculate total amount
            $totalAmount = $listing->price * $validated['quantity'];

            // Create order (without user_id for simple orders)
            $order = Order::create([
                'order_number' => Order::generateOrderNumber(),
                'user_id' => null, // No user for simple orders
                'listing_id' => $validated['listing_id'],
                'department_id' => $listing->department_id,
                'quantity' => $validated['quantity'],
                'total_amount' => $totalAmount,
                'status' => 'pending',
                'notes' => $validated['notes'] ?? null,
                'payment_method' => 'cash_on_pickup',
                'size' => $validated['size'] ?? null,
            ]);

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

            // Send confirmation email
            $this->sendSimpleOrderConfirmationEmail($order, $validated['email'], $validated['customer_name']);

            return response()->json([
                'message' => 'Order created successfully',
                'order' => $order->load(['listing', 'department']),
                'order_number' => $order->order_number,
            ], 201);
        } catch (\Exception $e) {
            Log::error('Simple order creation error: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error creating order: ' . $e->getMessage()
            ], 500);
        }
    }
}
