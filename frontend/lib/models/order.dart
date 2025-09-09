import 'listing.dart';
import 'user_role.dart';

class Order {
  final int id;
  final String orderNumber;
  final int? userId;
  final int listingId;
  final int departmentId;
  final int quantity;
  final String? size;
  final double totalAmount;
  final String status;
  final DateTime? pickupDate;
  final String? notes;
  final String paymentMethod;
  final bool emailSent;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related objects
  final Listing? listing;
  final Department? department;
  final UserSession? user;

  Order({
    required this.id,
    required this.orderNumber,
    this.userId,
    required this.listingId,
    required this.departmentId,
    required this.quantity,
    this.size,
    required this.totalAmount,
    required this.status,
    this.pickupDate,
    this.notes,
    required this.paymentMethod,
    required this.emailSent,
    required this.createdAt,
    required this.updatedAt,
    this.listing,
    this.department,
    this.user,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      userId: json['user_id'],
      listingId: json['listing_id'],
      departmentId: json['department_id'],
      quantity: json['quantity'],
      size: json['size'],
      totalAmount: double.parse(json['total_amount'].toString()),
      status: json['status'],
      pickupDate: json['pickup_date'] != null
          ? DateTime.parse(json['pickup_date'])
          : null,
      notes: json['notes'],
      paymentMethod: json['payment_method'],
      emailSent: json['email_sent'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      listing: json['listing'] != null
          ? Listing.fromJson(json['listing'])
          : null,
      department: json['department'] != null
          ? Department.fromJson(json['department'])
          : null,
      user: json['user'] != null ? UserSession.fromJson(json['user']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'user_id': userId,
      'listing_id': listingId,
      'department_id': departmentId,
      'quantity': quantity,
      'size': size,
      'total_amount': totalAmount,
      'status': status,
      'pickup_date': pickupDate?.toIso8601String(),
      'notes': notes,
      'payment_method': paymentMethod,
      'email_sent': emailSent,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Get status display name
  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'ready_for_pickup':
        return 'Ready for Pickup';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  // Get status color
  int get statusColor {
    switch (status) {
      case 'pending':
        return 0xFFF59E0B; // Orange
      case 'confirmed':
        return 0xFF3B82F6; // Blue
      case 'ready_for_pickup':
        return 0xFF059669; // Green
      case 'completed':
        return 0xFF6B7280; // Gray
      case 'cancelled':
        return 0xFFDC2626; // Red
      default:
        return 0xFF6B7280; // Gray
    }
  }

  // Check if order can be cancelled
  bool get canBeCancelled {
    return status == 'pending' || status == 'confirmed';
  }

  // Check if order is ready for pickup
  bool get isReadyForPickup {
    return status == 'ready_for_pickup';
  }
}
