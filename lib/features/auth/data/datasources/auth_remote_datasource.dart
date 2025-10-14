import '../models/user_model.dart';
import '../../../../core/utils/result.dart';

/// Representa sessão autenticada retornada pelo backend
class RemoteAuthSession {
  final UserModel user;
  final String idToken;

  const RemoteAuthSession({
    required this.user,
    required this.idToken,
  });
}

/// Interface para fonte de dados remota de autenticação
abstract class AuthRemoteDataSource {
  /// Faz login via API
  Future<Result<RemoteAuthSession>> login({
    required String email,
    required String password,
  });
  
  /// Registra usuário via API
  Future<Result<RemoteAuthSession>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? document,
  });
  
  /// Obtém dados do usuário atual via API
  Future<Result<UserModel>> getCurrentUser();
  
  /// Atualiza perfil via API
  Future<Result<UserModel>> updateProfile({
    required String name,
    String? phone,
    String? avatar,
  });
  
  /// Altera senha via API
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
  
  /// Faz logout via API
  Future<Result<void>> logout();
}
