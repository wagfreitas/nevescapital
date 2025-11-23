import '../repositories/auth_repository.dart';
import '../../../../core/utils/result.dart';

/// Caso de uso para verificar código OTP
/// 
/// Este UseCase encapsula a lógica de negócio para:
/// 1. Validar formato do código OTP
/// 2. Verificar código no backend
/// 3. Retornar sucesso/erro
class VerifyOtpUseCase {
  final AuthRepository _repository;
  
  const VerifyOtpUseCase(this._repository);
  
  /// Executa a verificação do OTP
  /// 
  /// [cpf] CPF do usuário
  /// [phone] Telefone usado no envio do OTP
  /// [otpCode] Código OTP recebido (4-6 dígitos)
  Future<Result<bool>> call({
    required String cpf,
    required String phone,
    required String otpCode,
  }) async {
    // Validação do código OTP
    final cleanCode = otpCode.trim();
    if (cleanCode.isEmpty) {
      return const Error(message: 'Código OTP é obrigatório');
    }
    
    if (cleanCode.length < 4 || cleanCode.length > 6) {
      return const Error(message: 'Código OTP inválido');
    }
    
    if (!RegExp(r'^\d+$').hasMatch(cleanCode)) {
      return const Error(message: 'Código deve conter apenas números');
    }
    
    // Validação de CPF
    final cleanCpf = cpf.replaceAll(RegExp(r'\D'), '');
    if (cleanCpf.isEmpty || cleanCpf.length != 11) {
      return const Error(message: 'CPF inválido');
    }
    
    // Validação de telefone
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.isEmpty || cleanPhone.length < 10) {
      return const Error(message: 'Telefone inválido');
    }
    
    // Delegar para o repository
    return await _repository.verifyOtp(
      cpf: cleanCpf,
      phone: phone,
      otpCode: cleanCode,
    );
  }
}
