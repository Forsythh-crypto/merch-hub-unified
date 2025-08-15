class AppConfig {
  // Development URLs - automatically detects environment
  static String get baseUrl {
    // For web development, use localhost
    if (identical(0, 0.0)) {
      return 'http://192.168.100.11:8000';
    }
    // For mobile development, use your local network IP
    return 'http://192.168.100.11:8000';
  }

  static Uri api(String path) {
    return Uri.parse('$baseUrl/api/$path');
  }

  // Helper methods for common endpoints
  static Uri login() => api('login');
  static Uri register() => api('register');
  static Uri logout() => api('logout');
  static Uri user() => api('user');
  static Uri userPermissions() => api('user/permissions');
  static Uri listings() => api('listings');
  static Uri adminListings() => api('admin/listings');
  static Uri categories() => api('categories');
  static Uri departments() => api('departments');
}
