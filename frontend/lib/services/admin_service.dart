import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/listing.dart';
import '../models/user_role.dart';
import '../config/app_config.dart';

class AdminService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Authentication failed - no token found');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  // Dashboard Statistics
  static Future<Map<String, dynamic>?> getDashboardStats() async {
    try {
      final headers = await _getHeaders();

      // First test if backend is accessible
      try {
        final testResponse = await http
            .get(AppConfig.api('ping'))
            .timeout(const Duration(seconds: 5));
        if (testResponse.statusCode != 200) {
          return null;
        }
      } catch (e) {
        return null;
      }

      // Test if token is valid by calling a protected endpoint
      try {
        final tokenTestResponse = await http
            .get(AppConfig.api('user'), headers: headers)
            .timeout(const Duration(seconds: 5));
        // Let the actual API call handle any issues
      } catch (e) {
        // Let the actual API call handle it
      }

      final response = await http
          .get(AppConfig.api('admin/dashboard-stats'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stats'];
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed - please login again');
      } else {
        throw Exception('Failed to load dashboard stats: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Authentication failed')) {
        rethrow;
      }
      throw Exception('Network error loading dashboard stats');
    }
  }

  // User Management
  static Future<List<UserSession>> getAllUsers() async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .get(AppConfig.api('admin/users'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['users'] != null) {
          final users = (data['users'] as List)
              .where((user) => user != null)
              .map((user) => UserSession.fromJson(user as Map<String, dynamic>))
              .toList();
          return users;
        } else {
          return [];
        }
      }
    } catch (e) {
      // Handle error silently
    }
    return [];
  }

  // Listing Management
  static Future<List<Listing>> getAllListings() async {
    try {
      final headers = await _getHeaders();

      final base = AppConfig.api('admin/all-listings').toString();
      final url = base.contains('?')
          ? '$base&_t=${DateTime.now().millisecondsSinceEpoch}'
          : '$base?_t=${DateTime.now().millisecondsSinceEpoch}';
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['listings'] != null) {
          final listings = (data['listings'] as List)
              .map((listing) => Listing.fromJson(listing))
              .toList();
          return listings;
        } else {
          return [];
        }
      }
    } catch (e) {
      // Handle error silently
    }
    return [];
  }

  static Future<List<Listing>> getAdminListings() async {
    try {
      final headers = await _getHeaders();

      final ts = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('${AppConfig.api('admin/listings')}&_t=$ts'.replaceFirst('/admin/listings&_t', '/admin/listings?_t')),
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

  static Future<List<Map<String, dynamic>>> getAllCategories() async {
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

  static Future<bool> approveListing(int listingId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        AppConfig.api('admin/listings/$listingId/approve'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Create Discount Code Exception: $e');
      return false;
    }
  }

  static Future<bool> deleteListing(int listingId) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.delete(
        AppConfig.api('admin/listings/$listingId'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Delete Discount Code Exception: $e');
      return false;
    }
  }

  static Future<bool> updateStock(int listingId, int stockQuantity) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        AppConfig.api('admin/listings/$listingId/update-stock'),
        headers: headers,
        body: jsonEncode({'stock_quantity': stockQuantity}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error creating department: $e');
      return false;
    }
  }

  // User Listings (for regular users to view)
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

  static Future<List<Listing>> getApprovedListings() async {
    try {
      final headers = await _getHeaders();

      final base = AppConfig.api('listings').toString();
      final url = base.contains('?')
          ? '$base&_t=${DateTime.now().millisecondsSinceEpoch}'
          : '$base?_t=${DateTime.now().millisecondsSinceEpoch}';
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['listings'] != null) {
          final listings = (data['listings'] as List)
              .map((listing) => Listing.fromJson(listing))
              .toList();
          return listings;
        } else {
          return [];
        }
      }
    } catch (e) {
      // Handle error silently
    }
    return [];
  }

  // Public listings endpoint for guest users (no authentication required)
  static Future<List<Listing>> getPublicListings() async {
    try {
      final base = AppConfig.api('public/listings').toString();
      final url = base.contains('?')
          ? '$base&_t=${DateTime.now().millisecondsSinceEpoch}'
          : '$base?_t=${DateTime.now().millisecondsSinceEpoch}';
      final response = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['listings'] != null) {
          final listings = (data['listings'] as List)
              .map((listing) => Listing.fromJson(listing))
              .toList();
          return listings;
        } else {
          return [];
        }
      }
    } catch (e) {
      // Handle error silently
    }
    return [];
  }

  // User Management Methods
  static Future<bool> grantAdminPrivileges(int userId, int departmentId) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        AppConfig.api('admin/users/$userId/grant-admin'),
        headers: headers,
        body: jsonEncode({'department_id': departmentId}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ Grant Admin Error - Status: ${response.statusCode}');
        print('❌ Grant Admin Error - Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Grant Admin Exception: $e');
      return false;
    }
  }

  static Future<bool> grantSuperAdminPrivileges(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        AppConfig.api('admin/users/$userId/grant-superadmin'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ Grant SuperAdmin Error - Status: ${response.statusCode}');
        print('❌ Grant SuperAdmin Error - Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Grant SuperAdmin Exception: $e');
      return false;
    }
  }

  static Future<bool> revokeAdminPrivileges(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        AppConfig.api('admin/users/$userId/revoke-admin'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ Revoke Admin Error - Status: ${response.statusCode}');
        print('❌ Revoke Admin Error - Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Revoke Admin Exception: $e');
      return false;
    }
  }

  static Future<bool> revokeSuperAdminPrivileges(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        AppConfig.api('admin/users/$userId/revoke-superadmin'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('❌ Revoke SuperAdmin Error - Status: ${response.statusCode}');
        print('❌ Revoke SuperAdmin Error - Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Revoke SuperAdmin Exception: $e');
      return false;
    }
  }

  // Discount Code Management
  Future<List<Map<String, dynamic>>> getDiscountCodes() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        AppConfig.api('admin/discount-codes'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final codes = List<Map<String, dynamic>>.from(data['discount_codes'] ?? []);
        return codes;
      }
      return [];
    } catch (e) {
      print('❌ Get Departments Exception: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDepartments() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        AppConfig.api('admin/departments'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['departments'] ?? []);
      }
      return [];
    } catch (e) {
      // Handle error silently
      return [];
    }
  }

  Future<bool> createDiscountCode(Map<String, dynamic> discountData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        AppConfig.api('admin/discount-codes'),
        headers: headers,
        body: jsonEncode(discountData),
      );

      return response.statusCode == 201;
    } catch (e) {
      print('Error updating department: $e');
      return false;
    }
  }

  Future<bool> deleteDiscountCode(int id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        AppConfig.api('admin/discount-codes/$id'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting department: $e');
      return false;
    }
  }

  // Department Management Methods
  static Future<List<Map<String, dynamic>>> getAllDepartments() async {
    try {
      final headers = await _getHeaders();
      final response = await http
          .get(AppConfig.api('admin/departments'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['departments'] != null) {
          final departments = (data['departments'] as List)
              .map((dept) => dept as Map<String, dynamic>)
              .toList();
          return departments;
        }
      }
    } catch (e) {
      // Handle error silently
    }
    return [];
  }

  static Future<bool> createDepartment(
    String name,
    String description, {
    String? logoPath,
  }) async {
    try {
      final headers = await _getHeaders();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/api/admin/departments'),
      );

      // Add headers
      headers.forEach((key, value) {
        request.headers[key] = value;
      });

      // Add text fields
      request.fields['name'] = name;
      request.fields['description'] = description;

      // Add logo file if provided
      if (logoPath != null && logoPath.isNotEmpty) {
        final file = await http.MultipartFile.fromPath('logo', logoPath);
        request.files.add(file);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
        'Create department response: ${response.statusCode} - ${response.body}',
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error creating listing: $e');
      throw Exception('Failed to create listing: $e');
    }
  }

  static Future<bool> updateDepartment(
    int departmentId,
    String name,
    String description, {
    String? logoPath,
  }) async {
    try {
      final headers = await _getHeaders();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConfig.baseUrl}/api/admin/departments/$departmentId'),
      );

      // Add _method field for PUT request
      request.fields['_method'] = 'PUT';

      // Add headers
      headers.forEach((key, value) {
        request.headers[key] = value;
      });

      // Add text fields
      request.fields['name'] = name;
      request.fields['description'] = description;

      // Add logo file if provided
      if (logoPath != null && logoPath.isNotEmpty) {
        final file = await http.MultipartFile.fromPath('logo', logoPath);
        request.files.add(file);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
        'Update department response: ${response.statusCode} - ${response.body}',
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error creating listing with variants: $e');
      throw Exception('Failed to create listing with variants: $e');
    }
  }

  static Future<bool> deleteDepartment(int departmentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        AppConfig.api('admin/departments/$departmentId'),
        headers: headers,
      );

      print(
        'Delete department response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200;
    } catch (e) {
      // Handle error silently
      return false;
    }
  }

  static Future<bool> createListing({
    required String title,
    required String description,
    required double price,
    required int stockQuantity,
    required String status,
    String? imagePath,
    List<String>? imagePaths,
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
      request.fields['status'] = status;
      if (size != null) request.fields['size'] = size;
      if (categoryId != null) {
        request.fields['category_id'] = categoryId.toString();
      }
      if (departmentId != null) {
        request.fields['department_id'] = departmentId.toString();
      }

      // Add single image file if provided (legacy support)
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = await http.MultipartFile.fromPath('image', imagePath);
        request.files.add(file);
      }
      
      // Add multiple image files if provided
      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (int i = 0; i < imagePaths.length; i++) {
          final path = imagePaths[i];
          if (path.isNotEmpty) {
            final file = await http.MultipartFile.fromPath(
              i == 0 ? 'image' : 'image_$i', 
              path
            );
            request.files.add(file);
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Create listing response status: ${response.statusCode}');
      print('Create listing response body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      // Handle error silently
      return false;
    }
  }

  static Future<bool> createListingWithVariants({
    required String title,
    required String description,
    required double price,
    required String status,
    String? imagePath,
    List<String>? imagePaths,
    int? categoryId,
    int? departmentId,
    required List<Map<String, dynamic>> sizeVariants,
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
      request.fields['status'] = status;
      if (categoryId != null) {
        request.fields['category_id'] = categoryId.toString();
      }
      if (departmentId != null) {
        request.fields['department_id'] = departmentId.toString();
      }

      // Add size variants as JSON
      request.fields['size_variants'] = jsonEncode(sizeVariants);

      // Add single image file if provided (legacy support)
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = await http.MultipartFile.fromPath('image', imagePath);
        request.files.add(file);
      }
      
      // Add multiple image files if provided
      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (int i = 0; i < imagePaths.length; i++) {
          final path = imagePaths[i];
          if (path.isNotEmpty) {
            final file = await http.MultipartFile.fromPath(
              i == 0 ? 'image' : 'image_$i', 
              path
            );
            request.files.add(file);
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Create listing with variants response status: ${response.statusCode}');
      print('Create listing with variants response body: ${response.body}');

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      // Handle error silently
      return false;
    }
  }

  static Future<bool> updateListing(
    int listingId, {
    String? title,
    String? description,
    double? price,
    File? image,
    List<File>? images,
    List<int>? imagesToRemove,
    String? status,
    int? stockQuantity,
    int? categoryId,
    int? departmentId,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final uri = AppConfig.api('admin/listings/$listingId');

      if (image != null || (images != null && images.isNotEmpty) || (imagesToRemove != null && imagesToRemove.isNotEmpty)) {
        // Handle multipart request for image upload or removal
        final request = http.MultipartRequest('POST', uri)
          ..headers['Authorization'] = 'Bearer $token'
          ..headers['Accept'] = 'application/json'
          ..fields['_method'] = 'PUT';

        if (title != null) request.fields['title'] = title;
        if (description != null) request.fields['description'] = description;
        if (price != null) request.fields['price'] = price.toString();
        if (status != null) request.fields['status'] = status;
        if (stockQuantity != null) {
          request.fields['stock_quantity'] = stockQuantity.toString();
        }
        if (categoryId != null) {
          request.fields['category_id'] = categoryId.toString();
        }
        if (departmentId != null) {
          request.fields['department_id'] = departmentId.toString();
        }
        

        
        // Handle specific image removal
        if (imagesToRemove != null && imagesToRemove.isNotEmpty) {
          for (int i = 0; i < imagesToRemove.length; i++) {
            request.fields['images_to_remove[$i]'] = imagesToRemove[i].toString();
          }
        }

        // Handle single image (legacy support)
        if (image != null) {
          final imageStream = http.ByteStream(image.openRead());
          final imageLength = await image.length();
          final multipartFile = http.MultipartFile(
            'image',
            imageStream,
            imageLength,
            filename: image.path.split('/').last,
          );
          request.files.add(multipartFile);
        }

        // Handle multiple images
        if (images != null && images.isNotEmpty) {
          for (int i = 0; i < images.length; i++) {
            final imageFile = images[i];
            final imageStream = http.ByteStream(imageFile.openRead());
            final imageLength = await imageFile.length();
            final multipartFile = http.MultipartFile(
              i == 0 && image == null ? 'image' : 'image_$i',
              imageStream,
              imageLength,
              filename: imageFile.path.split('/').last,
            );
            request.files.add(multipartFile);
          }
        }

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();
        print('Update listing response: ${response.statusCode} - $responseBody');
        if (response.statusCode != 200) {
          throw Exception('Server returned ${response.statusCode}: $responseBody');
        }
        return response.statusCode == 200;
      } else {
        // Handle JSON request for other fields
        final headers = await _getHeaders();
        final Map<String, dynamic> body = {};
        if (title != null) body['title'] = title;
        if (description != null) body['description'] = description;
        if (price != null) body['price'] = price;
        if (status != null) body['status'] = status;
        if (stockQuantity != null) body['stock_quantity'] = stockQuantity;
        if (categoryId != null) body['category_id'] = categoryId;
        if (departmentId != null) body['department_id'] = departmentId;


        final response = await http.put(
          uri,
          headers: headers,
          body: jsonEncode(body),
        );

        print('Update listing response: ${response.statusCode} - ${response.body}');
        if (response.statusCode != 200) {
          throw Exception('Server returned ${response.statusCode}: ${response.body}');
        }
        return response.statusCode == 200;
      }
    } catch (e) {
      print('Error updating listing: $e');
      throw Exception('Failed to update listing: $e');
    }
  }

  static Future<bool> updateListingSizeVariants(
    int listingId,
    List<Map<String, dynamic>> sizeVariants,
  ) async {
    try {
      final headers = await _getHeaders();

      final response = await http.put(
        AppConfig.api('admin/listings/$listingId/size-variants'),
        headers: headers,
        body: jsonEncode({'size_variants': sizeVariants}),
      );

      return response.statusCode == 200;
    } catch (e) {
      // Handle error silently
      return false;
    }
  }

  // Sales Report
  static Future<Map<String, dynamic>?> getSalesReport({
    String? department,
    String? dateRange,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // Build query parameters
      Map<String, String> queryParams = {};
      
      if (department != null && department != 'all') {
        queryParams['department'] = department;
      }
      
      if (dateRange != null) {
        queryParams['dateRange'] = dateRange; // Changed from date_range to dateRange
      }
      
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String().split('T')[0]; // Changed from start_date to startDate
      }
      
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String().split('T')[0]; // Changed from end_date to endDate
      }
      
      // Build URL with query parameters
      String url = 'admin/sales-report';
      if (queryParams.isNotEmpty) {
        String queryString = queryParams.entries
            .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url += '?$queryString';
      }

      print('Sales Report API URL: ${AppConfig.api(url)}'); // Debug log
      
      final response = await http.get(
        AppConfig.api(url),
        headers: headers,
      );

      print('Sales Report Response Status: ${response.statusCode}'); // Debug log
      print('Sales Report Response Body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Sales Report API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Sales Report Exception: $e');
      return null;
    }
  }
}
