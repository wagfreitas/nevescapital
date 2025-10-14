/// Helper para validação de email
class EmailHelper {
  /// Valida se o email tem formato válido
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email.trim());
  }

  /// Valida email e retorna mensagem de erro se inválido
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email é obrigatório';
    }
    
    if (!isValidEmail(email)) {
      return 'Email inválido';
    }
    
    return null;
  }

  /// Limpa o email removendo espaços extras
  static String cleanEmail(String email) {
    return email.trim().toLowerCase();
  }
}
