import 'dart:convert';
import 'package:http/http.dart' as http;

/// Helper para busca de endereço por CEP
class CepService {
  static Future<Map<String, String>?> getAddressByCep(String cep) async {
    try {
      final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
      
      if (cleanCep.length != 8) {
        return null;
      }
      
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cleanCep/json/'),
        headers: {'Accept': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['erro'] == true) {
          return null;
        }
        
        return {
          'street': data['logradouro'] ?? '',
          'neighborhood': data['bairro'] ?? '',
          'city': data['localidade'] ?? '',
          'state': data['uf'] ?? '',
        };
      }
      
      return null;
    } catch (e) {
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
