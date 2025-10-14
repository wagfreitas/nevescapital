import '../models/user_model.dart';
import '../../../../core/utils/result.dart';

/// Interface para fonte de dados local de autenticação
abstract class AuthLocalDataSource {
  /// Salva token de autenticação
  Future<Result<void>> saveToken(String token);
  
  /// Obtém token de autenticação
  Future<Result<String?>> getToken();
  
  /// Remove token de autenticação
  Future<Result<void>> removeToken();
  
  /// Salva dados do usuário
  Future<Result<void>> saveUser(UserModel user);
  
  /// Obtém dados do usuário
  Future<Result<UserModel?>> getUser();
  
  /// Remove dados do usuário
  Future<Result<void>> removeUser();
  
  /// Verifica se existe token salvo
  Future<Result<bool>> hasToken();
}
