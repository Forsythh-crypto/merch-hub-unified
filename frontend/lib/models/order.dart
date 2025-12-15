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
  final double? reservationFeeAmount;
  final bool reservationFeePaid;
  final String? paymentReceiptPath;
  final String status;
  final DateTime? pickupDate;
  final String? notes;
  final String paymentMethod;
  final bool emailSent;
  final String? email;
  final int? rating; // 1-5 stars
  final String? review; // User review text
  final DateTime createdAt;
  final DateTime updatedAt;

  // New fields for discounts
  final int? discountCodeId;
  final double? discountAmount;
  final double? originalAmount;

  // Related objects
  final Listing? listing;
  final Department? department;
  final UserSession? user;
  final List<OrderItem> items; // Moved here for clarity
  
  Order({
    required this.id,
    required this.orderNumber,
    this.userId,
    // Legacy fields - nullable now
    this.listingId = 0, 
    required this.departmentId,
    this.quantity = 0,
    this.size,
    required this.totalAmount,
    this.reservationFeeAmount,
    required this.reservationFeePaid,
    this.paymentReceiptPath,
    required this.status,
    this.pickupDate,
    this.notes,
    required this.paymentMethod,
    required this.emailSent,
    this.email,
    this.rating,
    this.review,
    required this.createdAt,
    required this.updatedAt,
    this.listing,
    this.department,
    this.user,
    this.items = const [],
    this.discountCodeId,
    this.discountAmount,
    this.originalAmount,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      orderNumber: json['order_number'],
      userId: json['user_id'],
      listingId: json['listing_id'] ?? 0, 
      departmentId: json['department_id'],
      quantity: json['quantity'] ?? 0, 
      size: json['size'],
      totalAmount: double.parse(json['total_amount'].toString()),
      reservationFeeAmount: json['reservation_fee_amount'] != null
          ? double.parse(json['reservation_fee_amount'].toString())
          : null,
      reservationFeePaid: json['reservation_fee_paid'] ?? false,
      paymentReceiptPath: json['payment_receipt_path'],
      status: json['status'],
      pickupDate: json['pickup_date'] != null
          ? DateTime.parse(json['pickup_date'])
          : null,
      notes: json['notes'],
      paymentMethod: json['payment_method'],
      emailSent: json['email_sent'] ?? false,
      email: json['email'],
      rating: json['rating'],
      review: json['review'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      listing: json['listing'] != null
          ? Listing.fromJson(json['listing'])
          : null,
      department: json['department'] != null
          ? Department.fromJson(json['department'])
          : null,
      user: json['user'] != null ? UserSession.fromJson(json['user']) : null,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList()
          : [],
      discountCodeId: json['discount_code_id'],
      discountAmount: json['discount_amount'] != null 
          ? double.parse(json['discount_amount'].toString()) 
          : null,
      originalAmount: json['original_amount'] != null 
          ? double.parse(json['original_amount'].toString()) 
          : null,
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
      'reservation_fee_amount': reservationFeeAmount,
      'reservation_fee_paid': reservationFeePaid,
      'payment_receipt_path': paymentReceiptPath,
      'status': status,
      'pickup_date': pickupDate?.toIso8601String(),
      'notes': notes,
      'payment_method': paymentMethod,
      'email_sent': emailSent,
      'email': email,
      'rating': rating,
      'review': review,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'discount_code_id': discountCodeId,
      'discount_amount': discountAmount,
      'original_amount': originalAmount,
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

  // Check if reservation fee is paid
  bool get hasPaidReservationFee {
    return reservationFeePaid;
  }

  // Get reservation fee amount (35% of total)
  double get calculatedReservationFeeAmount {
    return totalAmount * 0.35;
  }

  // Check if order can be confirmed (reservation fee must be paid)
  bool get canBeConfirmed {
    return hasPaidReservationFee && status == 'pending';
  }

  // Check if order needs reservation fee payment
  bool get needsReservationFeePayment {
    return !reservationFeePaid && status == 'pending';
  }



}

class OrderItem {
  final int id;
  final int orderId;
  final int listingId;
  final int quantity; // Make sure this is int
  final String? size;
  final double price;
  final double subtotal;
  final Listing? listing;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.listingId,
    required this.quantity,
    this.size,
    required this.price,
    required this.subtotal,
    this.listing,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is int) return value.toDouble();
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      listingId: json['listing_id'],
      quantity: json['quantity'] ?? 1,
      size: json['size'],
      price: parseDouble(json['price']),
      subtotal: parseDouble(json['subtotal']),
      listing: json['listing'] != null ? Listing.fromJson(json['listing']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'listing_id': listingId,
      'quantity': quantity,
      'size': size,
      'price': price,
      'subtotal': subtotal,
      'listing': listing?.toJson(),
    };
  }
}
