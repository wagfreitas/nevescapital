import '../../domain/usecases/get_user_by_cpf_usecase.dart';
import '../../domain/usecases/login_with_otp_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/datasources/firebase_auth_remote_datasource.dart';
import '../../data/datasources/shared_preferences_auth_local_datasource.dart';
import '../../../../core/network/network_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Factory simples para criar instâncias de UseCases
/// 
/// Esta classe fornece uma forma fácil de obter UseCases sem DI complexa.
/// No futuro, pode ser substituída por GetIt ou similar.
class AuthUseCaseFactory {
  static AuthRepository? _repository;
  
  /// Obtém ou cria a instância do repository
  static Future<AuthRepository> _getRepository() async {
    if (_repository != null) return _repository!;
    
    // Cria datasources
    final prefs = await SharedPreferences.getInstance();
    final localDataSource = SharedPreferencesAuthLocalDataSource(prefs);
    final remoteDataSource = FirebaseAuthRemoteDataSource();
    final networkInfo = NetworkInfoImpl();
    
    // Cria repository
    _repository = AuthRepositoryImpl(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
      networkInfo: networkInfo,
    );
    
    return _repository!;
  }
  
  /// Cria LoginWithOtpUseCase
  static Future<LoginWithOtpUseCase> createLoginWithOtpUseCase() async {
    final repository = await _getRepository();
    return LoginWithOtpUseCase(repository);
  }
  
  /// Cria VerifyOtpUseCase
  static Future<VerifyOtpUseCase> createVerifyOtpUseCase() async {
    final repository = await _getRepository();
    return VerifyOtpUseCase(repository);
  }
  
  /// Cria GetUserByCpfUseCase
  static Future<GetUserByCpfUseCase> createGetUserByCpfUseCase() async {
    final repository = await _getRepository();
    return GetUserByCpfUseCase(repository);
  }
  
  /// Cria LogoutUseCase
  static Future<LogoutUseCase> createLogoutUseCase() async {
    final repository = await _getRepository();
    return LogoutUseCase(repository);
  }
  
  /// Limpa a instância do repository (útil para testes)
  static void reset() {
    _repository = null;
  }
}
