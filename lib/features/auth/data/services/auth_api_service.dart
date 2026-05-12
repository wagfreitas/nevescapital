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

  /// Mensagem de erro do Nest (string ou lista do class-validator).
  static String? _parseApiErrorMessage(Map<String, dynamic> data) {
    final raw = data['message'];
    if (raw == null) return null;
    if (raw is List) return raw.map((e) => e.toString()).join(', ');
    return raw.toString();
  }

  /// Verifica o status do usuário após login no Firebase
  static Future<Map<String, dynamic>> checkUserStatus(String token) async {
    final url = Uri.parse('$_baseUrl/api/auth/check-user-status');

    try {
      AppLogger.info('🚀 [API] Verificando status do usuário...');
      AppLogger.debug('📍 [API] URL: $url');
      AppLogger.debug(
          '🔑 [API] API Key: ${_apiKey.isNotEmpty ? "${_apiKey.substring(0, 10)}..." : "VAZIA"}');

      final response = await http
          .post(
        url,
        headers: _headers,
        body: jsonEncode({'token': token}),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout na requisição');
        },
      );

      AppLogger.debug('📡 [API] Response status: ${response.statusCode}');
      AppLogger.debug('📡 [API] Response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'status': data['status'], // LOGGED_IN, REQUIRE_CPF_CHECK ou REGISTER
          'message': data['message'],
          'phone': data['phone'],
          'userId': data['userId'], // ID do usuário quando status é LOGGED_IN
          'user': data['user'], // Dados do usuário quando status é LOGGED_IN
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro ao verificar status',
        };
      }
    } catch (e) {
      AppLogger.error('❌ [API] Erro em checkUserStatus: $e');
      AppLogger.error('📍 [API] URL tentada: $url');
      AppLogger.error('🔑 [API] API Key configurada: ${_apiKey.isNotEmpty}');

      String errorMessage = 'Erro de conexão. Tente novamente.';
      if (e.toString().contains('Connection refused')) {
        errorMessage =
            'Backend não está rodando. Verifique se o servidor está ativo em $_baseUrl';
      } else if (e.toString().contains('Timeout')) {
        errorMessage = 'Timeout na conexão. Verifique sua internet.';
      }

      return {
        'success': false,
        'message': errorMessage,
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
    final cleanCpf = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    final url = Uri.parse('$_baseUrl/api/users/check-cpf/$cleanCpf');

    try {
      AppLogger.info('🚀 [API] Verificando CPF...');

      final response = await http.get(
        url,
        headers: _headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
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

  /// Envia código OTP via backend (alternativa ao Firebase Phone Auth)
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    final url = Uri.parse('$_baseUrl/api/auth/send-otp');

    try {
      AppLogger.info('🚀 [API] Enviando OTP para: $phone');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({'phone': phone}),
      );

      AppLogger.debug('📡 [API] Response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'code': data['code'], // ⚠️ APENAS PARA TESTES
          'message': data['message'] ?? 'Código OTP enviado',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erro ao enviar OTP',
        };
      }
    } catch (e) {
      AppLogger.error('❌ [API] Erro em sendOtp: $e');
      return {
        'success': false,
        'message': 'Erro de conexão. Tente novamente.',
      };
    }
  }

  /// Verifica código OTP via backend
  static Future<Map<String, dynamic>> verifyOtp(
      String phone, String code) async {
    final url = Uri.parse('$_baseUrl/api/auth/verify-otp');

    try {
      AppLogger.info('🚀 [API] Verificando OTP...');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'phone': phone,
          'code': code,
        }),
      );

      AppLogger.debug('📡 [API] Response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Código OTP verificado',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Código inválido',
        };
      }
    } catch (e) {
      AppLogger.error('❌ [API] Erro em verifyOtp: $e');
      return {
        'success': false,
        'message': 'Erro de conexão. Tente novamente.',
      };
    }
  }

  /// Envia código OTP via WhatsApp (4 dígitos)
  static Future<Map<String, dynamic>> sendOtpWhatsApp(String phone) async {
    final url = Uri.parse('$_baseUrl/api/auth/send-otp-whatsapp');

    try {
      AppLogger.info('🎯 [API] URL: $url');
      AppLogger.info('🚀 [API] Enviando OTP via WhatsApp para: ${phone.substring(0, 4)}***');

      final response = await http
          .post(
        url,
        headers: _headers,
        body: jsonEncode({'phone': phone}),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout na requisição');
        },
      );

      AppLogger.debug('📡 [API] Response status: ${response.statusCode}');
      AppLogger.debug('📡 [API] Response body: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Código enviado via WhatsApp',
        };
      } else {
        return {
          'success': false,
          'message': _parseApiErrorMessage(data) ??
              'Erro ao enviar código via WhatsApp',
        };
      }
    } catch (e) {
      AppLogger.error('❌ [API] Erro em sendOtpWhatsApp: $e');
      return {
        'success': false,
        'message': 'Erro de conexão. Tente novamente.',
      };
    }
  }

  /// Envia código OTP via SMS (canal alternativo ao WhatsApp).
  /// Usado quando o usuário não recebeu o código pelo WhatsApp.
  static Future<Map<String, dynamic>> sendOtpSms(String phone) async {
    final url = Uri.parse('$_baseUrl/api/auth/send-otp-sms');

    try {
      AppLogger.info('🚀 [API] Enviando OTP via SMS para: ${phone.substring(0, 4)}***');

      final response = await http
          .post(
        url,
        headers: _headers,
        body: jsonEncode({'phone': phone}),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout na requisição');
        },
      );

      AppLogger.debug('📡 [API] Response status: ${response.statusCode}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Código enviado via SMS',
        };
      } else {
        return {
          'success': false,
          'message': _parseApiErrorMessage(data) ??
              'Erro ao enviar código via SMS',
        };
      }
    } catch (e) {
      AppLogger.error('❌ [API] Erro em sendOtpSms: $e');
      return {
        'success': false,
        'message': 'Erro de conexão. Tente novamente.',
      };
    }
  }

  /// Envia OTP via Twilio Verify Service (suporta canais 'sms' e 'whatsapp').
  /// O [phone] deve conter apenas dígitos, com código do país (ex: 5511999999999).
  static Future<Map<String, dynamic>> sendVerifyOtp(
      String phone, String channel) async {
    final url = Uri.parse('$_baseUrl/api/auth/send-otp-verify');

    try {
      AppLogger.info(
          '[API] Enviando OTP via Verify ($channel) para: ${phone.substring(0, 4)}***');

      final response = await http
          .post(
        url,
        headers: _headers,
        body: jsonEncode({'phone': phone, 'channel': channel}),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout na requisição');
        },
      );

      AppLogger.debug('[API] Response status: ${response.statusCode}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Código enviado',
          'status': data['status'],
        };
      } else {
        return {
          'success': false,
          'message':
              _parseApiErrorMessage(data) ?? 'Erro ao enviar código',
        };
      }
    } catch (e) {
      AppLogger.error('[API] Erro em sendVerifyOtp: $e');
      return {
        'success': false,
        'message': 'Erro de conexão. Tente novamente.',
      };
    }
  }

  /// Verifica código OTP via Twilio Verify Service.
  /// O [phone] deve conter apenas dígitos, com código do país.
  static Future<Map<String, dynamic>> checkVerifyOtp(
      String phone, String code) async {
    final url = Uri.parse('$_baseUrl/api/auth/check-otp-verify');

    try {
      AppLogger.info('[API] Verificando OTP via Verify...');

      final response = await http
          .post(
        url,
        headers: _headers,
        body: jsonEncode({'phone': phone, 'code': code}),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout na requisição');
        },
      );

      AppLogger.debug('[API] Response status: ${response.statusCode}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': data['message'] ?? 'Código verificado',
          'status': data['status'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Código inválido',
        };
      }
    } catch (e) {
      AppLogger.error('[API] Erro em checkVerifyOtp: $e');
      return {
        'success': false,
        'message': 'Erro de conexão. Tente novamente.',
      };
    }
  }

  /// Verifica OTP e faz login em uma única chamada
  /// Retorna: { success, status (LOGGED_IN/REGISTER), customToken?, userId?, phone? }
  static Future<Map<String, dynamic>> verifyOtpLogin(
      String phone, String code) async {
    final url = Uri.parse('$_baseUrl/api/auth/verify-otp-login');

    try {
      AppLogger.info('🚀 [API] Verificando OTP e login...');

      final response = await http
          .post(
        url,
        headers: _headers,
        body: jsonEncode({
          'phone': phone,
          'code': code,
        }),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout na requisição');
        },
      );

      AppLogger.debug('📡 [API] Response status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'status': data['status'],
          'message': data['message'],
          'customToken': data['customToken'],
          'userId': data['userId'],
          'phone': data['phone'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Código inválido',
        };
      }
    } catch (e) {
      AppLogger.error('❌ [API] Erro em verifyOtpLogin: $e');
      return {
        'success': false,
        'message': 'Erro de conexão. Tente novamente.',
      };
    }
  }

  /// Verifica usuário pelo CPF completo após validação OTP
  /// Retorna o status do usuário e determina o fluxo (login, cadastro, etc)
  static Future<Map<String, dynamic>> checkUserByCpf(
      String token, String cpf) async {
    AppLogger.info('🚀 [API] Verificando usuário pelo CPF completo...');

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
