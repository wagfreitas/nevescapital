class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://neves-capital-api-452426572797.us-central1.run.app/api',
  );
}
