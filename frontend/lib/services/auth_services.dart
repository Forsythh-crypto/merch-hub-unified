import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        AppConfig.api('login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null && data['user'] != null) {
          final token = data['token'];
          final userData = data['user'];

          // Save both token and user data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setString('user_data', jsonEncode(userData));
          
          // Clear guest mode after successful login
          await prefs.remove('is_guest_mode');

          return true;
        } else {
          return false;
        }
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        final userData = jsonDecode(userDataStr) as Map<String, dynamic>;
        return userData;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getCurrentUserRole() async {
    try {
      final userData = await getCurrentUser();
      return userData?['role'];
    } catch (e) {
      return null;
    }
  }

  static Future<int?> getCurrentUserDepartment() async {
    try {
      final userData = await getCurrentUser();
      return userData?['departmentId'];
    } catch (e) {
      return null;
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
    } catch (e) {
      // Handle error silently
    }
  }
  // Verify email
  static Future<bool> verifyEmail(String email, String code) async {
    try {
      final response = await http.post(
        AppConfig.api('verify-email'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userData = data['user'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_data', jsonEncode(userData));
        
        return true;
      }
      return false;
    } catch (e) {
      print('Verify email error: $e');
      return false;
    }
  }

  // Resend verification code
  static Future<bool> resendCode(String email) async {
    try {
      final response = await http.post(
        AppConfig.api('resend-verification'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Resend code error: $e');
      return false;
    }
  }

  // Update profile
  static Future<bool> updateProfile({String? name, String? password}) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (password != null) {
        body['password'] = password;
        body['password_confirmation'] = password;
      }

      final response = await http.post(
        AppConfig.api('update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['user'];
        
        // Update stored user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(userData));
        
        return true;
      }
      return false;
    } catch (e) {
      print('Update profile error: $e');
      return false;
    }
  }
}
