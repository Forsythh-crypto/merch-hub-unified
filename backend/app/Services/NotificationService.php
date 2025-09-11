<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\User;
use App\Models\Order;
use App\Models\Department;
use Illuminate\Support\Facades\Log;

class NotificationService
{
    /**
     * Send notification for new order
     */
    public function notifyOrderCreated(Order $order)
    {
        try {
            // Notify superadmins about all orders
            $this->notifySuperAdmins($order, 'New Order Created', 
                "New order #{$order->order_number} has been created by {$order->user->name} for {$order->listing->name}");

            // Notify department admins about orders in their department
            $this->notifyDepartmentAdmins($order, 'New Order in Your Department', 
                "New order #{$order->order_number} has been created in {$order->department->name} department");

            // Notify the user who made the order
            $this->notifyUser($order->user, 'Order Confirmation', 
                "Your order #{$order->order_number} has been successfully created and is pending confirmation");

        } catch (\Exception $e) {
            Log::error('Failed to send order created notifications: ' . $e->getMessage());
        }
    }

    /**
     * Send notification for order status change
     */
    public function notifyOrderStatusChanged(Order $order, string $oldStatus, string $newStatus)
    {
        try {
            $statusMessages = [
                'confirmed' => 'Your order has been confirmed and is being processed',
                'ready_for_pickup' => 'Your order is ready for pickup!',
                'completed' => 'Your order has been completed',
                'cancelled' => 'Your order has been cancelled'
            ];

            $message = $statusMessages[$newStatus] ?? "Your order status has been updated to {$newStatus}";

            // Notify the user about status change
            if ($order->user) {
                $this->notifyUser($order->user, 'Order Status Update', 
                    "Order #{$order->order_number}: {$message}");
            }

            // Notify superadmins about status changes
            $this->notifySuperAdmins($order, 'Order Status Changed', 
                "Order #{$order->order_number} status changed from {$oldStatus} to {$newStatus}");

            // Notify department admins about status changes in their department
            $this->notifyDepartmentAdmins($order, 'Order Status Changed in Your Department', 
                "Order #{$order->order_number} in {$order->department->name} status changed from {$oldStatus} to {$newStatus}");

        } catch (\Exception $e) {
            Log::error('Failed to send order status change notifications: ' . $e->getMessage());
        }
    }

    /**
     * Send notification for receipt upload
     */
    public function notifyReceiptUploaded(Order $order)
    {
        try {
            // Notify superadmins about receipt upload
            $this->notifySuperAdmins($order, 'Payment Receipt Uploaded', 
                "Payment receipt has been uploaded for order #{$order->order_number} by {$order->user->name}");

            // Notify department admins about receipt upload in their department
            $this->notifyDepartmentAdmins($order, 'Payment Receipt Uploaded in Your Department', 
                "Payment receipt has been uploaded for order #{$order->order_number} in {$order->department->name} department");

        } catch (\Exception $e) {
            Log::error('Failed to send receipt uploaded notifications: ' . $e->getMessage());
        }
    }

    /**
     * Send notification for new reservation
     */
    public function notifyReservationCreated($reservation)
    {
        try {
            // Notify superadmins about all reservations
            $this->notifySuperAdmins(null, 'New Reservation Created', 
                "New reservation has been created");

            // Notify department admins about reservations in their department
            if (isset($reservation['department_id'])) {
                $this->notifyDepartmentAdminsById($reservation['department_id'], 'New Reservation in Your Department', 
                    "New reservation has been created in your department");
            }

            // Notify the user who made the reservation
            if (isset($reservation['user_id'])) {
                $user = User::find($reservation['user_id']);
                if ($user) {
                    $this->notifyUser($user, 'Reservation Confirmation', 
                        "Your reservation has been successfully created and is pending confirmation");
                }
            }

        } catch (\Exception $e) {
            Log::error('Failed to send reservation created notifications: ' . $e->getMessage());
        }
    }

