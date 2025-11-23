import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Serviço de logging configurável para substituir prints
/// 
/// Benefícios:
/// - Não loga dados sensíveis em produção
/// - Formatação consistente
/// - Níveis de log (debug, info, warning, error)
/// - Fácil desabilitar em produção
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  /// Log de debug (apenas desenvolvimento)
  static void debug(String message, [dynamic data]) {
    if (!kReleaseMode) {
      _logger.d(message, error: data);
    }
  }

  /// Log de informação
  static void info(String message, [dynamic data]) {
    _logger.i(message, error: data);
  }

  /// Log de warning
  static void warning(String message, [dynamic data]) {
    _logger.w(message, error: data);
  }

  /// Log de erro
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log de dados sensíveis (NUNCA em produção)
  static void sensitive(String label, dynamic data) {
    if (!kReleaseMode && kDebugMode) {
      _logger.d('🔐 [SENSITIVE] $label', error: _maskSensitiveData(data));
    }
  }

  /// Mascara dados sensíveis para logs
  static String _maskSensitiveData(dynamic data) {
    if (data == null) return 'null';
    
    final str = data.toString();
    if (str.length <= 4) return '****';
    
    // Mostra apenas primeiros e últimos 2 caracteres
    return '${str.substring(0, 2)}${'*' * (str.length - 4)}${str.substring(str.length - 2)}';
  }

  /// Log de início de operação
  static void operation(String operation) {
    debug('▶️ Iniciando: $operation');
  }

  /// Log de sucesso de operação
  static void success(String message) {
    debug('✅ $message');
  }

  /// Log de falha de operação
  static void failure(String message, [dynamic error]) {
    error('❌ $message', error);
  }

  /// Log de warning de segurança
  static void securityWarning(String message) {
    warning('🔒 SEGURANÇA: $message');
  }
}
