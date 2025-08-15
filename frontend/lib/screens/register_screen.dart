import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_config.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  List<Map<String, dynamic>> departments = [];
  int? selectedDepartmentId;
  bool isLoadingDepartments = true;

  @override
  void initState() {
    super.initState();
    fetchDepartments();
  }

  Future<void> fetchDepartments() async {
    try {
      final url = AppConfig.api('departments');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData is List
            ? responseData
            : responseData['departments'] ?? [];
        setState(() {
          departments = data
              .map((dept) => {'id': dept['id'], 'name': dept['name']})
              .toList();
          isLoadingDepartments = false;
        });
      } else {
        print('Failed to load departments: ${response.statusCode}');
        setState(() => isLoadingDepartments = false);
      }
    } catch (e) {
      print('Error fetching departments: $e');
      setState(() => isLoadingDepartments = false);
    }
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final password = passwordController.text;
      final confirmPassword = confirmController.text;

      final url = AppConfig.api('register');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'password_confirmation': confirmPassword,
            'department_id': selectedDepartmentId,
            'role': 'student', // Default role for new registrations
          }),
        );

        final data = jsonDecode(response.body);
        if (response.statusCode == 201 && data['token'] != null) {
          await saveToken(data['token']);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registration successful')),
          );

          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Registration failed')),
          );
        }
      } catch (e) {
        print('Error during registration: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Network error')));
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value == null || value.length < 6
                    ? 'Minimum 6 characters'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: confirmController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirm your password';
                  }
                  if (value != passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedDepartmentId,
                decoration: const InputDecoration(labelText: 'Department'),
                items: departments.map((dept) {
                  return DropdownMenuItem<int>(
                    value: dept['id'],
                    child: Text(dept['name'], overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDepartmentId = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a department' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
