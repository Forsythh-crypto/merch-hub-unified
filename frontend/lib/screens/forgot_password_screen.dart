import 'package:flutter/material.dart';
import '../services/auth_services.dart';
import '../styles/auth_styles.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  int _currentStep = 1;
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showDialog(String title, String message, {bool isError = false}) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: TextStyle(color: isError ? Colors.red : Colors.green)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await AuthService.forgotPassword(_emailController.text.trim());
    setState(() => _isLoading = false);

    if (result['success']) {
      setState(() => _currentStep = 2);
      _showDialog('Success', result['message']);
    } else {
      _showDialog('Error', result['message'], isError: true);
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await AuthService.verifyResetCode(
      _emailController.text.trim(),
      _codeController.text.trim(),
    );
    setState(() => _isLoading = false);

    if (result['success'] && result['valid'] == true) {
      setState(() => _currentStep = 3);
    } else {
      _showDialog('Error', 'Invalid verification code', isError: true);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showDialog('Error', 'Passwords do not match', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final result = await AuthService.resetPassword(
      _emailController.text.trim(),
      _codeController.text.trim(),
      _passwordController.text,
      _confirmPasswordController.text,
    );
    setState(() => _isLoading = false);

    if (result['success']) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Success', style: TextStyle(color: Colors.green)),
          content: const Text('Password reset successfully! Can login now.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to login
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      _showDialog('Error', result['message'], isError: true);
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A), // Dark Blue
            fontFamily: 'Montserrat',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your email to receive a verification code',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87, // Dark Grey
            fontFamily: 'Montserrat',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: AuthStyles.inputTextStyle,
          decoration: AuthStyles.getInputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icons.email_outlined,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your email';
            if (!value.contains('@')) return 'Please enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _sendCode,
          style: AuthStyles.primaryButtonStyle,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('SEND CODE'),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Verification Code',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A), // Dark Blue
            fontFamily: 'Montserrat',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the code sent to ${_emailController.text}',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87, // Dark Grey
            fontFamily: 'Montserrat',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          style: AuthStyles.inputTextStyle.copyWith(letterSpacing: 8, fontSize: 24),
          textAlign: TextAlign.center,
          decoration: AuthStyles.getInputDecoration(
            labelText: '6-Digit Code',
            prefixIcon: Icons.lock_clock_outlined,
          ),
          maxLength: 6,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter the code';
            if (value.length != 6) return 'Code must be 6 digits';
            return null;
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _verifyCode,
          style: AuthStyles.primaryButtonStyle,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('VERIFY'),
        ),
        TextButton(
          onPressed: _isLoading ? null : () => setState(() => _currentStep = 1),
          child: const Text('Change Email'),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E3A8A), // Dark Blue
            fontFamily: 'Montserrat',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your new password below',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87, // Dark Grey
            fontFamily: 'Montserrat',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: AuthStyles.inputTextStyle,
          decoration: AuthStyles.getInputDecoration(
            labelText: 'New Password',
            prefixIcon: Icons.lock_outlined,
             suffixIcon: IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter password';
            if (value.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: !_isPasswordVisible,
          style: AuthStyles.inputTextStyle,
          decoration: AuthStyles.getInputDecoration(
            labelText: 'Confirm Password',
            prefixIcon: Icons.lock_outlined,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please confirm password';
            if (value != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _resetPassword,
          style: AuthStyles.primaryButtonStyle,
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('RESET PASSWORD'),
        ),
      ],
    );
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
                  children: [
                    const SizedBox(height: 60),
                     // Logo placeholder or simple title
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
                    const SizedBox(height: 40),
                    
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
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _currentStep == 1
                              ? _buildStep1()
                              : _currentStep == 2
                                  ? _buildStep2()
                                  : _buildStep3(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
