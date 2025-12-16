import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../styles/auth_styles.dart';
import '../models/user_role.dart';

class LoginScreen extends StatefulWidget {
  final String? returnRoute;
  final Map<String, dynamic>? returnArguments;

  const LoginScreen({
    super.key,
    this.returnRoute,
    this.returnArguments,
  });

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

    try {
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
        
        // Clear guest mode after successful login
        await prefs.remove('is_guest_mode');

        // Create UserSession object using fromJson for consistency
        final userSession = UserSession.fromJson(userData);

        // Navigate based on role or return route
        if (!mounted) return;

        // If return route is 'pop', just close the screen (for modal flows)
        if (widget.returnRoute == 'pop') {
           Navigator.pop(context, true);
           return;
        }

        // If there's a return route, navigate directly to it
        if (widget.returnRoute != null) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: const Text('Login successful! Returning to your selected product...'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          
          if (!mounted) return;

          // Navigate directly to the return route without going to home first
          Navigator.pushReplacementNamed(
            context,
            widget.returnRoute!,
            arguments: widget.returnArguments,
          );
          return;
        }
        
        // Otherwise, go to home screen
        Navigator.pushReplacementNamed(context, '/home');

        // For admin/superadmin roles, navigate to their respective dashboards after delay
        if (userSession.isSuperAdmin) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
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
            }
          });
        } else if (userSession.isAdmin) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
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
            }
          });
        }
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(data['message'] ?? 'Login failed'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Network error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1E3A8A),
              const Color(0xFF1E3A8A).withOpacity(0.8),
            ],
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 80.0, 24.0, 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    const SizedBox(height: 60),
                    // Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            height: 220,
                            width: 450,
                            child: Image.asset(
                              'assets/logos/uddess_black.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Text(
                                  'UDD ESSENTIALS',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Montserrat',
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Wrapped text and form with Transform.translate
                    Transform.translate(
                       offset: const Offset(0, -45),
                      child: Column(
                        children: [
                          const Text(
                            'Welcome Back!',
                            style: AuthStyles.headingStyle,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sign in to continue to your account',
                            style: AuthStyles.subheadingStyle,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    // Login Form Section
                    Transform.translate(
                      offset: const Offset(0, 0),
                      child: Column(
                        children: [

                          // Login Form
                          Container(
                            padding: const EdgeInsets.all(24.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                          // Email Field
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: AuthStyles.inputTextStyle,
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
                            style: AuthStyles.inputTextStyle,
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
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/forgot-password');
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Color(0xFF1E3A8A),
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: AuthStyles.primaryButtonStyle,
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text('LOGIN'),
                          ),
                            const SizedBox(height: 32),

                            // Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account? ",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/register',
                                    );
                                  },
                                  child: const Text(
                                    'Register Here',
                                    style: TextStyle(
                                      color: Color(0xFF1E3A8A),
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Back Button (placed last so it stays on top of the stack)
            Positioned(
              top: 50,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
