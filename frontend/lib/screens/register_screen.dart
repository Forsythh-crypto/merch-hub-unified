import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../styles/auth_styles.dart';
import 'login_screen.dart';
import 'verification_screen.dart';

class RegisterScreen extends StatefulWidget {
  final String? returnRoute;
  final Map<String, dynamic>? returnArguments;

  const RegisterScreen({
    super.key,
    this.returnRoute,
    this.returnArguments,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _selectedDepartment;
  String _selectedRole = 'student';
  
  // Password validation trackers
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  final List<Map<String, dynamic>> _departments = [
    {
      'id': 1,
      'name': 'School of Information Technology Education',
      'logo': 'assets/logos/site.png',
    },
    {
      'id': 2,
      'name': 'School of Business and Accountancy',
      'logo': 'assets/logos/sba.png',
    },
    {
      'id': 3,
      'name': 'School of Criminology',
      'logo': 'assets/logos/soc.png',
    },
    {
      'id': 4,
      'name': 'School of Engineering',
      'logo': 'assets/logos/soe.png',
    },
    {
      'id': 5,
      'name': 'School of Teacher Education',
      'logo': 'assets/logos/ste.png',
    },
    {
      'id': 6,
      'name': 'School of Humanities',
      'logo': 'assets/logos/soh.png',
    },
    {
      'id': 7,
      'name': 'School of Health Sciences',
      'logo': 'assets/logos/sohs.png',
    },
    {
      'id': 8,
      'name': 'School of International Hospitality Management',
      'logo': 'assets/logos/sihm.png',
    },
  ];

  // Helper method to build password requirement row
  Widget _buildRequirementRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle_outlined,
            color: isMet ? Colors.green : Colors.grey,
            size: 14,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isMet ? Colors.green : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a department'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedDept = _departments.firstWhere(
        (dept) => dept['name'] == _selectedDepartment,
      );

      final response = await http.post(
        Uri.parse('http://localhost:8000/api/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'password_confirmation': _confirmPasswordController.text,
          'department_id': selectedDept['id'],
          'role': _selectedRole,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! Please verify your email.'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to verification screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationScreen(
                email: _emailController.text,
              ),
            ),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorData['message'] ?? 'Registration failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      
                      // Header
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
                      
                      // Form Section
                      Transform.translate(
                        offset: const Offset(0, -45),
                        child: Column(
                          children: [
                            const Text(
                              'Create Account',
                              style: AuthStyles.headingStyle,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Join the UDD community',
                              style: AuthStyles.subheadingStyle,
                            ),
                            const SizedBox(height: 24),

                            // Registration Form
                            Container(
                              constraints: const BoxConstraints(maxWidth: 400),
                              padding: const EdgeInsets.all(24.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.95),
                                borderRadius: BorderRadius.circular(20),
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
                            // Name Field
                            TextFormField(
                              controller: _nameController,
                              style: AuthStyles.inputTextStyle,
                              decoration: AuthStyles.getInputDecoration(
                                labelText: 'Name',
                                prefixIcon: Icons.person_outline,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your full name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: AuthStyles.inputTextStyle,
                              decoration: AuthStyles.getInputDecoration(
                                labelText: 'Email (must end with @cdd.edu.ph)',
                                prefixIcon: Icons.email_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                if (!value.endsWith('@cdd.edu.ph')) {
                                  return 'Email must end with @cdd.edu.ph';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: AuthStyles.inputTextStyle,
                              decoration: AuthStyles.getInputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icons.lock_outlined,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _hasMinLength = value.length >= 8;
                                  _hasUppercase = value.contains(RegExp(r'[A-Z]'));
                                  _hasLowercase = value.contains(RegExp(r'[a-z]'));
                                  _hasDigit = value.contains(RegExp(r'[0-9]'));
                                  _hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters';
                                }
                                if (!value.contains(RegExp(r'[A-Z]'))) {
                                  return 'Password must contain at least one uppercase letter';
                                }
                                if (!value.contains(RegExp(r'[a-z]'))) {
                                  return 'Password must contain at least one lowercase letter';
                                }
                                if (!value.contains(RegExp(r'[0-9]'))) {
                                  return 'Password must contain at least one number';
                                }
                                if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                                  return 'Password must contain at least one special character';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 8),
                            
                            // Password requirements indicators
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Password requirements:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  _buildRequirementRow('At least 8 characters', _hasMinLength),
                                  _buildRequirementRow('At least one uppercase letter', _hasUppercase),
                                  _buildRequirementRow('At least one lowercase letter', _hasLowercase),
                                  _buildRequirementRow('At least one number', _hasDigit),
                                  _buildRequirementRow('At least one special character', _hasSpecialChar),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password Field
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: AuthStyles.inputTextStyle,
                              decoration: AuthStyles.getInputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: Icons.lock_outlined,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword = !_obscureConfirmPassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Department Dropdown
                            SizedBox(
                              width: double.infinity,
                              child: DropdownButtonFormField<String>(
                                value: _selectedDepartment,
                                decoration: AuthStyles.getInputDecoration(
                                  labelText: 'Department',
                                  prefixIcon: Icons.school_outlined,
                                ),
                                isExpanded: true,
                                items: _departments.map((dept) {
                                  return DropdownMenuItem<String>(
                                    value: dept['name'],
                                    child: Text(
                                      dept['name'],
                                      style: const TextStyle(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDepartment = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select a department';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Register Button
                            ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: AuthStyles.primaryButtonStyle,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'REGISTER',
                                      style: AuthStyles.buttonTextStyle,
                                    ),
                            ),
                            const SizedBox(height: 24),

                            // Login Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already have an account? ',
                                  style: AuthStyles.accountheadingStyle,
                                ),
                                TextButton(
                                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginScreen(
                          returnRoute: widget.returnRoute,
                          returnArguments: widget.returnArguments,
                        ),
                      ),
                    );
                  },
                                  child: Text(
                                    'Login',
                                    style: AuthStyles.buttonTextStyle.copyWith(
                                      color: AuthStyles.primaryColor,
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
                    ],
                  ),
                ),
              ),
            ),
            // Back Button
            Positioned(
              top: 50,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                  ),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(
                        returnRoute: widget.returnRoute,
                        returnArguments: widget.returnArguments,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
