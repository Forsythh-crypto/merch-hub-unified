import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../styles/auth_styles.dart';
import '../models/user_role.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    final url = AppConfig.api('login');
    print('Attempting to connect to: $url'); // Debug log

    try {
      print('Sending login request...'); // Debug log
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json', // Add Accept header
        },
        body: jsonEncode({
          'email': emailController.text.trim(),
          'password': passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      setState(() => isLoading = false);

      if (response.statusCode == 200 && data['token'] != null) {
        final token = data['token'];
        final userData = data['user'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_data', jsonEncode(userData));

        print('Login successful, token: $token');

        // Create UserSession object
        final userSession = UserSession(
          userId: userData['id'].toString(),
          name: userData['name'],
          email: userData['email'],
          role: userData['role'] == 'superadmin'
              ? UserRole.superAdmin
              : userData['role'] == 'admin'
              ? UserRole.admin
              : UserRole.student,
          departmentId: userData['department_id'],
          departmentName: userData['department_name'],
        );

        // Navigate based on role
        if (!mounted) return;

        if (userSession.isSuperAdmin) {
          Navigator.pushReplacementNamed(
            context,
            '/superadmin',
            arguments: {
              'userId': userSession.userId,
              'name': userSession.name,
              'email': userSession.email,
              'role': userSession.role == UserRole.superAdmin
                  ? 'superadmin'
                  : 'admin',
              'departmentId': userSession.departmentId,
              'departmentName': userSession.departmentName,
            },
          );
        } else if (userSession.isAdmin) {
          Navigator.pushReplacementNamed(
            context,
            '/admin',
            arguments: {
              'userId': userSession.userId,
              'name': userSession.name,
              'email': userSession.email,
              'role': userSession.role == UserRole.admin ? 'admin' : 'student',
              'departmentId': userSession.departmentId,
              'departmentName': userSession.departmentName,
            },
          );
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        print('Login failed: ${data['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      print('Login error: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Network error')));
    }
  }

  void testLaravelLink() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.100.11:8000/api/ping'),
      );
      print('Ping status: ${response.statusCode}');
      print('Ping body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ping successful: ${response.statusCode}')),
      );
    } catch (e) {
      print('Ping error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ping failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Back Button
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Logo and Welcome Text
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: AuthStyles.primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.school,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Welcome Back!',
                            style: AuthStyles.headingStyle,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sign in to continue',
                            style: AuthStyles.subheadingStyle,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Login Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email Field
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: AuthStyles.getInputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icons.email_outlined,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: passwordController,
                            obscureText: !isPasswordVisible,
                            decoration: AuthStyles.getInputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icons.lock_outlined,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    isPasswordVisible = !isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: AuthStyles.primaryButtonStyle,
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'LOGIN',
                                    style: AuthStyles.buttonTextStyle,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: AuthStyles.subheadingStyle,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(
                              context,
                              '/register',
                            );
                          },
                          child: Text(
                            'Register',
                            style: AuthStyles.buttonTextStyle.copyWith(
                              color: AuthStyles.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Debug Test Button - Only show in debug mode
                    if (AppConfig.isDevelopment)
                      TextButton(
                        onPressed: testLaravelLink,
                        child: const Text('Test Laravel Link'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
