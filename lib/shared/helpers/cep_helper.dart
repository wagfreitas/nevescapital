/// Helper para validação e formatação de CEP
class CepHelper {
  /// Remove caracteres não numéricos do CEP
  static String cleanCep(String cep) {
    return cep.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Formata CEP no padrão xxxxx-xxx
  static String formatCep(String cep) {
    final cleanCepValue = cleanCep(cep);
    
    if (cleanCepValue.length <= 5) {
      return cleanCepValue;
    } else if (cleanCepValue.length <= 8) {
      return '${cleanCepValue.substring(0, 5)}-${cleanCepValue.substring(5)}';
    } else {
      // Se tiver mais de 8 dígitos, limita a 8
      final limitedCep = cleanCepValue.substring(0, 8);
      return '${limitedCep.substring(0, 5)}-${limitedCep.substring(5)}';
    }
  }

  /// Valida se o CEP é válido
  static bool isValidCep(String cep) {
    final cleanCepValue = cleanCep(cep);
    
    // Verifica se tem 8 dígitos
    if (cleanCepValue.length != 8) {
      return false;
    }
    
    // Verifica se não são todos dígitos iguais
    if (RegExp(r'^(\d)\1{7}$').hasMatch(cleanCepValue)) {
      return false;
    }
    
    return true;
  }

  /// Valida CEP e retorna mensagem de erro se inválido
  static String? validateCep(String? cep) {
    if (cep == null || cep.isEmpty) {
      return 'CEP é obrigatório';
    }
    
    final cleanCepValue = cleanCep(cep);
    
    if (cleanCepValue.length < 8) {
      return 'CEP deve ter 8 dígitos';
    }
    
    if (!isValidCep(cep)) {
      return 'CEP inválido';
    }
    
    return null;
  }

  /// Retorna apenas os números do CEP para envio ao backend
  static String getCepNumbers(String cep) {
    return cleanCep(cep);
  }
}
