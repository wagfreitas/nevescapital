import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neves_capital/shared/services/optimized_http_service.dart';
import 'package:neves_capital/shared/services/user_cache_service.dart';

/// Serviço para gerenciar dados no PostgreSQL via API NestJS
class DatabaseService {
  // URL da API - Alternar entre local e produção
  // Para desenvolvimento local: 'http://localhost:8080/api'
  // Para produção: 'https://neves-capital-api-452426572797.us-central1.run.app/api'
  // static const String _baseUrl = 'http://127.0.0.1:8080/api'; // LOCAL DEV (usando 127.0.0.1 para iOS)
  static const String _baseUrl = 'https://neves-capital-api-452426572797.us-central1.run.app/api'; // PRODUCTION
  static const String _apiKey = 'neves-capital-api-key-prod-2024';

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
      print('📤 Enviando dados para API NestJS...');
      print('🔗 URL: $_baseUrl/users/register');

      final response = await http.post(
        Uri.parse('$_baseUrl/users/register'),
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

      print('📥 Status code: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Usuário criado no PostgreSQL: ${data['user_id']}');
        return data;
      } else if (response.statusCode == 409) {
        throw Exception('CPF ou email já cadastrado');
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Erro ao criar usuário: ${error['message'] ?? response.statusCode}');
      }
    } catch (e) {
      print('❌ Erro ao criar usuário: $e');
      throw Exception('Erro ao salvar no PostgreSQL: $e');
    }
  }

  /// Buscar usuário por CPF via API (otimizado com cache)
  static Future<Map<String, dynamic>?> getUserByCpf(String cpf) async {
    try {
      print('🔍 Buscando usuário por CPF: $cpf');

      // SEMPRE buscar na API para obter UUID real do PostgreSQL
      // Não usar cache para dados completos, pois precisamos do ID (UUID) atualizado

      // Se não está no cache, buscar na API
      print('🌐 Buscando na API...');
      final response = await OptimizedHttpService.get(
        '$_baseUrl/users/cpf/$cpf',
        headers: _headers,
      );

      print('📥 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Usuário encontrado na API');
        print('   ID (UUID): ${data['id']}');
        print('   Email: ${data['email'] ?? 'não informado'}');
        
        // Verificar se tem UUID válido
        if (data['id'] == null || data['id'].toString().isEmpty) {
          print('❌ UUID não encontrado na resposta da API');
          return null;
        }
        
        // Salvar no cache para próximas consultas (apenas email)
        if (data['email'] != null) {
          await UserCacheService.cacheUserEmail(cpf, data['email'] as String);
        }
        
        return data;
      } else if (response.statusCode == 404) {
        print('⚠️  Usuário não encontrado');
        return null;
      } else {
        print('❌ Erro ao buscar usuário: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao buscar usuário por CPF: $e');
      // NÃO usar fallback simulado - sempre buscar dados reais
      return null;
    }
  }

  /// Verificar senha do usuário via API
  static Future<bool> verifyPassword(String cpf, String password) async {
    try {
      print('🔐 Verificando senha para CPF: $cpf');

      final response = await http.post(
        Uri.parse('$_baseUrl/users/verify-password'),
        headers: _headers,
        body: jsonEncode({
          'cpf': cpf,
          'password': password,
        }),
      );

      print('📥 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isValid = data['valid'] == true;
        print(isValid ? '✅ Senha válida' : '❌ Senha inválida');
        return isValid;
      } else {
        print('❌ Erro ao verificar senha: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao verificar senha: $e');
      return false;
    }
  }

  /// Buscar dados completos do usuário por Firebase UID
  /// Como o Firebase só tem email, buscamos por email no PostgreSQL
  static Future<Map<String, dynamic>?> getUserByFirebaseUid(String firebaseUid, {String? email}) async {
    try {
      // Se não tem email, não podemos buscar
      if (email == null || email.isEmpty) {
        print('Email necessário para buscar usuário');
        return null;
      }

      print('🔍 Buscando usuário por email do Firebase: $email');
      
      // Buscar por email no PostgreSQL (que descriptografa e compara)
      final userData = await getUserByEmail(email);
      
      if (userData != null && userData['id'] != null) {
        print('✅ Usuário encontrado por email');
        return userData;
      }
      
      print('⚠️ Usuário não encontrado por email');
      return null;
    } catch (e) {
      print('⚠️ Erro ao buscar usuário por Firebase UID: $e');
      return null;
    }
  }

  /// Buscar usuário por email via API
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      print('🔍 Buscando usuário por email: $email');

      // Codificar email para URL (tratar caracteres especiais como @)
      final encodedEmail = Uri.encodeComponent(email);
      
      final response = await OptimizedHttpService.get(
        '$_baseUrl/users/email/$encodedEmail',
        headers: _headers,
      );

      print('📥 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Usuário encontrado na API');
        print('   ID (UUID): ${data['id']}');
        print('   Email: ${data['email'] ?? 'não informado'}');
        
        // Verificar se tem UUID válido
        if (data['id'] == null || data['id'].toString().isEmpty) {
          print('❌ UUID não encontrado na resposta da API');
          return null;
        }
        
        return data;
      } else if (response.statusCode == 404) {
        print('⚠️  Usuário não encontrado');
        return null;
      } else {
        print('❌ Erro ao buscar usuário: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao buscar usuário por email: $e');
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
      print('📝 Atualizando usuário: $userId');

      // Verificar se userId é UUID (PostgreSQL ID) ou Firebase UID
      final isUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(userId);
      
      String postgresUserId = userId;
      
      // Se não for UUID, provavelmente é Firebase UID - precisamos buscar o ID do PostgreSQL
      if (!isUuid) {
        print('⚠️ Firebase UID detectado: $userId');
        print('⚠️ Buscando ID do PostgreSQL...');
        
        // Tentar buscar via CPF conhecido (solução temporária)
        // TODO: Criar endpoint GET /api/users/firebase-uid/:uid
        // Por enquanto, vamos buscar por CPF se for email conhecido
        // Esta é uma solução temporária até implementar endpoint no backend
        
        print('❌ Não é possível atualizar usando Firebase UID diretamente.');
        print('❌ É necessário buscar o ID do PostgreSQL primeiro.');
        print('❌ Solução temporária: buscar via CPF conhecido.');
        
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

      print('📤 Payload: ${jsonEncode(updateData)}');
      print('🔗 URL: $_baseUrl/users/$postgresUserId');

      final response = await http.put(
        Uri.parse('$_baseUrl/users/$postgresUserId'),
        headers: _headers,
        body: jsonEncode(updateData),
      );

      print('📥 Status code: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Usuário atualizado');
        return true;
      } else {
        final errorBody = response.body;
        print('❌ Erro ao atualizar: ${response.statusCode}');
        print('❌ Detalhes: $errorBody');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao atualizar usuário: $e');
      return false;
    }
  }

  /// Deletar usuário via API
  static Future<bool> deleteUser(String userId) async {
    try {
      print('🗑️  Deletando usuário: $userId');

      final response = await http.delete(
        Uri.parse('$_baseUrl/users/$userId'),
        headers: _headers,
      );

      print('📥 Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Usuário deletado');
        return true;
      } else {
        print('❌ Erro ao deletar: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao deletar usuário: $e');
      return false;
    }
  }

  /// Sincronizar email do Firebase com PostgreSQL
  /// Usa o endpoint do backend que atualiza o email no Firebase via Admin SDK
  static Future<bool> syncFirebaseEmail(String cpf, String oldEmail) async {
    try {
      print('🔄 Sincronizando email do Firebase via backend...');
      print('   CPF: $cpf');
      print('   Email antigo: $oldEmail');

      final response = await http.post(
        Uri.parse('$_baseUrl/users/sync-firebase-email'),
        headers: _headers,
        body: jsonEncode({
          'cpf': cpf,
          'oldEmail': oldEmail,
        }),
      );

      print('📥 Status code: ${response.statusCode}');
      print('📥 Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final success = data['success'] == true;
        if (success) {
          print('✅ Email sincronizado com sucesso');
          print('   Email novo: ${data['newEmail']}');
          return true;
        } else {
          print('❌ Sincronização falhou: ${data['message']}');
          return false;
        }
      } else {
        print('❌ Erro ao sincronizar: ${response.statusCode}');
        print('   Detalhes: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Erro ao sincronizar email: $e');
      return false;
    }
  }
}
