/// Helper para validação e formatação de CPF
class CpfHelper {
  /// Remove caracteres não numéricos do CPF
  static String cleanCpf(String cpf) {
    return cpf.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Formata CPF no padrão xxx.xxx.xxx-xx
  static String formatCpf(String cpf) {
    final cleanCpfValue = cleanCpf(cpf);
    
    if (cleanCpfValue.length <= 3) {
      return cleanCpfValue;
    } else if (cleanCpfValue.length <= 6) {
      return '${cleanCpfValue.substring(0, 3)}.${cleanCpfValue.substring(3)}';
    } else if (cleanCpfValue.length <= 9) {
      return '${cleanCpfValue.substring(0, 3)}.${cleanCpfValue.substring(3, 6)}.${cleanCpfValue.substring(6)}';
    } else if (cleanCpfValue.length <= 11) {
      return '${cleanCpfValue.substring(0, 3)}.${cleanCpfValue.substring(3, 6)}.${cleanCpfValue.substring(6, 9)}-${cleanCpfValue.substring(9)}';
    } else {
      // Se tiver mais de 11 dígitos, limita a 11
      final limitedCpf = cleanCpfValue.substring(0, 11);
      return '${limitedCpf.substring(0, 3)}.${limitedCpf.substring(3, 6)}.${limitedCpf.substring(6, 9)}-${limitedCpf.substring(9)}';
    }
  }

  /// Valida se o CPF é válido
  static bool isValidCpf(String cpf) {
    final cleanCpfValue = cleanCpf(cpf);
    
    // Verifica se tem 11 dígitos
    if (cleanCpfValue.length != 11) {
      return false;
    }
    
    // Verifica se todos os dígitos são iguais (CPF inválido)
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cleanCpfValue)) {
      return false;
    }
    
    // Calcula o primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cleanCpfValue[i]) * (10 - i);
    }
    int firstDigit = (sum * 10) % 11;
    if (firstDigit == 10) firstDigit = 0;
    
    // Verifica o primeiro dígito
    if (int.parse(cleanCpfValue[9]) != firstDigit) {
      return false;
    }
    
    // Calcula o segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cleanCpfValue[i]) * (11 - i);
    }
    int secondDigit = (sum * 10) % 11;
    if (secondDigit == 10) secondDigit = 0;
    
    // Verifica o segundo dígito
    if (int.parse(cleanCpfValue[10]) != secondDigit) {
      return false;
    }
    
    return true;
  }

  /// Valida CPF e retorna mensagem de erro se inválido
  static String? validateCpf(String? cpf) {
    if (cpf == null || cpf.isEmpty) {
      return 'CPF é obrigatório';
    }
    
    final cleanCpfValue = cleanCpf(cpf);
    
    if (cleanCpfValue.length < 11) {
      return 'CPF deve ter 11 dígitos';
    }
    
    if (!isValidCpf(cpf)) {
      return 'CPF inválido';
    }
    
    return null;
  }

  /// Retorna apenas os números do CPF para envio ao backend
  static String getCpfNumbers(String cpf) {
    return cleanCpf(cpf);
  }
}
