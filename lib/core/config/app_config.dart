class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://pagpagapp-production.up.railway.app/api',
  );
}
