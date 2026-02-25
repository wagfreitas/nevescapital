import 'dart:convert';
import 'package:http/http.dart' as http;

/// Helper para busca de endereço por CEP
/// Primeira tentativa: BrasilAPI; em caso de falha, usa ViaCEP como redundância.
class CepService {
  static const _brasilApiBase = 'https://brasilapi.com.br/api/cep/v2';
  static const _viaCepBase = 'https://viacep.com.br/ws';

  static Future<Map<String, String>?> getAddressByCep(String cep) async {
    final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCep.length != 8) return null;

    // 1ª tentativa: BrasilAPI
    final result = await _fetchFromBrasilApi(cleanCep);
    if (result != null) return result;

    // 2ª tentativa (redundância): ViaCEP
    return _fetchFromViaCep(cleanCep);
  }

  /// BrasilAPI: https://brasilapi.com.br/api/cep/v2/{cep}
  static Future<Map<String, String>?> _fetchFromBrasilApi(String cleanCep) async {
    try {
      final response = await http.get(
        Uri.parse('$_brasilApiBase/$cleanCep'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>?;
      if (data == null) return null;
      return {
        'street': (data['street'] ?? '').toString().trim(),
        'neighborhood': (data['neighborhood'] ?? '').toString().trim(),
        'city': (data['city'] ?? '').toString().trim(),
        'state': (data['state'] ?? '').toString().trim(),
      };
    } catch (_) {
      return null;
    }
  }

  /// ViaCEP (redundância): https://viacep.com.br/ws/{cep}/json/
  static Future<Map<String, String>?> _fetchFromViaCep(String cleanCep) async {
    try {
      final response = await http.get(
        Uri.parse('$_viaCepBase/$cleanCep/json/'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body) as Map<String, dynamic>?;
      if (data == null || data['erro'] == true) return null;
      return {
        'street': (data['logradouro'] ?? '').toString().trim(),
        'neighborhood': (data['bairro'] ?? '').toString().trim(),
        'city': (data['localidade'] ?? '').toString().trim(),
        'state': (data['uf'] ?? '').toString().trim(),
      };
    } catch (_) {
      return null;
    }
  }
}

/// Modelo para dados de endereço
class AddressData {
  final String street;
  final String neighborhood;
  final String city;
  final String state;
  final String number;
  final String complement;

  AddressData({
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
    this.number = '',
    this.complement = '',
  });

  Map<String, String> toMap() {
    return {
      'street': street,
      'neighborhood': neighborhood,
      'city': city,
      'state': state,
      'number': number,
      'complement': complement,
    };
  }
}
