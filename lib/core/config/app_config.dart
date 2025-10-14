class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://southamerica-east1-pag-pag-prod.cloudfunctions.net/api',
  );
}
