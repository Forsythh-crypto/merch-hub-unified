import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/admin_service.dart';
import '../config/app_config.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _debugInfo = '';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  Future<void> _testListingsAPI() async {
    setState(() {
      _debugInfo = 'Testing listings API...\n';
    });

    try {
      // Test 1: Check if we can get headers
      final headers = await _getHeaders();
      setState(() {
        _debugInfo += 'Headers obtained: ${headers.toString()}\n';
      });

      // Test 2: Test the API endpoint directly
      final url = AppConfig.api('admin/all-listings');
      setState(() {
        _debugInfo += 'API URL: $url\n';
      });

      final response = await http.get(url, headers: headers);
      setState(() {
        _debugInfo += 'Response status: ${response.statusCode}\n';
        _debugInfo += 'Response body: ${response.body}\n';
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['listings'] != null) {
          final listings = data['listings'] as List;
          setState(() {
            _debugInfo += 'Found ${listings.length} listings\n';
            for (int i = 0; i < listings.length; i++) {
              _debugInfo +=
                  'Listing $i: ${listings[i]['title']} - Status: ${listings[i]['status']}\n';
            }
          });
        } else {
          setState(() {
            _debugInfo += 'No listings data in response\n';
          });
        }
      } else {
        setState(() {
          _debugInfo += 'API call failed with status ${response.statusCode}\n';
        });
      }
    } catch (e) {
      setState(() {
        _debugInfo += 'Error: $e\n';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Screen'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _testListingsAPI,
              child: const Text('Test Listings API'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _debugInfo,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
