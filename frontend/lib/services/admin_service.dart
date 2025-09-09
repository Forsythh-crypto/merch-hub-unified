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
    print('🔑 Token retrieved: ${token?.substring(0, 20)}...');
    print('🔑 Full token: $token');
    print('🔑 Token length: ${token?.length}');
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
      print('📊 Getting dashboard stats with headers: $headers');

      // First test if backend is accessible
      try {
        final testResponse = await http
            .get(AppConfig.api('ping'))
            .timeout(const Duration(seconds: 5));
        print('🔗 Backend ping response: ${testResponse.statusCode}');
        print('🔗 Backend ping body: ${testResponse.body}');
      } catch (e) {
        print('❌ Backend not accessible: $e');
        return null;
      }

      // Test if token is valid by calling a protected endpoint
      try {
        final tokenTestResponse = await http
            .get(AppConfig.api('user'), headers: headers)
            .timeout(const Duration(seconds: 5));
        print('🔑 Token test response: ${tokenTestResponse.statusCode}');
        print('🔑 Token test body: ${tokenTestResponse.body}');
        if (tokenTestResponse.statusCode == 401) {
          print('❌ Token is invalid or expired - this will cause logout');
          // Don't return null here, let the actual API call handle it
        }
      } catch (e) {
        print('❌ Token test failed: $e');
        // Don't return null here, let the actual API call handle it
      }

      final response = await http
          .get(AppConfig.api('admin/dashboard-stats'), headers: headers)
          .timeout(const Duration(seconds: 10));

      print(
        '📊 Dashboard stats response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stats'];
      } else {
        print(
          '❌ Dashboard stats failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error getting dashboard stats: $e');
    }
    return null;
  }

  // User Management
  static Future<List<UserSession>> getAllUsers() async {
    try {
      final headers = await _getHeaders();
      print('👥 Getting users with headers: $headers');

      final response = await http
          .get(AppConfig.api('admin/users'), headers: headers)
          .timeout(const Duration(seconds: 10));

      print('👥 Users response status: ${response.statusCode}');
      print('👥 Users response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['users'] != null) {
          final users = (data['users'] as List)
              .where((user) => user != null)
              .map((user) => UserSession.fromJson(user as Map<String, dynamic>))
              .toList();
          print('✅ Parsed ${users.length} users');
          return users;
        } else {
          print('⚠️ No users data in response');
          return [];
        }
      } else {
        print(
          '❌ Failed to get users: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error getting users: $e');
    }
    return [];
  }

  // Listing Management
  static Future<List<Listing>> getAllListings() async {
    try {
      final headers = await _getHeaders();
      print('📦 Getting all listings...');
      print('📦 API URL: ${AppConfig.api('admin/all-listings')}');

      final base = AppConfig.api('admin/all-listings').toString();
      final url = base.contains('?')
          ? '$base&_t=${DateTime.now().millisecondsSinceEpoch}'
          : '$base?_t=${DateTime.now().millisecondsSinceEpoch}';
      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 10));

      print('📦 All listings response: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['listings'] != null) {
          final listings = (data['listings'] as List)
              .map((listing) => Listing.fromJson(listing))
              .toList();
          print('✅ Loaded ${listings.length} listings');
          return listings;
        } else {
          print('⚠️ No listings data in response');
          return [];
        }
      } else {
        print(
          '❌ Failed to get listings: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error getting all listings: $e');
    }
    return [];
  }

  static Future<List<Listing>> getAdminListings() async {
    try {
      final headers = await _getHeaders();
      print(
        '🔍 Getting admin listings from: ${AppConfig.api('admin/listings')}',
      );

      final ts = DateTime.now().millisecondsSinceEpoch;
      final response = await http.get(
        Uri.parse('${AppConfig.api('admin/listings')}&_t=$ts'.replaceFirst('/admin/listings&_t', '/admin/listings?_t')),
        headers: headers,
      );

      print(
        '🔍 Admin listings response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final listings = (data['listings'] as List)
            .map((listing) => Listing.fromJson(listing))
            .toList();

        print('🔍 Parsed ${listings.length} listings');
        return listings;
      } else {
        print('❌ Failed to get admin listings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting admin listings: $e');
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
      print('Error getting categories: $e');
    }
    return [];
  }

  static Future<bool> approveListing(int listingId) async {
    try {
      final headers = await _getHeaders();
      print('🔄 Approving listing ID: $listingId');
      print('🔄 Headers: $headers');

      final response = await http.put(
        AppConfig.api('admin/listings/$listingId/approve'),
        headers: headers,
      );

      print('🔄 Approval response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error approving listing: $e');
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
      print('Error deleting listing: $e');
      return false;
    }
  }

  static Future<bool> updateStock(int listingId, int stockQuantity) async {
    try {
      final headers = await _getHeaders();
      print('🔧 Updating stock for listing $listingId to $stockQuantity');

      final response = await http.put(
        AppConfig.api('admin/listings/$listingId/update-stock'),
        headers: headers,
        body: jsonEncode({'stock_quantity': stockQuantity}),
      );

      print(
        '🔧 Update stock response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating stock: $e');
      return false;
    }
  }

  // User Listings (for regular users to view)
  static Future<List<Listing>> getUserListings() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        AppConfig.api('listings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['listings'] as List)
            .map((listing) => Listing.fromJson(listing))
            .toList();
      }
    } catch (e) {
      print('Error getting user listings: $e');
    }
    return [];
  }

  // User Management Methods
  static Future<bool> grantAdminPrivileges(int userId, int departmentId) async {
    try {
      final headers = await _getHeaders();
      print(
        '🔑 Granting admin privileges to user $userId for department $departmentId',
      );

      final response = await http.put(
        AppConfig.api('admin/users/$userId/grant-admin'),
        headers: headers,
        body: jsonEncode({'department_id': departmentId}),
      );

      print('Grant admin response: ${response.statusCode} - ${response.body}');

      if (response.statusCode != 200) {
        print('❌ Failed to grant admin privileges: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      print('Error granting admin privileges: $e');
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

      print(
        'Grant superadmin response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error granting superadmin privileges: $e');
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

      print('Revoke admin response: ${response.statusCode} - ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('Error revoking admin privileges: $e');
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

      print(
        'Revoke superadmin response: ${response.statusCode} - ${response.body}',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error revoking superadmin privileges: $e');
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

      print(
        '🏢 Departments response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['departments'] != null) {
          final departments = (data['departments'] as List)
              .map((dept) => dept as Map<String, dynamic>)
              .toList();
          print('✅ Parsed ${departments.length} departments');
          return departments;
        }
      } else {
        print(
          '❌ Failed to get departments: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Error getting departments: $e');
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
        Uri.parse(AppConfig.baseUrl + '/api/admin/departments'),
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
      print('Error creating department: $e');
      return false;
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
        Uri.parse(AppConfig.baseUrl + '/api/admin/departments/$departmentId'),
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
      print('Error updating department: $e');
      return false;
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
      print('Error deleting department: $e');
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
    String? size,
    int? categoryId,
    int? departmentId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConfig.baseUrl + '/api/listings'),
      );

      // Add auth headers ONLY (do not set Content-Type for multipart)
      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer ' + token;
      }
      request.headers['Accept'] = 'application/json';

      // Add text fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['stock_quantity'] = stockQuantity.toString();
      request.fields['status'] = status;
      if (size != null) request.fields['size'] = size;
      if (categoryId != null)
        request.fields['category_id'] = categoryId.toString();
      if (departmentId != null)
        request.fields['department_id'] = departmentId.toString();

      // Add image file if provided
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = await http.MultipartFile.fromPath('image', imagePath);
        request.files.add(file);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
        '📦 Create listing response: ${response.statusCode} - ${response.body}',
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Error creating listing: $e');
      return false;
    }
  }

  static Future<bool> createListingWithVariants({
    required String title,
    required String description,
    required double price,
    required String status,
    String? imagePath,
    int? categoryId,
    int? departmentId,
    required List<Map<String, dynamic>> sizeVariants,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConfig.baseUrl + '/api/listings'),
      );

      // Add auth headers ONLY (do not set Content-Type for multipart)
      final token = await _getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer ' + token;
      }
      request.headers['Accept'] = 'application/json';

      // Add text fields
      request.fields['title'] = title;
      request.fields['description'] = description;
      request.fields['price'] = price.toString();
      request.fields['status'] = status;
      if (categoryId != null)
        request.fields['category_id'] = categoryId.toString();
      if (departmentId != null)
        request.fields['department_id'] = departmentId.toString();

      // Add size variants as JSON
      request.fields['size_variants'] = jsonEncode(sizeVariants);

      // Add image file if provided
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = await http.MultipartFile.fromPath('image', imagePath);
        request.files.add(file);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print(
        '📦 Create listing with variants response: ${response.statusCode} - ${response.body}',
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('❌ Error creating listing with variants: $e');
      return false;
    }
  }

  static Future<bool> updateListing(
    int listingId, {
    required String title,
    required String description,
    required double price,
    String? status,
    int? stockQuantity,
  }) async {
    try {
      final headers = await _getHeaders();
      print('🔑 Update listing headers: $headers');
      final requestBody = {
        'title': title,
        'description': description,
        'price': price,
      };

      // Only include status if provided (for superadmins)
      if (status != null) {
        requestBody['status'] = status;
      }

      // Include stock quantity if provided
      if (stockQuantity != null) {
        requestBody['stock_quantity'] = stockQuantity;
      }

      print(
        '📝 Update listing data: {title: $title, description: $description, price: $price, status: $status}',
      );

      final response = await http.put(
        AppConfig.api('admin/listings/$listingId'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print(
        '📦 Update listing response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode != 200) {
        print('❌ Update listing failed with status: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error updating listing: $e');
      return false;
    }
  }

  static Future<bool> updateListingSizeVariants(
    int listingId,
    List<Map<String, dynamic>> sizeVariants,
  ) async {
    try {
      final headers = await _getHeaders();
      print('🔑 Update size variants headers: $headers');
      print('📝 Update size variants data: $sizeVariants');

      final response = await http.put(
        AppConfig.api('admin/listings/$listingId/size-variants'),
        headers: headers,
        body: jsonEncode({'size_variants': sizeVariants}),
      );

      print(
        '📦 Update size variants response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode != 200) {
        print(
          '❌ Update size variants failed with status: ${response.statusCode}',
        );
        print('❌ Response body: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Error updating size variants: $e');
      return false;
    }
  }
}
