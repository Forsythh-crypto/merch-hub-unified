class AppConfig {
  static String baseUrl =
      'http://192.168.100.11:8000'; // Updated to match auth service

  static Uri api(String path) {
    return Uri.parse('$baseUrl/api/$path');
  }
}
