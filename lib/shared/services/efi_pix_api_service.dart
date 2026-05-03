import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:neves_capital/core/config/env_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Service para chamar os endpoints EFI PIX do backend (sandbox).
class EfiPixApiService {
  static String get _baseUrl => EnvService.apiBaseUrl;
  static String get _apiKey => EnvService.apiKey;

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
      };

  /// Envia PIX via sandbox EFI.
  ///
  /// Suporta 3 modalidades (uma OU outra):
  /// - [chave]: chave PIX do destinatario
  /// - [dadosBancarios]: Map com banco, agencia, conta, cpfCnpj, nome
  /// - [pixCopiaECola]: BR Code
  ///
  /// [valor] deve ser String com 2 casas decimais (ex: "100.50").
  static Future<Map<String, dynamic>> sendPix({
    required String valor,
    String? chave,
    Map<String, dynamic>? dadosBancarios,
    String? pixCopiaECola,
    String? descricao,
  }) async {
    final url = Uri.parse('$_baseUrl/api/_internal/efi/test/pix');

    try {
      AppLogger.info('[EFI PIX] Enviando PIX sandbox...');
      AppLogger.debug('[EFI PIX] URL: $url');
      AppLogger.debug('[EFI PIX] Valor: R\$ $valor');

      final body = <String, dynamic>{
        'valor': valor,
      };

      if (descricao != null) body['descricao'] = descricao;

      if (chave != null) {
        body['chave'] = chave;
      } else if (dadosBancarios != null) {
        body['dadosBancarios'] = dadosBancarios;
      } else if (pixCopiaECola != null) {
        body['pixCopiaECola'] = pixCopiaECola;
      }

      final response = await http
          .post(url, headers: _headers, body: jsonEncode(body))
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Timeout ao enviar PIX');
        },
      );

      AppLogger.debug('[EFI PIX] Response status: ${response.statusCode}');
      AppLogger.debug('[EFI PIX] Response body: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        AppLogger.info('[EFI PIX] PIX enviado com sucesso');
        return {
          ...data,
          'success': true,
          'message': _parseErrorMessage(data),
        };
      } else {
        final message = _parseErrorMessage(data);
        AppLogger.error('[EFI PIX] Erro: $message');
        return {
          ...data,
          'success': false,
          'message': message,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      AppLogger.error('[EFI PIX] Erro ao enviar PIX: $e');
      return {
        'success': false,
        'message': _friendlyErrorMessage(e.toString()),
      };
    }
  }

  /// Consulta status de um PIX enviado.
  static Future<Map<String, dynamic>> getPixStatus(String idEnvio) async {
    final url = Uri.parse('$_baseUrl/api/_internal/efi/test/pix/$idEnvio');

    try {
      AppLogger.info('[EFI PIX] Consultando status do PIX: $idEnvio');

      final response = await http
          .get(url, headers: _headers)
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, ...data};
      } else {
        return {
          'success': false,
          'message': _parseErrorMessage(data),
          ...data,
        };
      }
    } catch (e) {
      AppLogger.error('[EFI PIX] Erro ao consultar PIX: $e');
      return {
        'success': false,
        'message': _friendlyErrorMessage(e.toString()),
      };
    }
  }

  static String _parseErrorMessage(Map<String, dynamic> data) {
    final raw = data['message'];
    if (raw == null) return 'Erro desconhecido';
    if (raw is List) return raw.map((e) => e.toString()).join(', ');
    return raw.toString();
  }

  static String _friendlyErrorMessage(String error) {
    if (error.contains('Connection refused')) {
      return 'Backend indisponivel. Verifique se o servidor esta ativo.';
    }
    if (error.contains('Timeout')) {
      return 'Timeout na conexao. Tente novamente.';
    }
    return 'Erro de conexao. Tente novamente.';
  }
}
