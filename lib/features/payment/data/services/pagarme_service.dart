import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service para integração com a API do Pagar.me
class PagarmeService {
  // Chave de API do ambiente Sandbox
  static const String _apiKey = 'sk_test_6483ab5348254353b94b703a2af0f839';
  
  // Base URL da API V5 do Pagar.me
  static const String _baseUrl = 'https://api.pagar.me/core/v5';
  
  /// Processa um pagamento com cartão de crédito
  Future<Map<String, dynamic>> processarPagamentoCartao({
    required String nomeEstabelecimento,
    required int valorCentavos,
    required String nomeTitular,
    required String numeroCartao,
    required String cvv,
    required String vencimento,
  }) async {
    try {
      // Dividir vencimento MM/AA
      final vencimentoParts = vencimento.split('/');
      final expMonth = vencimentoParts[0];
      final expYear = '20${vencimentoParts[1]}';
      
      // Construir payload da requisição
      final payload = {
        'amount': valorCentavos, // API V5 espera valor em centavos
        'description': 'Venda - $nomeEstabelecimento',
        'items': [
          {
            'code': 'VENDA_${DateTime.now().millisecondsSinceEpoch}', // Código único obrigatório
            'amount': valorCentavos, // Valor em centavos
            'description': 'Venda - $nomeEstabelecimento',
            'quantity': 1,
          }
        ],
        'payments': [
          {
            'payment_method': 'credit_card',
            'credit_card': {
              'recurrence_cycle': 'first',
              'installments': 1,
              'statement_descriptor': nomeEstabelecimento.substring(0, nomeEstabelecimento.length > 13 ? 13 : nomeEstabelecimento.length),
              'card': {
                'number': numeroCartao.replaceAll(' ', ''),
                'holder_name': nomeTitular,
                'exp_month': int.parse(expMonth),
                'exp_year': int.parse(expYear),
                'cvv': cvv,
                'billing_address': {
                  'line_1': 'Rua das Flores, 123',
                  'zip_code': '01234567',
                  'city': 'São Paulo',
                  'state': 'SP',
                  'country': 'BR'
                }
              },
            },
          }
        ],
        'customer': {
          'name': nomeTitular,
          'email': 'teste@pagpag.com.br', // Email obrigatório
          'type': 'individual',
          'document': '00000000000', // CPF obrigatório para validação
          'phones': {
            'mobile_phone': {
              'country_code': '55',
              'area_code': '11',
              'number': '999999999',
            }
          },
        },
        'metadata': {
          'estabelecimento': nomeEstabelecimento,
        },
      };

      // Fazer requisição para criar o pedido
      final response = await http.post(
        Uri.parse('$_baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_apiKey:'))}',
        },
        body: jsonEncode(payload),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Pagamento criado com sucesso
        final charges = responseData['charges'] as List?;
        
        if (charges != null && charges.isNotEmpty) {
          final charge = charges[0];
          final status = charge['status'];
          
          if (status == 'paid') {
            return {
              'success': true,
              'message': 'Pagamento aprovado com sucesso!',
              'transactionId': charge['id'],
              'orderId': responseData['id'],
            };
          } else if (status == 'pending') {
            return {
              'success': false,
              'message': 'Pagamento pendente de autorização',
              'transactionId': charge['id'],
            };
          } else {
            final errorMessage = charge['last_transaction']?['acquirer_message'] ?? 'Erro desconhecido';
            return {
              'success': false,
              'message': 'Pagamento recusado: $errorMessage',
            };
          }
        }
        
        return {
          'success': false,
          'message': 'Erro ao processar pagamento',
        };
      } else {
        // Erro na requisição
        final errors = responseData['errors'] as Map<String, dynamic>?;
        String errorMessage = 'Erro ao processar pagamento';
        
        if (errors != null) {
          errorMessage = errors.values.first.toString();
        } else if (responseData['message'] != null) {
          errorMessage = responseData['message'];
        }
        
        return {
          'success': false,
          'message': errorMessage,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  /// Tokeniza um cartão (para uso futuro/recorrência)
  Future<Map<String, dynamic>> tokenizarCartao({
    required String numeroCartao,
    required String nomeTitular,
    required String cvv,
    required String vencimento,
  }) async {
    try {
      final vencimentoParts = vencimento.split('/');
      final expMonth = vencimentoParts[0];
      final expYear = '20${vencimentoParts[1]}';
      
      final payload = {
        'type': 'card',
        'card': {
          'number': numeroCartao.replaceAll(' ', ''),
          'holder_name': nomeTitular,
          'exp_month': int.parse(expMonth),
          'exp_year': int.parse(expYear),
          'cvv': cvv,
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/tokens?appId=pk_test_SUACHAVEAQUI'), // Usar chave pública
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'token': responseData['id'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erro ao tokenizar cartão',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: ${e.toString()}',
      };
    }
  }

  /// Consulta status de um pedido
  Future<Map<String, dynamic>> consultarPedido(String orderId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/orders/$orderId'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_apiKey:'))}',
        },
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao consultar pedido',
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


