class Notification {
  final int id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final int? userId;
  final String? userRole;
  final int? departmentId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    this.userId,
    this.userRole,
    this.departmentId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      type: json['type'],
      title: json['title'],
      message: json['message'],
      data: json['data'],
      userId: json['user_id'],
      userRole: json['user_role'],
      departmentId: json['department_id'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'message': message,
      'data': data,
      'user_id': userId,
      'user_role': userRole,
      'department_id': departmentId,
      'is_read': isRead,
      'read_at': readAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Notification types
  static const String typeOrderCreated = 'order_created';
  static const String typeOrderStatusChanged = 'order_status_changed';
  static const String typeReservationCreated = 'reservation_created';

  // Helper methods
  bool get isUnread => !isRead;
  
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String get icon {
    switch (type) {
      case 'order_created':
        return '🛒';
      case 'order_status_changed':
        return '📋';
      case 'reservation_created':
        return '📅';
      default:
        return '🔔';
    }
  }
}
