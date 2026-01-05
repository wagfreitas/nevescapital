/// Helper para validação e formatação de Telefone
class PhoneHelper {
  /// Remove caracteres não numéricos do telefone
  static String cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Remove o código do país (55) se presente
  static String removeCountryCode(String phone) {
    final cleanPhoneValue = cleanPhone(phone);
    
    // Se começar com 55 e tiver mais de 11 dígitos, remove o 55
    if (cleanPhoneValue.length > 11 && cleanPhoneValue.startsWith('55')) {
      return cleanPhoneValue.substring(2);
    }
    
    return cleanPhoneValue;
  }

  /// Formata telefone no padrão (xx)xxxxx-xxxx
  /// Remove automaticamente o código do país (55) se presente
  static String formatPhone(String phone) {
    final cleanPhoneValue = removeCountryCode(phone);
    
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

  /// Mascara o telefone mostrando apenas os últimos 4 dígitos
  /// Exemplo: "+55 (11) 98765-4321" -> "+55 (11) XXXXX-4321"
  static String maskPhoneLast4(String phone) {
    final cleanPhoneValue = cleanPhone(phone);
    
    if (cleanPhoneValue.length < 4) {
      return phone; // Retorna original se não tiver pelo menos 4 dígitos
    }
    
    final last4 = cleanPhoneValue.substring(cleanPhoneValue.length - 4);
    
    // Se o telefone tem formatação, tentar manter a estrutura
    if (phone.contains('(') && phone.contains(')')) {
      // Formato: (XX) XXXXX-XXXX ou (XX) XXXX-XXXX
      final parts = phone.split(')');
      if (parts.length == 2) {
        final ddd = parts[0].replaceAll('(', '').replaceAll(' ', '');
        final number = parts[1].trim();
        
        // Contar quantos dígitos tem no número (sem contar o hífen)
        final numberDigits = number.replaceAll('-', '').replaceAll(' ', '');
        final maskedDigits = 'X' * (numberDigits.length - 4);
        
        if (number.contains('-')) {
          // Formato com hífen: XXXXX-4321
          final afterHyphen = number.split('-')[1];
          
          if (afterHyphen.length >= 4) {
            return '+55 ($ddd) $maskedDigits-$last4';
          } else {
            // Se o hífen está no lugar errado, ajustar
            return '+55 ($ddd) $maskedDigits$last4';
          }
        } else {
          // Sem hífen
          return '+55 ($ddd) $maskedDigits$last4';
        }
      }
    }
    
    // Se não tem formatação conhecida, retornar formato padrão
    final maskedDigits = 'X' * (cleanPhoneValue.length - 4);
    return '+55 ($maskedDigits$last4)';
  }
}
