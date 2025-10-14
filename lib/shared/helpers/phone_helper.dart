/// Helper para validação e formatação de Telefone
class PhoneHelper {
  /// Remove caracteres não numéricos do telefone
  static String cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Formata telefone no padrão (xx)xxxxx-xxxx
  static String formatPhone(String phone) {
    final cleanPhoneValue = cleanPhone(phone);
    
    if (cleanPhoneValue.isEmpty) {
      return '';
    } else if (cleanPhoneValue.length <= 2) {
      return '($cleanPhoneValue';
    } else if (cleanPhoneValue.length <= 7) {
      return '(${cleanPhoneValue.substring(0, 2)})${cleanPhoneValue.substring(2)}';
    } else if (cleanPhoneValue.length <= 11) {
      return '(${cleanPhoneValue.substring(0, 2)})${cleanPhoneValue.substring(2, 7)}-${cleanPhoneValue.substring(7)}';
    } else {
      // Se tiver mais de 11 dígitos, limita a 11
      final limitedPhone = cleanPhoneValue.substring(0, 11);
      return '(${limitedPhone.substring(0, 2)})${limitedPhone.substring(2, 7)}-${limitedPhone.substring(7)}';
    }
  }

  /// Valida se o telefone é válido
  static bool isValidPhone(String phone) {
    final cleanPhoneValue = cleanPhone(phone);
    
    // Verifica se tem 10 ou 11 dígitos (com ou sem 9)
    if (cleanPhoneValue.length < 10 || cleanPhoneValue.length > 11) {
      return false;
    }
    
    // Verifica se o DDD é válido (11 a 99)
    if (cleanPhoneValue.length >= 2) {
      final ddd = int.tryParse(cleanPhoneValue.substring(0, 2));
      if (ddd == null || ddd < 11 || ddd > 99) {
        return false;
      }
    }
    
    // Verifica se não são todos dígitos iguais
    if (RegExp(r'^(\d)\1{9,10}$').hasMatch(cleanPhoneValue)) {
      return false;
    }
    
    return true;
  }

  /// Valida telefone e retorna mensagem de erro se inválido
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Telefone é obrigatório';
    }
    
    final cleanPhoneValue = cleanPhone(phone);
    
    if (cleanPhoneValue.length < 10) {
      return 'Telefone deve ter pelo menos 10 dígitos';
    }
    
    if (cleanPhoneValue.length > 11) {
      return 'Telefone deve ter no máximo 11 dígitos';
    }
    
    if (!isValidPhone(phone)) {
      return 'Telefone inválido';
    }
    
    return null;
  }

  /// Retorna apenas os números do telefone para envio ao backend
  static String getPhoneNumbers(String phone) {
    return cleanPhone(phone);
  }
}
