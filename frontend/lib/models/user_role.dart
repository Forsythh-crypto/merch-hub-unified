import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum UserRole { superAdmin, admin, student }

class UserSession {
  final String userId;
  final String name;
  final String email;
  final UserRole role;
  final int? departmentId; // null for superAdmin, specific dept for admin
  final String? departmentName;

  UserSession({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    this.departmentId,
    this.departmentName,
  });

  bool get isSuperAdmin => role == UserRole.superAdmin;
  bool get isAdmin => role == UserRole.admin;
  bool get isStudent => role == UserRole.student;

  // Check if admin can manage specific department
  bool canManageDepartment(int deptId) {
    if (isSuperAdmin) return true;
    if (isAdmin && departmentId == deptId) return true;
    return false;
  }

  factory UserSession.fromJson(Map<String, dynamic> json) {
    UserRole role;
    switch (json['role']) {
      case 'superadmin':
        role = UserRole.superAdmin;
        break;
      case 'admin':
        role = UserRole.admin;
        break;
      case 'student':
        role = UserRole.student;
        break;
      default:
        role = UserRole.student;
    }

    return UserSession(
      userId: json['userId']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: role,
      departmentId: json['departmentId'],
      departmentName: json['departmentName'],
    );
  }

  Map<String, dynamic> toJson() {
    String roleString;
    switch (role) {
      case UserRole.superAdmin:
        roleString = 'superadmin';
        break;
      case UserRole.admin:
        roleString = 'admin';
        break;
      case UserRole.student:
        roleString = 'student';
        break;
    }

    return {
      'userId': userId,
      'name': name,
      'email': email,
      'role': roleString,
      'departmentId': departmentId,
      'departmentName': departmentName,
    };
  }

  // Load user session from storage
  static Future<UserSession?> fromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataStr = prefs.getString('user_data');
      if (userDataStr != null) {
        final userData = jsonDecode(userDataStr) as Map<String, dynamic>;
        return UserSession.fromJson(userData);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
