import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neves_capital/shared/services/optimized_http_service.dart';
import 'package:neves_capital/shared/services/user_cache_service.dart';
import 'package:neves_capital/core/config/env_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Serviço para gerenciar dados no PostgreSQL via API NestJS
/// 
/// SEGURANÇA: API Key e URL carregadas de variáveis de ambiente (.env)
class DatabaseService {
  // URL e chave carregadas de variáveis de ambiente
  static String get _baseUrl => EnvService.apiBaseUrl;
  static String get _apiKey => EnvService.apiKey;

  /// Headers padrão com autenticação
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': _apiKey,
  };

  /// Registrar usuário no PostgreSQL via API
  static Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String fullName,
    required String cpf,
    required String phone,
    required String cep,
    required String address,
    required String neighborhood,
    required String city,
    required String state,
    required String number,
    String? complement,
  }) async {
    try {
      AppLogger.debug('📤 Enviando dados para API NestJS...');
      AppLogger.debug('🔗 URL: $_baseUrl/users/register');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/register'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': fullName,
          'cpf': cpf,
          'phone': phone,
          'cep': cep,
          'address': address,
          'neighborhood': neighborhood,
          'city': city,
          'state': state,
          'number': number,
          'complement': complement ?? '',
        }),
      );

      AppLogger.debug('Status code: ${response.statusCode}');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        AppLogger.info('Usuário criado no PostgreSQL com sucesso');
        return data;
      } else if (response.statusCode == 409) {
        throw Exception('CPF ou email já cadastrado');
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Erro ao criar usuário: ${error['message'] ?? response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Erro ao criar usuário', e);
      throw Exception('Erro ao salvar no PostgreSQL: $e');
    }
  }

  /// Buscar usuário por CPF via API (otimizado com cache)
  static Future<Map<String, dynamic>?> getUserByCpf(String cpf) async {
    try {
      AppLogger.sensitive('Buscando usuário por CPF', cpf);

      // SEMPRE buscar na API para obter UUID real do PostgreSQL
      // Não usar cache para dados completos, pois precisamos do ID (UUID) atualizado

      // Se não está no cache, buscar na API
      AppLogger.debug('Buscando na API...');
      final response = await OptimizedHttpService.get(
        '$_baseUrl/api/users/cpf/$cpf',
        headers: _headers,
      );

      AppLogger.debug('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info('Usuário encontrado na API');
        AppLogger.debug('ID (UUID) presente: ${data['id'] != null}');
        
        // Verificar se tem UUID válido
        if (data['id'] == null || data['id'].toString().isEmpty) {
          AppLogger.warning('UUID não encontrado na resposta da API');
          return null;
        }
        
        // Salvar no cache para próximas consultas (apenas email)
        if (data['email'] != null) {
          await UserCacheService.cacheUserEmail(cpf, data['email'] as String);
        }
        
        return data;
      } else if (response.statusCode == 404) {
        AppLogger.warning('Usuário não encontrado');
        return null;
      } else {
        AppLogger.error('Erro ao buscar usuário: ${response.statusCode}', null);
        return null;
      }
    } catch (e) {
      AppLogger.error('Erro ao buscar usuário por CPF', e);
      // NÃO usar fallback simulado - sempre buscar dados reais
      return null;
    }
  }

  /// Verificar senha do usuário via API
  static Future<bool> verifyPassword(String cpf, String password) async {
    try {
      AppLogger.sensitive('Verificando senha para CPF', cpf);

      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/verify-password'),
        headers: _headers,
        body: jsonEncode({
          'cpf': cpf,
          'password': password,
        }),
      );

      AppLogger.debug('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isValid = data['valid'] == true;
        AppLogger.debug(isValid ? 'Senha válida' : 'Senha inválida');
        return isValid;
      } else {
        AppLogger.error('Erro ao verificar senha: ${response.statusCode}', null);
        return false;
      }
    } catch (e) {
      AppLogger.error('Erro ao verificar senha', e);
      return false;
    }
  }

  /// Buscar dados completos do usuário por Firebase UID
  /// Como o Firebase só tem email, buscamos por email no PostgreSQL
  static Future<Map<String, dynamic>?> getUserByFirebaseUid(String firebaseUid, {String? email}) async {
    try {
      // Se não tem email, não podemos buscar
      if (email == null || email.isEmpty) {
        AppLogger.warning('Email necessário para buscar usuário');
        return null;
      }

      AppLogger.debug('Buscando usuário por email do Firebase');
      
      // Buscar por email no PostgreSQL (que descriptografa e compara)
      final userData = await getUserByEmail(email);
      
      if (userData != null && userData['id'] != null) {
        AppLogger.info('Usuário encontrado por email');
        return userData;
      }
      
      AppLogger.warning('Usuário não encontrado por email');
      return null;
    } catch (e) {
      AppLogger.error('Erro ao buscar usuário por Firebase UID', e);
      return null;
    }
  }

  /// Buscar usuário por email via API
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      AppLogger.sensitive('Buscando usuário por email', email);

      // Codificar email para URL (tratar caracteres especiais como @)
      final encodedEmail = Uri.encodeComponent(email);
      
      final response = await OptimizedHttpService.get(
        '$_baseUrl/api/users/email/$encodedEmail',
        headers: _headers,
      );

      AppLogger.debug('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info('Usuário encontrado na API');
        AppLogger.debug('ID presente: ${data['id'] != null}');
        
        // Verificar se tem UUID válido
        if (data['id'] == null || data['id'].toString().isEmpty) {
          AppLogger.warning('UUID não encontrado na resposta da API');
          return null;
        }
        
        return data;
      } else if (response.statusCode == 404) {
        AppLogger.warning('Usuário não encontrado');
        return null;
      } else {
        AppLogger.error('Erro ao buscar usuário: ${response.statusCode}', null);
        return null;
      }
    } catch (e) {
      AppLogger.error('Erro ao buscar usuário por email', e);
      return null;
    }
  }

  /// Atualizar dados do usuário via API
  /// userId pode ser Firebase UID ou PostgreSQL ID
  static Future<bool> updateUser({
    required String userId,
    String? fullName,
    String? email,
    String? phone,
    String? cep,
    String? address,
    String? neighborhood,
    String? city,
    String? state,
    String? number,
    String? complement,
  }) async {
    try {
      AppLogger.debug('Atualizando usuário');

      // Verificar se userId é UUID (PostgreSQL ID) ou Firebase UID
      final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(userId);
      
      String postgresUserId = userId;
      
      // Se não for UUID, provavelmente é Firebase UID - precisamos buscar o ID do PostgreSQL
      if (!isUuid) {
        AppLogger.warning('Firebase UID detectado - busca de ID PostgreSQL necessária');
        AppLogger.debug('Tentando buscar ID do PostgreSQL');
        
        // Tentar buscar via CPF conhecido (solução temporária)
        // TODO: Criar endpoint GET /api/users/firebase-uid/:uid
        // Por enquanto, vamos buscar por CPF se for email conhecido
        // Esta é uma solução temporária até implementar endpoint no backend
        
        AppLogger.error('Não é possível atualizar usando Firebase UID diretamente', null);
        AppLogger.debug('Solução: buscar ID PostgreSQL via CPF conhecido');
        
        // Retornar erro informativo
        throw Exception('Firebase UID detectado. É necessário buscar o ID do PostgreSQL primeiro. Tente fazer login novamente.');
      }

      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['fullName'] = fullName;
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;
      if (cep != null) updateData['cep'] = cep;
      if (address != null) updateData['address'] = address;
      if (neighborhood != null) updateData['neighborhood'] = neighborhood;
      if (city != null) updateData['city'] = city;
      if (state != null) updateData['state'] = state;
      if (number != null) updateData['number'] = number;
      if (complement != null) updateData['complement'] = complement;

      AppLogger.debug('Preparando atualização de usuário');
      AppLogger.debug('Campos a atualizar: ${updateData.keys.join(", ")}');

      final response = await http.put(
        Uri.parse('$_baseUrl/api/users/$postgresUserId'),
        headers: _headers,
        body: jsonEncode(updateData),
      );

      AppLogger.debug('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        AppLogger.info('Usuário atualizado com sucesso');
        return true;
      } else {
        AppLogger.error('Erro ao atualizar usuário: ${response.statusCode}', null);
        AppLogger.debug('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      AppLogger.error('Erro ao atualizar usuário', e);
      return false;
    }
  }

  /// Deletar usuário via API
  static Future<bool> deleteUser(String userId) async {
    try {
      AppLogger.debug('Deletando usuário');

      final response = await http.delete(
        Uri.parse('$_baseUrl/api/users/$userId'),
        headers: _headers,
      );

      AppLogger.debug('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        AppLogger.info('Usuário deletado com sucesso');
        return true;
      } else {
        AppLogger.error('Erro ao deletar usuário: ${response.statusCode}', null);
        return false;
      }
    } catch (e) {
      AppLogger.error('Erro ao deletar usuário', e);
      return false;
    }
  }

  /// Solicitar código OTP para recuperação de senha via SMS/WhatsApp
  static Future<Map<String, dynamic>> requestPasswordResetOtp(String cpf) async {
    try {
      AppLogger.sensitive('Solicitando código OTP para CPF', cpf);

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/request-password-reset-otp'),
        headers: _headers,
        body: jsonEncode({
          'cpf': cpf,
        }),
      );

      AppLogger.debug('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info('Código OTP solicitado com sucesso');
        return data;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Erro ao solicitar código OTP');
      }
    } catch (e) {
      AppLogger.error('Erro ao solicitar código OTP', e);
      rethrow;
    }
  }

  /// Verificar código OTP e obter token temporário
  static Future<Map<String, dynamic>> verifyPasswordResetOtp(String cpf, String otpCode) async {
    try {
      AppLogger.sensitive('Verificando código OTP', otpCode);

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/verify-password-reset-otp'),
        headers: _headers,
        body: jsonEncode({
          'cpf': cpf,
          'otp_code': otpCode,
        }),
      );

      AppLogger.debug('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info('Código OTP verificado com sucesso');
        return data;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Erro ao verificar código OTP');
      }
    } catch (e) {
      AppLogger.error('Erro ao verificar código OTP', e);
      rethrow;
    }
  }

  /// Alterar senha usando token OTP
  static Future<bool> changePasswordWithOtp({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      AppLogger.debug('Alterando senha com token OTP');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/change-password-with-otp'),
        headers: _headers,
        body: jsonEncode({
          'token': token,
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      AppLogger.debug('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        AppLogger.info('Senha alterada com sucesso');
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Erro ao alterar senha');
      }
    } catch (e) {
      AppLogger.error('Erro ao alterar senha', e);
      rethrow;
    }
  }

  /// Buscar dados da loja do usuário
  static Future<Map<String, dynamic>?> getStoreData(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/$userId/store'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        return null; // Dados não encontrados (normal para primeira vez)
      } else {
        throw Exception('Erro ao buscar dados da loja');
      }
    } catch (e) {
      AppLogger.error('Erro ao buscar dados da loja', e);
      rethrow;
    }
  }

  /// Salvar dados da loja do usuário
  static Future<bool> saveStoreData({
    required String userId,
    required String storeName,
    required String businessType,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/api/users/$userId/store'),
        headers: _headers,
        body: jsonEncode({
          'store_name': storeName,
          'business_type': businessType,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Erro ao salvar dados da loja');
      }
    } catch (e) {
      AppLogger.error('Erro ao salvar dados da loja', e);
      rethrow;
    }
  }

  /// Buscar chaves PIX do usuário
  static Future<List<Map<String, dynamic>>> getPixKeys(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/users/$userId/pix-keys'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        return [];
      }
    } catch (e) {
      AppLogger.error('Erro ao buscar chaves PIX', e);
      return [];
    }
  }

  /// Adicionar chave PIX
  static Future<bool> addPixKey({
    required String userId,
    required String pixKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/$userId/pix-keys'),
        headers: _headers,
        body: jsonEncode({
          'pix_key': pixKey,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Erro ao adicionar chave PIX');
      }
    } catch (e) {
      AppLogger.error('Erro ao adicionar chave PIX', e);
      rethrow;
    }
  }

  /// Remover chave PIX
  static Future<bool> removePixKey({
    required String userId,
    required String keyId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/users/$userId/pix-keys/$keyId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Erro ao remover chave PIX');
      }
    } catch (e) {
      AppLogger.error('Erro ao remover chave PIX', e);
      rethrow;
    }
  }

  /// Sincronizar email do Firebase com PostgreSQL
  /// Usa o endpoint do backend que atualiza o email no Firebase via Admin SDK
  static Future<bool> syncFirebaseEmail(String cpf, String oldEmail) async {
    try {
      AppLogger.debug('Sincronizando email do Firebase via backend');
      AppLogger.sensitive('CPF/Email antigo', '$cpf/$oldEmail');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/users/sync-firebase-email'),
        headers: _headers,
        body: jsonEncode({
          'cpf': cpf,
          'oldEmail': oldEmail,
        }),
      );

      AppLogger.debug('Status code: ${response.statusCode}');
      AppLogger.debug('Response body length: ${response.body.length}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'] == true;
        if (success) {
          AppLogger.info('Email sincronizado com sucesso');
          AppLogger.sensitive('Email novo', data['newEmail']);
          return true;
        } else {
          AppLogger.warning('Sincronização falhou: ${data['message']}');
          return false;
        }
      } else {
        AppLogger.error('Erro ao sincronizar: ${response.statusCode}');
        AppLogger.debug('Detalhes: ${response.body}');
        return false;
      }
    } catch (e) {
      AppLogger.error('Erro ao sincronizar email', e);
      return false;
    }
  }

  /// Verificar se CPF já está cadastrado
  static Future<Map<String, dynamic>> verifyCpf(String cpf) async {
    try {
      AppLogger.sensitive('Verificando CPF', cpf);
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/check-cpf'),
        headers: _headers,
        body: jsonEncode({
          'cpf': cpf,
        }),
      );

      AppLogger.debug('Status code: ${response.statusCode}');

      // Aceitar tanto 200 quanto 201 como sucesso
      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          AppLogger.info('CPF verificado: ${data['exists'] == true ? 'Já cadastrado' : 'Não cadastrado'}');
          
          // Garantir que retorna no formato esperado
          return {
            'success': data['success'] ?? true,
            'exists': data['exists'] ?? false,
            'message': data['message'] ?? '',
          };
        } catch (e) {
          AppLogger.error('Erro ao decodificar resposta', e);
          AppLogger.debug('Response body: ${response.body}');
          throw Exception('Erro ao processar resposta do servidor');
        }
      } else {
        AppLogger.error('Erro ao verificar CPF: ${response.statusCode}', null);
        AppLogger.debug('Detalhes: ${response.body}');
        
        // Tentar extrair mensagem do backend se disponível
        String errorMessage = 'Erro ao verificar CPF';
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>?;
          if (errorData != null && errorData['message'] != null) {
            errorMessage = errorData['message'] as String;
          }
        } catch (_) {
          // Se não conseguir decodificar, usar mensagem padrão
        }
        
        throw Exception(errorMessage);
      }
    } catch (e) {
      AppLogger.error('Erro ao verificar CPF', e);
      
      // Detectar erros de conexão e retornar mensagem amigável
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('econnreset') || 
          errorString.contains('connection refused') ||
          errorString.contains('socketexception') ||
          errorString.contains('failed host lookup') ||
          errorString.contains('network is unreachable')) {
        throw Exception('Erro de conexão. Verifique se o backend está rodando e tente novamente.');
      }
      
      rethrow;
    }
  }

  /// Solicitar código OTP para cadastro via WhatsApp
  static Future<Map<String, dynamic>> requestRegistrationOtp(String cpf, String phone) async {
    try {
      AppLogger.debug('Solicitando OTP de cadastro para: ${phone.substring(0, 2)}***');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/request-registration-otp'),
        headers: _headers,
        body: jsonEncode({
          'cpf': cpf,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        AppLogger.info('OTP solicitado com sucesso');
        return data;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        AppLogger.error('Erro ao solicitar OTP: ${response.statusCode}');
        AppLogger.debug('Detalhes: ${errorData['message'] ?? response.body}');
        throw Exception(errorData['message'] ?? 'Erro ao solicitar código OTP');
      }
    } catch (e) {
      AppLogger.error('Erro ao solicitar OTP de cadastro: $e');
      rethrow;
    }
  }

  /// Verificar código OTP de cadastro
  static Future<Map<String, dynamic>> verifyRegistrationOtp(String cpf, String phone, String otpCode) async {
    try {
      AppLogger.debug('Verificando OTP de cadastro...');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/auth/verify-registration-otp'),
        headers: _headers,
        body: jsonEncode({
          'cpf': cpf,
          'phone': phone,
          'otp_code': otpCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        AppLogger.info('OTP verificado com sucesso');
        return data;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        AppLogger.error('Erro ao verificar OTP: ${response.statusCode}');
        AppLogger.debug('Detalhes: ${errorData['message'] ?? response.body}');
        throw Exception(errorData['message'] ?? 'Código OTP inválido');
      }
    } catch (e) {
      AppLogger.error('Erro ao verificar OTP de cadastro: $e');
      rethrow;
    }
  }
}
