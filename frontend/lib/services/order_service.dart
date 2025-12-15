import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/order.dart';

class OrderService {
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

  // Create a new order
  static Future<Map<String, dynamic>> createOrder({
    required List<Map<String, dynamic>> items, // [{listing_id, quantity, size}]
    required String email,
    String? notes,
    String? discountCode,
  }) async {
    try {
      final headers = await _getHeaders();
      final requestBody = {
        'items': items,
        'email': email,
        'notes': notes,
      };

      // Add discount code if provided
      if (discountCode != null) {
        requestBody['discount_code'] = discountCode;
      }

      // Use authenticated orders endpoint
      final response = await http.post(
        AppConfig.api('orders'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'order': Order.fromJson(data['order']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create order',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Get user's orders
  static Future<List<Order>> getUserOrders() async {
    try {
      final headers = await _getHeaders();

      final response = await http.get(
        AppConfig.api('orders'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orders = (data['orders'] as List)
            .map((order) => Order.fromJson(order))
            .toList();
        return orders;
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get order details
  static Future<Order> getOrderDetails(int orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        AppConfig.api('orders/$orderId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Order.fromJson(data['order']);
      } else {
        throw Exception('Failed to load order details');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Cancel order
  static Future<Map<String, dynamic>> cancelOrder(int orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        AppConfig.api('orders/$orderId/cancel'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'order': Order.fromJson(data['order']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to cancel order',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Admin: Get all orders
  static Future<List<Order>> getAdminOrders() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        AppConfig.api('admin/orders'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['orders'] as List)
            .map((order) => Order.fromJson(order))
            .toList();
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Admin: Update order status
  static Future<Map<String, dynamic>> updateOrderStatus({
    required int orderId,
    required String status,
    DateTime? pickupDate,
    String? notes,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'status': status,
        if (pickupDate != null) 'pickup_date': pickupDate.toIso8601String(),
        if (notes != null) 'notes': notes,
      };

      final response = await http.put(
        AppConfig.api('admin/orders/$orderId/status'),
        headers: headers,
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'order': Order.fromJson(data['order']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update order status',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Upload payment receipt
  static Future<Map<String, dynamic>> uploadReceipt({
    required int orderId,
    required File receiptFile,
  }) async {
    try {
      final token = await _getToken();
      final uri = AppConfig.api('orders/$orderId/upload-receipt');
      
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add the receipt file
      request.files.add(
        await http.MultipartFile.fromPath(
          'receipt',
          receiptFile.path,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'order': Order.fromJson(data['order']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to upload receipt',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Validate discount code
  static Future<Map<String, dynamic>> validateDiscountCode({
    required String code,
    required double orderAmount,
    required int departmentId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        AppConfig.api('discount-codes/validate'),
        headers: headers,
        body: jsonEncode({
          'code': code,
          'order_amount': orderAmount,
          'department_id': departmentId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'valid': data['valid'],
          'discount_code': data['discount_code'],
          'discount_amount': double.tryParse(data['discount_amount'].toString()) ?? 0.0,
          'final_amount': double.tryParse(data['final_amount'].toString()) ?? 0.0,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'valid': false,
          'message': data['message'] ?? 'Failed to validate discount code',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'valid': false,
        'message': 'Network error: $e'
      };
    }
  }

  // Admin: Confirm reservation fee payment
  static Future<Map<String, dynamic>> confirmReservationFee(int orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        AppConfig.api('admin/orders/$orderId/confirm-reservation-fee'),
        headers: headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'order': Order.fromJson(data['order']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to confirm reservation fee',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  // Rate an order
  static Future<void> rateOrder(int orderId, int rating, String review) async {
    final token = await _getToken(); // Changed from AuthService.getToken() to _getToken() for consistency
    final response = await http.post(
      AppConfig.api('orders/$orderId/rate'), // Changed from Uri.parse('${AppConfig.apiBaseUrl}/orders/$orderId/rate') to AppConfig.api() for consistency
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'rating': rating,
        'review': review,
      }),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Failed to rate order'); // Wrapped in Exception for consistency
    }
  }

  static Future<Map<String, dynamic>> applyDiscount(int orderId, String code) async {
    try { // Added try-catch block for consistency
      final token = await _getToken(); // Changed from AuthService.getToken() to _getToken() for consistency
      final response = await http.post(
        AppConfig.api('orders/$orderId/apply-discount'), // Changed from Uri.parse('${AppConfig.apiBaseUrl}/orders/$orderId/apply-discount') to AppConfig.api() for consistency
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'discount_code': code}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'order': Order.fromJson(data['order']),
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to apply discount',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'}; // Added network error handling for consistency
    }
  }
}
