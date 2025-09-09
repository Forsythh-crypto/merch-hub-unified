import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl {
    final fromEnv = dotenv.env['API_BASE_URL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return 'http://localhost:8000';
  }

  static Uri api(String path) {
    return Uri.parse('$baseUrl/api/$path');
  }

  static String fileUrl(String path) {
    return '$baseUrl/api/files/$path';
  }
}
