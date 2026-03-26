import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

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
      AppLogger.info('✅ Variáveis de ambiente carregadas com sucesso');
    } catch (e) {
      AppLogger.warning('⚠️ Erro ao carregar .env: $e');
      AppLogger.info('ℹ️ Usando valores padrão (desenvolvimento)');
    }
  }

  // API Backend
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ??
      'https://nevescapital-production.up.railway.app';

  static String get apiKey =>
      dotenv.env['API_KEY'] ?? '';

  // Pagar.me
  static String get pagarmeApiKey =>
      dotenv.env['PAGARME_API_KEY'] ?? '';

  static String get pagarmeBaseUrl =>
      dotenv.env['PAGARME_BASE_URL'] ?? 'https://api.pagar.me/core/v5';

  /// Verifica se todas as chaves obrigatórias estão configuradas
  static bool validateRequiredKeys() {
    try {
      final apiKeyValue = apiKey;
      final pagarmeKeyValue = pagarmeApiKey;
      
      if (apiKeyValue.isEmpty) {
        AppLogger.warning('⚠️ API_KEY não configurada');
        return false;
      }
      
      if (pagarmeKeyValue.isEmpty) {
        AppLogger.warning('⚠️ PAGARME_API_KEY não configurada');
        return false;
      }
      
      return true;
    } catch (e) {
      AppLogger.error('❌ Erro na validação de chaves: $e');
      return false;
    }
  }
}
