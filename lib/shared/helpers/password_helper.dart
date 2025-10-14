/// Helper para validação de senha forte
class PasswordHelper {
  /// Valida se a senha é forte
  static bool isStrongPassword(String password) {
    if (password.length < 8) return false;
    
    // Verifica se tem pelo menos uma letra maiúscula
    if (!RegExp(r'[A-Z]').hasMatch(password)) return false;
    
    // Verifica se tem pelo menos um número
    if (!RegExp(r'[0-9]').hasMatch(password)) return false;
    
    // Verifica se tem pelo menos um caractere especial
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) return false;
    
    return true;
  }

  /// Valida senha forte e retorna mensagem de erro se inválida
  static String? validateStrongPassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Senha é obrigatória';
    }
    
    if (password.length < 8) {
      return 'Senha deve ter pelo menos 8 caracteres';
    }
    
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Senha deve ter pelo menos uma letra maiúscula';
    }
    
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Senha deve ter pelo menos um número';
    }
    
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Senha deve ter pelo menos um caractere especial';
    }
    
    return null;
  }

  /// Valida se as senhas coincidem
  static String? validatePasswordMatch(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    
    if (password != confirmPassword) {
      return 'As senhas não coincidem';
    }
    
    return null;
  }

  /// Retorna critérios de senha forte para exibição
  static List<String> getPasswordCriteria() {
    return [
      'Pelo menos 8 caracteres',
      'Uma letra maiúscula',
      'Um número',
      'Um caractere especial (!@#\$%^&*(),.?":{}|<>)',
    ];
  }
}
