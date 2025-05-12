class AppConfig {
  static const String apiBaseUrl = 'https://api.example.com';
  static const int connectTimeout = 5000;
  static const int receiveTimeout = 3000;

  // Auth configurations
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Validation configurations
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 32;
  static const String emailRegex = r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+';
}
