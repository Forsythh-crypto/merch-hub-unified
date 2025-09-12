import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/listing.dart';
import '../config/app_config.dart';

class UserService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  // Get user's own listings
  static Future<List<Listing>> getUserListings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        AppConfig.api('user/listings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final listings = (data['listings'] as List)
            .map((listing) => Listing.fromJson(listing))
            .toList();
        return listings;
      }
    } catch (e) {
      // Handle error silently
    }
    return [];
  }

  // Create a new listing (for regular users)
  static Future<Map<String, dynamic>> createListing({
    required String title,
    required String description,
    required double price,
    required int stockQuantity,
    required List<File> images,
    String? size,
    int? categoryId,
    int? departmentId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/api/listings'),
      );

      // Add auth headers ONLY (do not set Content-Type for multipart)
      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // Add text fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['stock_quantity'] = stockQuantity.toString();
      request.fields['status'] = 'pending'; // User listings start as pending
      if (size != null) request.fields['size'] = size;
      if (categoryId != null) {
        request.fields['category_id'] = categoryId.toString();
      }
      if (departmentId != null) {
        request.fields['department_id'] = departmentId.toString();
      }

      // Add image files
      for (int i = 0; i < images.length; i++) {
        final imageFile = images[i];
        final imageStream = http.ByteStream(imageFile.openRead());
        final imageLength = await imageFile.length();
        final multipartFile = http.MultipartFile(
          i == 0 ? 'image' : 'image_$i',
          imageStream,
          imageLength,
          filename: imageFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Listing created successfully',
          'listing': responseData['listing'] != null 
              ? Listing.fromJson(responseData['listing']) 
              : null,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create listing',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Create listing with size variants (for clothing)
  static Future<Map<String, dynamic>> createListingWithVariants({
    required String title,
    required String description,
    required double price,
    required List<File> images,
    required List<Map<String, dynamic>> sizeVariants,
    int? categoryId,
    int? departmentId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/api/listings'),
      );

      // Add auth headers ONLY (do not set Content-Type for multipart)
      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';

      // Add text fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['status'] = 'pending'; // User listings start as pending
      if (categoryId != null) {
        request.fields['category_id'] = categoryId.toString();
      }
      if (departmentId != null) {
        request.fields['department_id'] = departmentId.toString();
      }

      // Add size variants as JSON
      request.fields['size_variants'] = jsonEncode(sizeVariants);

      // Add image files
      for (int i = 0; i < images.length; i++) {
        final imageFile = images[i];
        final imageStream = http.ByteStream(imageFile.openRead());
        final imageLength = await imageFile.length();
        final multipartFile = http.MultipartFile(
          i == 0 ? 'image' : 'image_$i',
          imageStream,
          imageLength,
          filename: imageFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Listing created successfully',
          'listing': responseData['listing'] != null 
              ? Listing.fromJson(responseData['listing']) 
              : null,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to create listing',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: $e',
      };
    }
  }

  // Get categories for dropdown
  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(AppConfig.api('categories'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['categories'] != null) {
          return (data['categories'] as List)
              .map((c) => c as Map<String, dynamic>)
              .toList();
        }
      }
    } catch (e) {
      // Handle error silently
    }
    return [];
  }
}