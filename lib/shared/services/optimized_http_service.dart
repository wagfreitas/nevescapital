import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:neves_capital/core/utils/app_logger.dart';

/// Serviço HTTP otimizado com timeout e retry
class OptimizedHttpService {
  static const Duration _timeout = Duration(seconds: 10); // Timeout otimizado
  static const int _maxRetries = 3;
  static const Duration _baseDelay = Duration(milliseconds: 500);

  /// Fazer requisição GET com retry automático
  static Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    int? maxRetries,
  }) async {
    return await _makeRequestWithRetry(
      () => http.get(Uri.parse(url), headers: headers).timeout(_timeout),
      maxRetries: maxRetries ?? _maxRetries,
    );
  }

  /// Fazer requisição POST com retry automático
  static Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Object? body,
    int? maxRetries,
  }) async {
    return await _makeRequestWithRetry(
      () => http.post(
        Uri.parse(url),
        headers: headers,
        body: body is String ? body : jsonEncode(body),
      ).timeout(_timeout),
      maxRetries: maxRetries ?? _maxRetries,
    );
  }

  /// Fazer requisição PUT com retry automático
  static Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    Object? body,
    int? maxRetries,
  }) async {
    return await _makeRequestWithRetry(
      () => http.put(
        Uri.parse(url),
        headers: headers,
        body: body is String ? body : jsonEncode(body),
      ).timeout(_timeout),
      maxRetries: maxRetries ?? _maxRetries,
    );
  }

  /// Fazer requisição DELETE com retry automático
  static Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    int? maxRetries,
  }) async {
    return await _makeRequestWithRetry(
      () => http.delete(Uri.parse(url), headers: headers).timeout(_timeout),
      maxRetries: maxRetries ?? _maxRetries,
    );
  }

  /// Implementar retry com backoff exponencial
  static Future<http.Response> _makeRequestWithRetry(
    Future<http.Response> Function() request,
    {required int maxRetries}
  ) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      try {
        AppLogger.debug('Tentativa ${attempts + 1}/$maxRetries');
        final response = await request();
        
        // Se a resposta foi bem-sucedida, retornar
        if (response.statusCode >= 200 && response.statusCode < 300) {
          AppLogger.debug('Requisição bem-sucedida');
          return response;
        }
        
        // Se é erro do servidor (5xx), tentar novamente
        if (response.statusCode >= 500) {
          throw HttpException('Erro do servidor: ${response.statusCode}');
        }
        
        // Se é erro do cliente (4xx), não tentar novamente
        return response;
        
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        attempts++;
        
        // Se não é erro de rede, não tentar novamente
        if (!_isNetworkError(e)) {
          AppLogger.error('Erro não relacionado à rede: $e');
          break;
        }
        
        if (attempts < maxRetries) {
          final delay = _calculateDelay(attempts);
          AppLogger.debug('Aguardando ${delay.inMilliseconds}ms antes da próxima tentativa...');
          await Future.delayed(delay);
        }
      }
    }

    throw lastException ?? Exception('Falha após $maxRetries tentativas');
  }

  /// Verificar se é erro de rede
  static bool _isNetworkError(dynamic error) {
    if (error is SocketException) return true;
    if (error is HttpException) return true;
    if (error is TimeoutException) return true;
    if (error.toString().contains('Connection refused')) return true;
    if (error.toString().contains('Network is unreachable')) return true;
    if (error.toString().contains('No route to host')) return true;
    return false;
  }

  /// Calcular delay com backoff exponencial
  static Duration _calculateDelay(int attempt) {
    final delayMs = _baseDelay.inMilliseconds * (1 << (attempt - 1));
    return Duration(milliseconds: delayMs.clamp(100, 5000)); // Entre 100ms e 5s
  }
}
