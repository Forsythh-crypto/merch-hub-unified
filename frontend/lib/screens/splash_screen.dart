import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_role.dart';
import '../screens/config/app_config.dart';
import '../screens/superadmin_dashboard.dart';
import '../screens/admin_listings_screen.dart';
import '../screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/welcome');
        return;
      }

      final response = await http.get(
        AppConfig.api('user'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userSession = UserSession.fromJson(
          data['user'] as Map<String, dynamic>,
        );

        // Navigate based on role without showing home screen
        if (userSession.isSuperAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SuperAdminDashboard(userSession: userSession),
            ),
          );
        } else if (userSession.isAdmin) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AdminListingsScreen(userSession: userSession),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      } else {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } catch (e) {
      print('Error in splash screen: $e');
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // UDD Logo placeholder
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(Icons.school, color: Colors.white, size: 60),
            ),
            const SizedBox(height: 24),
            const Text(
              'UDD MERCH',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
