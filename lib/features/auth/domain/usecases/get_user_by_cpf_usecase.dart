import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/utils/result.dart';

/// Caso de uso para buscar usuário por CPF
/// 
/// Este UseCase encapsula a lógica de negócio para:
/// 1. Validar CPF
/// 2. Buscar usuário no backend
/// 3. Retornar dados do usuário ou null
class GetUserByCpfUseCase {
  final AuthRepository _repository;
  
  const GetUserByCpfUseCase(this._repository);
  
  /// Executa a busca do usuário por CPF
  /// 
  /// [cpf] CPF do usuário (formato: 000.000.000-00 ou apenas dígitos)
  /// 
  /// Retorna User se encontrado, null se não encontrado, ou Error em caso de falha
  Future<Result<User?>> call({required String cpf}) async {
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
    
    // Delegar para o repository
    return await _repository.getUserByCpf(cpf: cleanCpf);
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