    /**
     * Notify all superadmins
     */
    private function notifySuperAdmins($order, string $title, string $message)
    {
        $superAdmins = User::where('role', User::ROLE_SUPERADMIN)->get();
        
        foreach ($superAdmins as $admin) {
            Notification::create([
                'type' => $order ? Notification::TYPE_ORDER_CREATED : Notification::TYPE_RESERVATION_CREATED,
                'title' => $title,
                'message' => $message,
                'user_id' => $admin->id,
                'user_role' => User::ROLE_SUPERADMIN,
                'data' => $order ? [
                    'order_id' => $order->id,
                    'order_number' => $order->order_number,
                    'department_id' => $order->department_id,
                    'user_name' => $order->user->name,
                    'listing_name' => $order->listing->name,
                ] : null,
            ]);
        }
    }

    /**
     * Notify department admins about orders in their department
     */
    private function notifyDepartmentAdmins($order, string $title, string $message)
    {
        $departmentAdmins = User::where('role', User::ROLE_ADMIN)
            ->where('department_id', $order->department_id)
            ->get();
        
        foreach ($departmentAdmins as $admin) {
            Notification::create([
                'type' => Notification::TYPE_ORDER_CREATED,
                'title' => $title,
                'message' => $message,
                'user_id' => $admin->id,
                'user_role' => User::ROLE_ADMIN,
                'department_id' => $order->department_id,
                'data' => [
                    'order_id' => $order->id,
                    'order_number' => $order->order_number,
                    'department_id' => $order->department_id,
                    'user_name' => $order->user->name,
                    'listing_name' => $order->listing->name,
                ],
            ]);
        }
    }

    /**
     * Notify department admins by department ID
     */
    private function notifyDepartmentAdminsById($departmentId, string $title, string $message)
    {
        $departmentAdmins = User::where('role', User::ROLE_ADMIN)
            ->where('department_id', $departmentId)
            ->get();
        
        foreach ($departmentAdmins as $admin) {
            Notification::create([
                'type' => Notification::TYPE_RESERVATION_CREATED,
                'title' => $title,
                'message' => $message,
                'user_id' => $admin->id,
                'user_role' => User::ROLE_ADMIN,
                'department_id' => $departmentId,
            ]);
        }
    }

    /**
     * Notify specific user
     */
    private function notifyUser(User $user, string $title, string $message)
    {
        Notification::create([
            'type' => Notification::TYPE_ORDER_CREATED,
            'title' => $title,
            'message' => $message,
            'user_id' => $user->id,
            'user_role' => $user->role,
        ]);
    }

    /**
     * Get notifications for a user based on their role
     */
    public function getUserNotifications(User $user, int $limit = 50)
    {
        $query = Notification::query();

        if ($user->isSuperAdmin()) {
            // Superadmins see all notifications
            $query->where(function ($q) use ($user) {
                $q->where('user_id', $user->id)
                  ->orWhere('user_role', User::ROLE_SUPERADMIN);
            });
        } elseif ($user->isAdmin()) {
            // Admins see their personal notifications and department notifications
            $query->where(function ($q) use ($user) {
                $q->where('user_id', $user->id)
                  ->orWhere(function ($q2) use ($user) {
                      $q2->where('user_role', User::ROLE_ADMIN)
                         ->where('department_id', $user->department_id);
                  });
            });
        } else {
            // Students only see their personal notifications
            $query->where('user_id', $user->id);
        }

        return $query->orderBy('created_at', 'desc')
                    ->limit($limit)
                    ->get();
    }

    /**
     * Get unread notification count for a user
     */
    public function getUnreadCount(User $user)
    {
        $query = Notification::unread();

        if ($user->isSuperAdmin()) {
            $query->where(function ($q) use ($user) {
                $q->where('user_id', $user->id)
                  ->orWhere('user_role', User::ROLE_SUPERADMIN);
            });
        } elseif ($user->isAdmin()) {
            $query->where(function ($q) use ($user) {
                $q->where('user_id', $user->id)
                  ->orWhere(function ($q2) use ($user) {
                      $q2->where('user_role', User::ROLE_ADMIN)
                         ->where('department_id', $user->department_id);
                  });
            });
        } else {
            $query->where('user_id', $user->id);
        }

        return $query->count();
    }

    /**
     * Mark notifications as read
     */
    public function markAsRead(User $user, array $notificationIds = [])
    {
        $query = Notification::where('user_id', $user->id);

        if (!empty($notificationIds)) {
            $query->whereIn('id', $notificationIds);
        }

        return $query->update([
            'is_read' => true,
            'read_at' => now(),
        ]);
    }
}
