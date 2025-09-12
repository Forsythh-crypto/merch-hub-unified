import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PingScreen extends StatefulWidget {
  const PingScreen({super.key});

  @override
  _PingScreenState createState() => _PingScreenState();
}

class _PingScreenState extends State<PingScreen> {
  String message = 'Checking...';

  @override
  void initState() {
    super.initState();
    checkPing();
  }

  Future<void> checkPing() async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    final response = await http.get(Uri.parse('$baseUrl/api/ping'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        message = data['message']; // should be "pong"
      });
    } else {
      setState(() {
        message = 'Failed to connect: ${response.statusCode}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ping Test')),
      body: Center(child: Text(message)),
    );
  }
}