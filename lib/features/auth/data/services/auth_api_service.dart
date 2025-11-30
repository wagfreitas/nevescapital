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

  // 🎭 MODO MOCK PARA TESTES
  static const bool _useMockData = true;

  // 🎯 DADOS DE TESTE - CPFs para cada cenário
  static const Map<String, Map<String, dynamic>> _mockUsers = {
    '12345678901': {
      // Cenário A: LOGIN_SUCCESS
      'status': 'LOGIN_SUCCESS',
      'phone': '+5511989630454',
      'token': 'mock-token-user-1',
    },
    '98765432100': {
      // Cenário B: PHONE_CHANGE_DETECTED
      'status': 'PHONE_CHANGE_DETECTED',
      'phone': '+5511989630454', // Telefone NOVO (atual)
      'oldPhone': '+5511999999999', // Telefone ANTIGO
    },
    '11122233344': {
      // Cenário C: PRE_REGISTRATION_FOUND
      'status': 'PRE_REGISTRATION_FOUND',
      'currentStep': 'email',
      'phone': '+5511989630454',
    },
    '55566677788': {
      // Cenário D: NEW_USER
      'status': 'NEW_USER',
    },
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
    AppLogger.info('🚀 [API] Verificando usuário pelo CPF completo...');

    // 🎭 MODO MOCK: Retornar dados fake
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simular latência

      final cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
      final mockUser = _mockUsers[cleanCpf];

      if (mockUser != null) {
        AppLogger.info('✅ [MOCK] CPF encontrado: ${mockUser['status']}');
        return {
          'success': true,
          ...mockUser,
        };
      } else {
        // CPF não encontrado nos mocks - considerar novo usuário
        AppLogger.info('✅ [MOCK] CPF não encontrado - NEW_USER');
        return {
          'success': true,
          'status': 'NEW_USER',
        };
      }
    }

    // MODO REAL: Chamar API
    final url = Uri.parse('$_baseUrl/api/auth/check-user-by-cpf');

    try {
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

        return {
          'success': true,
          'status': status,
          'token': data['token'],
          'phone': data['phone'],
          'oldPhone': data['oldPhone'],
          'currentStep': data['currentStep'],
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
