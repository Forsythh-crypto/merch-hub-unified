import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const bool isDevelopment = true;

  static String get baseUrl {
    final fromEnv = dotenv.env['API_BASE_URL']?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return 'http://localhost:8000';
  }

  static String get _apiBaseUrl => '$baseUrl/api';

  static Uri api(String endpoint) {
    return Uri.parse('$_apiBaseUrl/$endpoint');
  }

  static String fileUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '$_apiBaseUrl/files/$path';
  }
}
