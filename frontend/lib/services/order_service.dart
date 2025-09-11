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
    print('🔑 Order service token: ${token?.substring(0, 20)}...');
    print('🔑 Order service token length: ${token?.length}');
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Create a new order
  static Future<Map<String, dynamic>> createOrder({
    required int listingId,
    required int quantity,
    required String email,
    String? notes,
    String? size,
  }) async {
    try {
      final headers = await _getHeaders();
      print('Creating order with headers: $headers');
      final requestBody = {
        'listing_id': listingId,
        'quantity': quantity,
        'email': email,
        'notes': notes,
      };

      // Add size if provided
      if (size != null) {
        requestBody['size'] = size;
      }

      print('Request body: ${jsonEncode(requestBody)}');

      // Use authenticated orders endpoint
      final response = await http.post(
        AppConfig.api('orders'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
      print('🔍 Getting user orders with headers: $headers');
      print('🔍 API URL: ${AppConfig.api('orders')}');

      final response = await http.get(
        AppConfig.api('orders'),
        headers: headers,
      );

      print('🔍 Orders response status: ${response.statusCode}');
      print('🔍 Orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orders = (data['orders'] as List)
            .map((order) => Order.fromJson(order))
            .toList();
        print('✅ Successfully loaded ${orders.length} orders');
        return orders;
      } else {
        print('❌ Failed to load orders: ${response.statusCode}');
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      print('❌ Error getting user orders: $e');
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

      print('📤 Uploading receipt for order $orderId');
      print('📤 File path: ${receiptFile.path}');
      print('📤 URI: $uri');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📤 Upload response status: ${response.statusCode}');
      print('📤 Upload response body: ${response.body}');

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
      print('❌ Error uploading receipt: $e');
      return {'success': false, 'message': 'Network error: $e'};
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
}
