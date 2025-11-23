import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neves_capital/shared/helpers/user_helper.dart';

/// Service para gerenciar transações do usuário
class UserTransactionService {
  static const String _baseUrl = 'https://neves-capital-api-124871515546.us-central1.run.app/api';
  
  /// Busca saldo do usuário logado
  static Future<Map<String, dynamic>> getSaldoUsuario() async {
    try {
      final user = await UserHelper.getCurrentUser();
      if (user == null) {
        return {
          'success': false,
          'message': 'Usuário não logado',
        };
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/transactions/balance/${user.uid}'),
        headers: {
          'Content-Type': 'application/json',
          // TODO: Adicionar autenticação quando implementada
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao buscar saldo',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  /// Busca histórico de transações do usuário
  static Future<Map<String, dynamic>> getHistoricoTransacoes({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final user = await UserHelper.getCurrentUser();
      if (user == null) {
        return {
          'success': false,
          'message': 'Usuário não logado',
        };
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/transactions/history/${user.uid}?limit=$limit&offset=$offset'),
        headers: {
          'Content-Type': 'application/json',
          // TODO: Adicionar autenticação quando implementada
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
          'pagination': data['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao buscar histórico',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  /// Busca estatísticas do usuário
  static Future<Map<String, dynamic>> getEstatisticasUsuario() async {
    try {
      final user = await UserHelper.getCurrentUser();
      if (user == null) {
        return {
          'success': false,
          'message': 'Usuário não logado',
        };
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/transactions/stats/${user.uid}'),
        headers: {
          'Content-Type': 'application/json',
          // TODO: Adicionar autenticação quando implementada
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao buscar estatísticas',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  /// Verifica status de sincronização de uma transação
  static Future<Map<String, dynamic>> getStatusSincronizacao(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/transactions/sync-status/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          // TODO: Adicionar autenticação quando implementada
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao verificar status de sincronização',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: ${e.toString()}',
      };
    }
  }
}
