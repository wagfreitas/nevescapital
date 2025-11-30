import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neves_capital/core/config/env_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

class AuthApiService {
  static String get _baseUrl => EnvService.apiBaseUrl;
  static String get _apiKey => EnvService.apiKey;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
      };

  /// Verifica o status do usuário após login no Firebase
  static Future<Map<String, dynamic>> checkUserStatus(String token) async {
    final url = Uri.parse('$_baseUrl/api/auth/check-user-status');

    try {
      AppLogger.info('🚀 [API] Verificando status do usuário...');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'token': token}),
      );

      AppLogger.debug('📡 [API] Response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'status': data['status'], // REQUIRE_CPF_CHECK ou REGISTER
          'message': data['message'],
          'phone': data['phone'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro ao verificar status',
        };
      }
    } catch (e) {
      AppLogger.error('❌ [API] Erro em checkUserStatus: $e');
      return {
        'success': false,
        'message': 'Erro de conexão. Tente novamente.',
      };
    }
  }

  /// Completa o login verificando o CPF (primeiros 5 dígitos)
  static Future<Map<String, dynamic>> loginComplete(
      String token, String cpfPrefix) async {
    final url = Uri.parse('$_baseUrl/api/auth/login-complete');

    try {
      AppLogger.info('🚀 [API] Completando login com CPF check...');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'token': token,
          'cpfPrefix': cpfPrefix,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'CPF incorreto',
        };
      }
    } catch (e) {
      AppLogger.error('❌ [API] Erro em loginComplete: $e');
      return {
        'success': false,
        'message': 'Erro de conexão. Tente novamente.',
      };
    }
  }

  /// Verifica se um CPF já está cadastrado no sistema
  static Future<Map<String, dynamic>> checkCpf(String cpf) async {
    final url = Uri.parse('$_baseUrl/api/auth/check-cpf');

    try {
      AppLogger.info('🚀 [API] Verificando CPF...');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'cpf': cpf}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'exists': data['exists'] ?? false,
          'message': data['message'] ?? '',
        };
      } else {
        return {
          'success': false,
          'exists': false,
          'message': data['message'] ?? 'Erro ao verificar CPF',
        };
      }
    } catch (e) {
      AppLogger.error('❌ [API] Erro em checkCpf: $e');
      return {
        'success': false,
        'exists': false,
        'message': 'Erro de conexão. Tente novamente.',
      };
    }
  }

  /// Verifica usuário pelo CPF completo após validação OTP
  /// Retorna o status do usuário e determina o fluxo (login, cadastro, etc)
  static Future<Map<String, dynamic>> checkUserByCpf(
      String token, String cpf) async {
    final url = Uri.parse('$_baseUrl/api/auth/check-user-by-cpf');

    try {
      AppLogger.info('🚀 [API] Verificando usuário pelo CPF completo...');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'token': token,
          'cpf': cpf,
        }),
      );

      AppLogger.debug('📡 [API] Response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final status = data['status'] as String;

        // Status possíveis:
        // - LOGIN_SUCCESS: CPF encontrado + telefone correspondente
        // - PHONE_CHANGE_DETECTED: CPF encontrado + telefone diferente
        // - PRE_REGISTRATION_FOUND: Pré-cadastro encontrado
        // - NEW_USER: CPF não encontrado

        return {
          'success': true,
          'status': status,
          'token': data['token'], // Presente em LOGIN_SUCCESS
          'phone': data['phone'], // Telefone cadastrado (se houver)
          'oldPhone':
              data['oldPhone'], // Telefone anterior (se PHONE_CHANGE_DETECTED)
          'currentStep':
              data['currentStep'], // Etapa atual (se PRE_REGISTRATION_FOUND)
          'message': data['message'] ?? '',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Dados não conferem',
        };
      }
    } catch (e) {
      AppLogger.error('❌ [API] Erro em checkUserByCpf: $e');
      return {
        'success': false,
        'message': 'Erro de conexão. Tente novamente.',
      };
    }
  }
}
