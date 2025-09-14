import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../screens/superadmin_dashboard.dart';
import '../screens/admin_listings_screen.dart';
import '../screens/user_home_screen.dart';
import '../services/auth_services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  UserSession? _userSession;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserRole();
    });
  }

  Future<void> _checkUserRole() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final userData = await AuthService.getCurrentUser();

      if (!mounted) return;

      if (userData != null) {
        final userSession = UserSession(
          userId: userData['id']?.toString() ?? '',
          name: userData['name'] ?? '',
          email: userData['email'] ?? '',
          role: userData['role'] == 'superadmin'
              ? UserRole.superAdmin
              : userData['role'] == 'admin'
              ? UserRole.admin
              : UserRole.student,
          departmentId: userData['department_id'] is int ? userData['department_id'] : null,
          departmentName: userData['department_name'] ?? '',
        );

        setState(() {
          _userSession = userSession;
        });

        final args = {
          'userId': userData['id']?.toString() ?? '',
          'name': userData['name'] ?? '',
          'email': userData['email'] ?? '',
          'role': userData['role'] ?? '',
          'departmentId': userData['department_id'] is int ? userData['department_id'] : null,
          'departmentName': userData['department_name'] ?? '',
        };

        if (userSession.isSuperAdmin) {
          if (!mounted) return;
          Navigator.of(
            context,
          ).pushReplacementNamed('/superadmin', arguments: args);
        } else if (userSession.isAdmin) {
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/admin', arguments: args);
        }
      } else {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed("/login");
      }
    } catch (e) {
      debugPrint("Error checking user role: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: _userSession?.isSuperAdmin == true
          ? SuperAdminDashboard(userSession: _userSession!)
          : _userSession?.isAdmin == true
          ? AdminListingsScreen(userSession: _userSession!)
          : const UserHomeScreen(),
    );
  }
}
