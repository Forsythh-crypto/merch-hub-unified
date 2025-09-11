<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Services\NotificationService;
use App\Models\Notification;
use Illuminate\Support\Facades\Log;

class NotificationController extends Controller
{
    protected $notificationService;

    public function __construct(NotificationService $notificationService)
    {
        $this->notificationService = $notificationService;
    }

    /**
     * Get user's notifications
     */
    public function index(Request $request)
    {
        try {
            $user = $request->user();
            $limit = $request->get('limit', 50);
            
            $notifications = $this->notificationService->getUserNotifications($user, $limit);

            return response()->json([
                'notifications' => $notifications,
                'unread_count' => $this->notificationService->getUnreadCount($user)
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch notifications: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error fetching notifications'
            ], 500);
        }
    }

    /**
     * Get unread notification count
     */
    public function unreadCount(Request $request)
    {
        try {
            $user = $request->user();
            $count = $this->notificationService->getUnreadCount($user);

            return response()->json(['unread_count' => $count]);
        } catch (\Exception $e) {
            Log::error('Failed to fetch unread count: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error fetching unread count'
            ], 500);
        }
    }

    /**
     * Mark notifications as read
     */
    public function markAsRead(Request $request)
    {
        try {
            $user = $request->user();
            $notificationIds = $request->get('notification_ids', []);

            $updated = $this->notificationService->markAsRead($user, $notificationIds);

            return response()->json([
                'message' => 'Notifications marked as read',
                'updated_count' => $updated
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to mark notifications as read: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error marking notifications as read'
            ], 500);
        }
    }

    /**
     * Mark specific notification as read
     */
    public function markAsReadSingle(Request $request, $id)
    {
        try {
            $user = $request->user();
            
            $notification = Notification::where('user_id', $user->id)
                ->findOrFail($id);

            $notification->markAsRead();

            return response()->json([
                'message' => 'Notification marked as read',
                'notification' => $notification
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to mark notification as read: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error marking notification as read'
            ], 500);
        }
    }

    /**
     * Delete notification
     */
    public function destroy(Request $request, $id)
    {
        try {
            $user = $request->user();
            
            $notification = Notification::where('user_id', $user->id)
                ->findOrFail($id);

            $notification->delete();

            return response()->json([
                'message' => 'Notification deleted successfully'
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to delete notification: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error deleting notification'
            ], 500);
        }
    }

    /**
     * Clear all notifications for user
     */
    public function clearAll(Request $request)
    {
        try {
            $user = $request->user();
            
            $deleted = Notification::where('user_id', $user->id)->delete();

            return response()->json([
                'message' => 'All notifications cleared',
                'deleted_count' => $deleted
            ]);
        } catch (\Exception $e) {
            Log::error('Failed to clear notifications: ' . $e->getMessage());
            return response()->json([
                'message' => 'Error clearing notifications'
            ], 500);
        }
    }
}