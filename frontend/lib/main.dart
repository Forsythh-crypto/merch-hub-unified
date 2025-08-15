import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/superadmin_dashboard.dart';
import 'screens/admin_listings_screen.dart';
import 'screens/user_listings_screen.dart';
import 'models/user_role.dart';

void main() {
  runApp(const MerchHubApp());
}

class MerchHubApp extends StatelessWidget {
  const MerchHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Merch Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/superadmin': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          final userSession = UserSession(
            userId: args['userId'],
            name: args['name'],
            email: args['email'],
            role: args['role'] == 'superadmin'
                ? UserRole.superAdmin
                : UserRole.student,
            departmentId: args['departmentId'],
            departmentName: args['departmentName'],
          );
          return SuperAdminDashboard(userSession: userSession);
        },
        '/admin': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          final userSession = UserSession(
            userId: args['userId'],
            name: args['name'],
            email: args['email'],
            role: args['role'] == 'admin' ? UserRole.admin : UserRole.student,
            departmentId: args['departmentId'],
            departmentName: args['departmentName'],
          );
          return AdminListingsScreen(userSession: userSession);
        },
        '/user-listings': (context) {
          final initialDepartment =
              ModalRoute.of(context)?.settings.arguments as String?;
          return UserListingsScreen(initialDepartment: initialDepartment);
        },
      },
    );
  }
}
