/// Classe com validadores comuns para formulários
class Validators {
  /// Valida se o email está em formato válido
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    
    return null;
  }
  
  /// Valida se a senha atende aos critérios mínimos
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    
    if (value.length < 6) {
      return 'Senha deve ter pelo menos 6 caracteres';
    }
    
    return null;
  }
  
  /// Valida se o campo não está vazio
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Campo'} é obrigatório';
    }
    return null;
  }
  
  /// Valida se o valor tem o tamanho mínimo
  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Campo'} é obrigatório';
    }
    
    if (value.length < minLength) {
      return '${fieldName ?? 'Campo'} deve ter pelo menos $minLength caracteres';
    }
    
    return null;
  }
  
  /// Valida se o valor tem o tamanho máximo
  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value != null && value.length > maxLength) {
      return '${fieldName ?? 'Campo'} deve ter no máximo $maxLength caracteres';
    }
    
    return null;
  }
  
  /// Valida se o valor é um número válido
  static String? number(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Campo'} é obrigatório';
    }
    
    if (double.tryParse(value) == null) {
      return '${fieldName ?? 'Campo'} deve ser um número válido';
    }
    
    return null;
  }
  
  /// Valida se o valor é um número positivo
  static String? positiveNumber(String? value, {String? fieldName}) {
    final numberValidation = number(value, fieldName: fieldName);
    if (numberValidation != null) return numberValidation;
    
    final numValue = double.parse(value!);
    if (numValue <= 0) {
      return '${fieldName ?? 'Campo'} deve ser um número positivo';
    }
    
    return null;
  }
  
  /// Valida se o telefone está em formato válido
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefone é obrigatório';
    }
    
    // Remove caracteres não numéricos
    final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cleanValue.length < 10 || cleanValue.length > 11) {
      return 'Telefone inválido';
    }
    
    return null;
  }
}
