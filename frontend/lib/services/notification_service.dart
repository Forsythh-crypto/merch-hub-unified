import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/notification.dart' as app_models;

class NotificationService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Get user's notifications
  static Future<Map<String, dynamic>> getNotifications({int limit = 50}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        AppConfig.api('notifications?limit=$limit'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notifications = (data['notifications'] as List)
            .map((notification) => app_models.Notification.fromJson(notification))
            .toList();
        
        return {
          'success': true,
          'notifications': notifications,
          'unread_count': data['unread_count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load notifications',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get unread notification count
  static Future<int> getUnreadCount() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        AppConfig.api('notifications/unread-count'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unread_count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      // Silently handle error
      return 0;
    }
  }

  // Mark notifications as read
  static Future<Map<String, dynamic>> markAsRead({List<int>? notificationIds}) async {
    try {
      final headers = await _getHeaders();
      final body = <String, dynamic>{};
      
      if (notificationIds != null && notificationIds.isNotEmpty) {
        body['notification_ids'] = notificationIds;
      }

      final response = await http.post(
        AppConfig.api('notifications/mark-read'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'updated_count': data['updated_count'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to mark notifications as read',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Mark specific notification as read
  static Future<Map<String, dynamic>> markAsReadSingle(int notificationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        AppConfig.api('notifications/$notificationId/mark-read'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'notification': app_models.Notification.fromJson(data['notification']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to mark notification as read',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Delete notification
  static Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        AppConfig.api('notifications/$notificationId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete notification',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Clear all notifications
  static Future<Map<String, dynamic>> clearAll() async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        AppConfig.api('notifications'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'deleted_count': data['deleted_count'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to clear notifications',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }
}
