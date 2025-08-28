class AppConfig {
  static const bool isDevelopment = true;
  static String get _apiBaseUrl {
    // Try the specific IP first, fallback to 0.0.0.0
    const ips = [
      'http://192.168.100.11:8000/api',
      'http://0.0.0.0:8000/api',
      'http://10.0.2.2:8000/api', // Android emulator special IP
    ];
    return ips[0]; // Using first IP for now
  }

  static Uri api(String endpoint) {
    final url = '$_apiBaseUrl/$endpoint';
    // print('API URL: $url'); // Debug log - commented out for production
    return Uri.parse(url);
  }

  static String fileUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    return '$_apiBaseUrl/files/$path';
  }
}
