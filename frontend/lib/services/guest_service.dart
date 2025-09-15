import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_role.dart';
import '../widgets/login_prompt_dialog.dart';

class GuestService {
  static const String _guestModeKey = 'is_guest_mode';
  static const String _userSessionKey = 'user_session';
  
  // Check if user is in guest mode
  static Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestModeKey) ?? false;
  }
  
  // Set guest mode
  static Future<void> setGuestMode(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestModeKey, isGuest);
  }
  
  // Check if user is authenticated (has valid session)
  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final isGuest = await isGuestMode();
    return token != null && !isGuest;
  }
  
  // Get current user session (null if guest)
  static Future<UserSession?> getCurrentUserSession() async {
    final isGuest = await isGuestMode();
    if (isGuest) return null;
    
    final prefs = await SharedPreferences.getInstance();
    final userSessionJson = prefs.getString(_userSessionKey);
    if (userSessionJson != null) {
      // Parse and return user session
      // This would need to be implemented based on how you store user session
      return null; // Placeholder
    }
    return null;
  }
  
  // Clear guest mode and any stored data
  static Future<void> clearGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestModeKey);
  }
  
  // Check if action requires authentication
  static bool requiresAuthentication(String action) {
    const restrictedActions = [
      'reserve_product',
      'pre_order',
      'add_to_cart',
      'checkout',
      'view_orders',
      'create_listing',
    ];
    return restrictedActions.contains(action);
  }
  
  // Show login prompt for restricted actions
  static Future<bool> promptLogin(
    BuildContext context, 
    String action, {
    String? returnRoute,
    Map<String, dynamic>? returnArguments,
  }) async {
    return await LoginPromptDialog.show(
      context, 
      action: action,
      returnRoute: returnRoute,
      returnArguments: returnArguments,
    );
  }
}