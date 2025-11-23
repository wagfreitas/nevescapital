import '../repositories/auth_repository.dart';
import '../../../../core/utils/result.dart';

/// Caso de uso para login com OTP (fluxo atual do app)
/// 
/// Este UseCase encapsula a lógica de negócio para:
/// 1. Validar CPF
/// 2. Solicitar OTP via WhatsApp
/// 3. Retornar sucesso/erro
class LoginWithOtpUseCase {
  final AuthRepository _repository;
  
  const LoginWithOtpUseCase(this._repository);
  
  /// Executa o login com OTP
  /// 
  /// [cpf] CPF do usuário (formato: 000.000.000-00 ou apenas dígitos)
  /// [phone] Telefone para envio do OTP (formato: +5511999999999)
  Future<Result<Map<String, dynamic>>> call({
    required String cpf,
    required String phone,
  }) async {
    // Validação de CPF
    final cleanCpf = cpf.replaceAll(RegExp(r'\D'), '');
    if (cleanCpf.isEmpty) {
      return const Error(message: 'CPF é obrigatório');
    }
    
    if (cleanCpf.length != 11) {
      return const Error(message: 'CPF inválido');
    }
    
    if (!_isValidCpf(cleanCpf)) {
      return const Error(message: 'CPF inválido');
    }
    
    // Validação de telefone
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty) {
      return const Error(message: 'Telefone é obrigatório');
    }
    
    if (cleanPhone.length < 10) {
      return const Error(message: 'Telefone inválido');
    }
    
    // Delegar para o repository
    return await _repository.requestOtp(
      cpf: cleanCpf,
      phone: phone,
    );
  }
  
  /// Valida CPF usando algoritmo oficial
  bool _isValidCpf(String cpf) {
    // Remove formatação
    cpf = cpf.replaceAll(RegExp(r'\D'), '');
    
    // Verifica se tem 11 dígitos
    if (cpf.length != 11) return false;
    
    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;
    
    // Valida primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(cpf[i]) * (10 - i);
    }
    int firstDigit = 11 - (sum % 11);
    if (firstDigit >= 10) firstDigit = 0;
    if (firstDigit != int.parse(cpf[9])) return false;
    
    // Valida segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(cpf[i]) * (11 - i);
    }
    int secondDigit = 11 - (sum % 11);
    if (secondDigit >= 10) secondDigit = 0;
    if (secondDigit != int.parse(cpf[10])) return false;
    
    return true;
  }
}
