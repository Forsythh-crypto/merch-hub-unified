import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.11:8000/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null && data['user'] != null) {
          final token = data['token'];
          final userData = data['user'];

          // Save both token and user data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          await prefs.setString('user_data', jsonEncode(userData));
          print('Token and user data saved successfully');

          // Verify the data was saved
          final savedToken = prefs.getString('auth_token');
          final savedUserData = prefs.getString('user_data');
          print('Saved token: $savedToken');
          print('Saved user data: $savedUserData');

          return true;
        } else {
          print('Invalid response data - missing token or user data');
          return false;
        }
      } else {
        print('Login failed with status ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        return jsonDecode(userDataStr) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
