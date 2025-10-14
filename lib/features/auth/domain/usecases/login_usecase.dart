import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/utils/result.dart';

/// Caso de uso para fazer login
class LoginUseCase {
  final AuthRepository _repository;
  
  const LoginUseCase(this._repository);
  
  /// Executa o login
  Future<Result<User>> call({
    required String email,
    required String password,
  }) async {
    // Validações básicas
    if (email.isEmpty) {
      return const Error(message: 'Email é obrigatório');
    }
    
    if (password.isEmpty) {
      return const Error(message: 'Senha é obrigatória');
    }
    
    if (!_isValidEmail(email)) {
      return const Error(message: 'Email inválido');
    }
    
    if (password.length < 6) {
      return const Error(message: 'Senha deve ter pelo menos 6 caracteres');
    }
    
    return await _repository.login(
      email: email,
      password: password,
    );
  }
  
  /// Valida formato do email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
