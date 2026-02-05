/// Constantes gerais da aplicação
class AppConstants {
  // URLs e endpoints
  static const String baseUrl = 'https://api.nevescapital.com';
  static const String apiVersion = 'v1';
  
  // Chaves de armazenamento local
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // Configurações da aplicação
  static const String appName = 'Pag Pag';
  static const String appVersion = '1.0.0';
  
  // Timeouts
  static const int connectionTimeout = 30000; // 30 segundos
  static const int receiveTimeout = 30000; // 30 segundos
}
