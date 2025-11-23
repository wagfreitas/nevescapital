import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Serviço para gerenciar variáveis de ambiente
/// 
/// IMPORTANTE: 
/// - Nunca commite o arquivo .env no Git
/// - Use .env.example como template
/// - Configure CI/CD para injetar .env em builds
class EnvService {
  /// Carrega as variáveis de ambiente do arquivo .env
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
      // Keep print for visibility during app startup
      print('✅ Variáveis de ambiente carregadas com sucesso');
    } catch (e) {
      // Keep print for debugging env loading issues
      print('⚠️ Erro ao carregar .env: $e');
      print('ℹ️ Usando valores padrão (desenvolvimento)');
    }
  }

  // API Backend
  static String get apiBaseUrl => 
      dotenv.env['API_BASE_URL'] ?? 
      'https://neves-capital-api-124871515546.us-central1.run.app';
  
  static String get apiKey => 
      dotenv.env['API_KEY'] ?? 
      _throwMissingKey('API_KEY');

  // Pagar.me
  static String get pagarmeApiKey => 
      dotenv.env['PAGARME_API_KEY'] ?? 
      _throwMissingKey('PAGARME_API_KEY');
  
  static String get pagarmeBaseUrl => 
      dotenv.env['PAGARME_BASE_URL'] ?? 
      'https://api.pagar.me/core/v5';

  /// Lança erro se chave obrigatória estiver faltando
  static String _throwMissingKey(String key) {
    throw Exception(
      'Variável de ambiente $key não configurada!\n'
      'Crie o arquivo .env baseado em .env.example'
    );
  }

  /// Verifica se todas as chaves obrigatórias estão configuradas
  static bool validateRequiredKeys() {
    try {
      // Tenta acessar todas as chaves obrigatórias
      final _ = [
        apiKey,
        pagarmeApiKey,
      ];
      return true;
    } catch (e) {
      // Keep print for critical env validation errors
      print('❌ Erro na validação de chaves: $e');
      return false;
    }
  }
}
