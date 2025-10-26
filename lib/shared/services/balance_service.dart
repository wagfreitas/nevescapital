import 'package:neves_capital/shared/services/user_transaction_service.dart';
import 'package:neves_capital/shared/helpers/format_helpers.dart';

/// Service para gerenciar informações financeiras do usuário
class BalanceService {
  /// Consulta saldo disponível do usuário (agora do banco de dados)
  static Future<Map<String, dynamic>> getSaldoDisponivel() async {
    try {
      final resultado = await UserTransactionService.getSaldoUsuario();
      
      if (resultado['success'] == true) {
        final data = resultado['data'];
        final available = data?['available_amount'] ?? 0;
        final waitingFunds = data?['waiting_funds'] ?? 0;
        final totalTransactions = data?['total_transactions'] ?? 0;
        
        return {
          'success': true,
          'available': available,
          'waiting_funds': waitingFunds,
          'total_transactions': totalTransactions,
          'available_formatted': FormatHelpers.formatCurrency(available / 100),
          'waiting_funds_formatted': FormatHelpers.formatCurrency(waitingFunds / 100),
        };
      } else {
        return {
          'success': false,
          'message': resultado['message'] ?? 'Erro ao consultar saldo',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: ${e.toString()}',
      };
    }
  }
  
  /// Consulta histórico de transações do usuário
  static Future<Map<String, dynamic>> getHistoricoTransacoes({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final resultado = await UserTransactionService.getHistoricoTransacoes(
        limit: limit,
        offset: offset,
      );
      
      if (resultado['success'] == true) {
        return {
          'success': true,
          'data': resultado['data'],
          'pagination': resultado['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': resultado['message'] ?? 'Erro ao consultar histórico',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: ${e.toString()}',
      };
    }
  }
  
  /// Consulta estatísticas do usuário
  static Future<Map<String, dynamic>> getEstatisticasUsuario() async {
    try {
      final resultado = await UserTransactionService.getEstatisticasUsuario();
      
      if (resultado['success'] == true) {
        return {
          'success': true,
          'data': resultado['data'],
        };
      } else {
        return {
          'success': false,
          'message': resultado['message'] ?? 'Erro ao consultar estatísticas',
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