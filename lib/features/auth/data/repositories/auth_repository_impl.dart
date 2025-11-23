import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/network/network_info.dart';
import '../../../../shared/services/firestore_service.dart';

/// Implementação do repositório de autenticação
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required AuthLocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _networkInfo = networkInfo;
  
  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    // Verifica conectividade
    if (!await _networkInfo.isConnected) {
      return const Error(message: 'Sem conexão com a internet');
    }
    
    // Faz login via API
    final result = await _remoteDataSource.login(
      email: email,
      password: password,
    );
    
    if (result.isError) {
      return Error(message: result.errorMessage ?? 'Erro ao fazer login');
    }
    
    final session = result.dataOrNull!;
    final user = session.user;
    
    // Salva dados localmente
    final cacheUserResult = await _localDataSource.saveUser(user);
    if (cacheUserResult.isError) {
      return Error(message: cacheUserResult.errorMessage ?? 'Erro ao cachear usuário');
    }

    final cacheTokenResult = await _localDataSource.saveToken(session.idToken);
    if (cacheTokenResult.isError) {
      return Error(message: cacheTokenResult.errorMessage ?? 'Erro ao cachear token');
    }
    
    return Success(user);
  }
  
  @override
  Future<Result<User>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? document,
  }) async {
    // Verifica conectividade
    if (!await _networkInfo.isConnected) {
      return const Error(message: 'Sem conexão com a internet');
    }
    
    // Registra via API
    final result = await _remoteDataSource.register(
      email: email,
      password: password,
      name: name,
      phone: phone,
      document: document,
    );
    
    if (result.isError) {
      return Error(message: result.errorMessage ?? 'Erro ao registrar usuário');
    }
    
    final session = result.dataOrNull!;
    final user = session.user;
    
    // Salva dados localmente
    final cacheUserResult = await _localDataSource.saveUser(user);
    if (cacheUserResult.isError) {
      return Error(message: cacheUserResult.errorMessage ?? 'Erro ao cachear usuário');
    }

    final cacheTokenResult = await _localDataSource.saveToken(session.idToken);
    if (cacheTokenResult.isError) {
      return Error(message: cacheTokenResult.errorMessage ?? 'Erro ao cachear token');
    }
    
    return Success(user);
  }
  
  @override
  Future<Result<void>> logout() async {
    // Remove dados locais
    await _localDataSource.removeUser();
    await _localDataSource.removeToken();
    
    // Se houver conectividade, faz logout na API
    if (await _networkInfo.isConnected) {
      await _remoteDataSource.logout();
    }
    
    return const Success(null);
  }
  
  @override
  Future<Result<User?>> getCurrentUser() async {
    // Tenta obter do cache local primeiro
    final localResult = await _localDataSource.getUser();
    if (localResult.isSuccess && localResult.dataOrNull != null) {
      return Success(localResult.dataOrNull);
    }
    
    // Se não houver dados locais e houver conectividade, busca da API
    if (await _networkInfo.isConnected) {
      final result = await _remoteDataSource.getCurrentUser();
      if (result.isSuccess && result.dataOrNull != null) {
        await _localDataSource.saveUser(result.dataOrNull!);
        return Success(result.dataOrNull);
      }
    }
    
    return const Success(null);
  }
  
  @override
  Future<Result<bool>> isAuthenticated() async {
    final hasTokenResult = await _localDataSource.hasToken();
    return Success(hasTokenResult.dataOrNull ?? false);
  }
  
  @override
  Future<Result<User>> updateProfile({
    required String name,
    String? phone,
    String? avatar,
  }) async {
    // Verifica conectividade
    if (!await _networkInfo.isConnected) {
      return const Error(message: 'Sem conexão com a internet');
    }
    
    // Atualiza via API
    final result = await _remoteDataSource.updateProfile(
      name: name,
      phone: phone,
      avatar: avatar,
    );
    
    if (result.isError) {
      return Error(message: result.errorMessage ?? 'Erro ao atualizar perfil');
    }
    
    final user = result.dataOrNull!;
    
    // Atualiza dados locais
    await _localDataSource.saveUser(user);
    
    return Success(user);
  }
  
  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    // Verifica conectividade
    if (!await _networkInfo.isConnected) {
      return const Error(message: 'Sem conexão com a internet');
    }
    
    // Altera senha via API
    final result = await _remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    
    if (result.isError) {
      return Error(message: result.errorMessage ?? 'Erro ao alterar senha');
    }
    
    return const Success(null);
  }
  
  // ===== Implementação dos métodos OTP =====
  
  @override
  Future<Result<Map<String, dynamic>>> requestOtp({
    required String cpf,
    required String phone,
  }) async {
    // Verifica conectividade
    if (!await _networkInfo.isConnected) {
      return const Error(message: 'Sem conexão com a internet');
    }
    
    try {
      // Chama serviço para solicitar OTP
      // Por enquanto, retorna sucesso mock até implementar no backend
      return Success({'success': true, 'message': 'OTP enviado via WhatsApp'});
    } catch (e) {
      return Error(message: e.toString().replaceAll('Exception: ', ''));
    }
  }
  
  @override
  Future<Result<bool>> verifyOtp({
    required String cpf,
    required String phone,
    required String otpCode,
  }) async {
    // Verifica conectividade
    if (!await _networkInfo.isConnected) {
      return const Error(message: 'Sem conexão com a internet');
    }
    
    try {
      // MOCK: Aceita código 1234 para testes
      // TODO: Implementar verificação real no backend
      final isValid = otpCode == '1234';
      return Success(isValid);
    } catch (e) {
      return Error(message: e.toString().replaceAll('Exception: ', ''));
    }
  }
  
  @override
  Future<Result<User?>> getUserByCpf({
    required String cpf,
  }) async {
    // Verifica conectividade
    if (!await _networkInfo.isConnected) {
      return const Error(message: 'Sem conexão com a internet');
    }
    
    try {
      // Busca usuário no Firestore
      final userData = await FirestoreService.getUserByCpf(cpf);
      
      if (userData == null) {
        return const Success(null);
      }
      
      // Converte para entidade User
      final user = User(
        id: userData['id'] as String? ?? '',
        email: userData['email'] as String? ?? '',
        name: userData['fullName'] as String? ?? '',
        phone: userData['phone'] as String?,
        avatar: null,
        createdAt: DateTime.now(), // TODO: pegar do Firestore se disponível
        updatedAt: DateTime.now(),
      );
      
      return Success(user);
    } catch (e) {
      return Error(message: e.toString().replaceAll('Exception: ', ''));
    }
  }
}
