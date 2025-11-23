import '../entities/user.dart';
import '../../../../core/utils/result.dart';

/// Interface do repositório de autenticação
abstract class AuthRepository {
  /// Faz login do usuário
  Future<Result<User>> login({
    required String email,
    required String password,
  });
  
  /// Registra um novo usuário
  Future<Result<User>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? document,
  });
  
  /// Faz logout do usuário
  Future<Result<void>> logout();
  
  /// Obtém o usuário atual
  Future<Result<User?>> getCurrentUser();
  
  /// Verifica se o usuário está autenticado
  Future<Result<bool>> isAuthenticated();
  
  /// Atualiza o perfil do usuário
  Future<Result<User>> updateProfile({
    required String name,
    String? phone,
    String? avatar,
  });
  
  /// Altera a senha do usuário
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  
  // ===== Métodos OTP (fluxo atual do app) =====
  
  /// Solicita código OTP via WhatsApp
  Future<Result<Map<String, dynamic>>> requestOtp({
    required String cpf,
    required String phone,
  });
  
  /// Verifica código OTP
  Future<Result<bool>> verifyOtp({
    required String cpf,
    required String phone,
    required String otpCode,
  });
  
  /// Busca usuário por CPF
  Future<Result<User?>> getUserByCpf({
    required String cpf,
  });
}
