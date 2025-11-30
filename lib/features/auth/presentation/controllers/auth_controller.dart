import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neves_capital/shared/services/auth_service.dart';
import 'package:neves_capital/shared/services/firestore_service.dart';
import 'package:neves_capital/shared/services/biometric_service.dart';
import 'package:neves_capital/shared/services/user_cache_service.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';
import 'package:neves_capital/shared/helpers/user_helper.dart';
import 'package:neves_capital/core/utils/app_logger.dart';
import 'package:neves_capital/core/utils/result.dart';
import 'package:neves_capital/features/auth/presentation/factories/auth_usecase_factory.dart';

/// Estados de progresso do login
enum LoginProgress {
  idle,
  searchingUser,
  authenticating,
  success,
  error,
}

/// Controller para gerenciar autenticação (Firebase + PostgreSQL)
class AuthController extends ChangeNotifier {
  firebase_auth.User? _currentUser;
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  String? _errorMessage;
  LoginProgress _loginProgress = LoginProgress.idle;
  bool _isDisposed = false;
  StreamSubscription<firebase_auth.User?>? _authStateSubscription;
  bool _isLoggedInOtp = false; // Estado de login via OTP (sem Firebase)
  static const String _isLoggedInKey = 'is_logged_in_otp'; // Chave no SharedPreferences

  // Getters
  firebase_auth.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isBiometricAvailable => _isBiometricAvailable;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null || _isLoggedInOtp; // Login via Firebase OU OTP
  LoginProgress get loginProgress => _loginProgress;
  bool get isDisposed => _isDisposed;

  /// Inicializar controller (otimizado)
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      // 1. Verificar estado de login via OTP no SharedPreferences
      await _loadOtpLoginState();
      
      // 2. Verificar usuário atual do Firebase (para compatibilidade com login antigo)
      _currentUser = AuthService.currentUser;
      AppLogger.debug('AuthController.initialize() - currentUser: ${_currentUser != null}');
      AppLogger.debug('AuthController.initialize() - isLoggedInOtp: $_isLoggedInOtp');
      AppLogger.debug('AuthController.initialize() - isLoggedIn: $isLoggedIn');
      
      // Escutar mudanças de autenticação (apenas para login via Firebase)
      _authStateSubscription = AuthService.authStateChanges.listen((firebase_auth.User? user) {
        if (_isDisposed) {
          AppLogger.warning('AuthController - authStateChanges ignorado - controller disposed');
          return;
        }
        AppLogger.debug('AuthController - authStateChanges RECEBIDO');
        AppLogger.debug('User do evento: ${user != null}');
        AppLogger.debug('currentUser antes: ${_currentUser != null}');
        AppLogger.debug('isLoggedIn antes: $isLoggedIn');
        _currentUser = user;
        AppLogger.debug('currentUser depois: ${_currentUser != null}');
        AppLogger.debug('isLoggedIn depois: $isLoggedIn');
        AppLogger.debug('Chamando notifyListeners()');
        notifyListeners();
        AppLogger.debug('notifyListeners() concluído');
      });
      
      // Verificar disponibilidade biométrica em paralelo (não bloqueia)
      _checkBiometricAvailability();
      
    } catch (e) {
      _setError('Erro ao inicializar: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Carregar estado de login via OTP do SharedPreferences
  Future<void> _loadOtpLoginState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLoggedInOtp = prefs.getBool(_isLoggedInKey) ?? false;
      AppLogger.debug('Estado de login OTP carregado: $_isLoggedInOtp');
    } catch (e) {
      AppLogger.error('Erro ao carregar estado de login OTP', e);
      _isLoggedInOtp = false;
    }
  }

  /// Salvar estado de login via OTP no SharedPreferences
  Future<void> _saveOtpLoginState(bool isLoggedIn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, isLoggedIn);
      _isLoggedInOtp = isLoggedIn;
      AppLogger.debug('Estado de login OTP salvo: $isLoggedIn');
    } catch (e) {
      AppLogger.error('Erro ao salvar estado de login OTP', e);
    }
  }

  /// Verificar disponibilidade biométrica em background
  void _checkBiometricAvailability() async {
    try {
      _isBiometricAvailable = await BiometricService.isAvailable();
      AppLogger.debug('Biometria disponível: $_isBiometricAvailable');
    } catch (e) {
      AppLogger.error('Erro ao verificar biometria', e);
      _isBiometricAvailable = false;
    }
  }

  /// Registrar novo usuário
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
    required String cpf,
    required String phone,
    required String cep,
    required String address,
    required String neighborhood,
    required String city,
    required String state,
    required String number,
    String? complement,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // ==========================================
      // CRIAR USUÁRIO NO FIRESTORE
      // ==========================================
      AppLogger.info('Criando usuário no Firestore...');
      
      // Gerar ID único para o usuário (Firestore gera automaticamente se não fornecido)
      await FirestoreService.createUser(
        email: email,
        fullName: fullName,
        cpf: cpf,
        phone: phone,
        cep: cep,
        address: address,
        neighborhood: neighborhood,
        city: city,
        state: state,
        number: number,
        complement: complement,
      );

      AppLogger.info('Usuário criado no Firestore com sucesso');

      // ==========================================
      // SUCESSO: USUÁRIO CRIADO NO FIRESTORE
      // ==========================================
      // Não usa Firebase Auth - login será feito via OTP
      // Salvar CPF para uso futuro
      await SecureStorageService.saveLastCpf(cpf);
      
      // Marcar como logado (após cadastro, usuário já está logado)
      _isLoggedInOtp = true;
      await _saveOtpLoginState(true);
      
      notifyListeners();
      AppLogger.info('Cadastro completo! Usuário criado no Firestore');
      
      return true;

    } catch (e) {
      AppLogger.error('ERRO NO CADASTRO - NADA FOI GRAVADO', e);
      
      _setError('Erro no cadastro: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login com CPF e senha (otimizado)
  /// 
  /// **REFATORADO**: Agora usa GetUserByCpfUseCase (Clean Architecture)
  Future<bool> loginWithCpf({
    required String cpf,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    _setLoginProgress(LoginProgress.searchingUser);

    try {
      AppLogger.sensitive('Iniciando login otimizado com CPF', cpf);
      
      // 1. Buscar usuário usando UseCase (Clean Architecture)
      final getUserUseCase = await AuthUseCaseFactory.createGetUserByCpfUseCase();
      final result = await getUserUseCase(cpf: cpf);
      
      if (result.isError) {
        throw Exception(result.errorMessage ?? 'Erro ao buscar usuário');
      }
      
      final user = result.dataOrNull;
      if (user == null) {
        throw Exception('CPF não cadastrado');
      }

      final email = user.email;
      AppLogger.info('Usuário encontrado via UseCase');

      // 2. Fazer login no Firebase com email + senha
      _setLoginProgress(LoginProgress.authenticating);
      AppLogger.debug('Fazendo login no Firebase...');
      
      final credential = await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Erro ao fazer login no Firebase');
      }

      _currentUser = credential.user;
      
      // 3. SEMPRE atualizar e recarregar displayName para garantir que está correto
      final userFullName = user.name;
      
      // Salvar CPF após login bem-sucedido (para uso na edição de dados)
      await SecureStorageService.saveLastCpf(cpf);
      AppLogger.debug('CPF salvo no SecureStorage para uso futuro');

      if (userFullName.isNotEmpty) {
        final currentDisplayName = _currentUser?.displayName;
        AppLogger.debug('displayName atual: "$currentDisplayName"');
        AppLogger.debug('displayName esperado: "$userFullName"');
        
        // Verificar se precisa atualizar
        if (currentDisplayName != userFullName) {
          AppLogger.debug('Atualizando displayName...');
          await _currentUser?.updateDisplayName(userFullName);
          await _currentUser?.reload();
          _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
          AppLogger.debug('DisplayName atualizado');
        } else {
          AppLogger.debug('DisplayName já está correto');
        }
        
        // Sempre recarregar o usuário para garantir dados frescos
        await _currentUser?.reload();
        _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      }
      
      // 4. Salvar timestamp do login para otimizações futuras
      await UserCacheService.saveLastLogin();
      
      _setLoginProgress(LoginProgress.success);
      
      AppLogger.info('Login realizado com sucesso!');
      AppLogger.debug('currentUser setado: ${_currentUser != null}');
      AppLogger.debug('isLoggedIn: $isLoggedIn');
      AppLogger.debug('Chamando notifyListeners()...');
      
      // Notificar para atualizar UI
      notifyListeners();
      
      AppLogger.debug('notifyListeners() concluído');
      
      return true;
      
    } catch (e) {
      AppLogger.error('Erro no login', e);
      _setLoginProgress(LoginProgress.error);
      
      // Traduzir erros do Firebase
      String errorMessage = 'Erro no login';
      
      if (e.toString().contains('wrong-password') || 
          e.toString().contains('invalid-credential')) {
        errorMessage = 'Senha incorreta';
      } else if (e.toString().contains('user-not-found')) {
        errorMessage = 'Usuário não encontrado';
      } else if (e.toString().contains('CPF não cadastrado')) {
        errorMessage = 'CPF não cadastrado';
      } else if (e.toString().contains('network') || 
                 e.toString().contains('timeout') ||
                 e.toString().contains('Connection')) {
        errorMessage = 'Erro de conexão. Verifique sua internet.';
      }
      
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login com biometria
  Future<bool> loginWithBiometric() async {
    if (!_isBiometricAvailable) {
      _setError('Biometria não disponível');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      // Autenticar com biometria
      final isAuthenticated = await BiometricService.authenticate(
        reason: 'Use sua biometria para fazer login',
      );

      if (!isAuthenticated) {
        _setError('Autenticação biométrica falhou');
        return false;
      }

      // Aqui você pode implementar lógica para recuperar dados biométricos salvos
      // Por exemplo, buscar CPF salvo localmente e fazer login automático
      
      return true;
    } catch (e) {
      _setError('Erro na autenticação biométrica: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login com OTP (sem Firebase, apenas validação do código)
  /// Após validação do OTP, marca o usuário como logado no SharedPreferences
  /// 
  /// **REFATORADO**: Agora usa GetUserByCpfUseCase (Clean Architecture)
  Future<bool> loginWithOtpMock(String cpf) async {
    _setLoading(true);
    _clearError();
    _setLoginProgress(LoginProgress.searchingUser);

    try {
      AppLogger.sensitive('OTP: Iniciando login com OTP para CPF', cpf);
      
      // 1. Buscar usuário usando UseCase (Clean Architecture)
      final getUserUseCase = await AuthUseCaseFactory.createGetUserByCpfUseCase();
      final result = await getUserUseCase(cpf: cpf);
      
      if (result.isError) {
        throw Exception(result.errorMessage ?? 'Erro ao buscar usuário');
      }
      
      final user = result.dataOrNull;
      if (user == null) {
        throw Exception('CPF não cadastrado');
      }

      AppLogger.info('OTP: Usuário encontrado via UseCase');

      // 2. OTP foi validado na tela anterior, então apenas marcamos como logado
      // Em produção, aqui seria feita a validação do OTP com o backend
      _setLoginProgress(LoginProgress.authenticating);
      
      // 3. Salvar estado de login no SharedPreferences
      await _saveOtpLoginState(true);
      
      // 4. Salvar CPF e timestamp de login
      await SecureStorageService.saveLastCpf(cpf);
      await UserCacheService.saveLastLogin();

      _setLoginProgress(LoginProgress.success);
      
      AppLogger.info('OTP: Login com OTP realizado com sucesso!');
      AppLogger.debug('isLoggedIn: $isLoggedIn');
      
      notifyListeners();
      
      return true;
      
    } catch (e) {
      AppLogger.error('OTP: Erro no login com OTP', e);
      _setLoginProgress(LoginProgress.error);
      
      String errorMessage = 'Erro no login';
      if (e.toString().contains('CPF não cadastrado')) {
        errorMessage = 'CPF não cadastrado';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }
      
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login com Firebase Custom Token (Novo Fluxo CPF-First)
  Future<bool> loginWithCustomToken(String token) async {
    _setLoading(true);
    _clearError();
    _setLoginProgress(LoginProgress.authenticating);

    try {
      AppLogger.info('🔑 Iniciando login com Custom Token...');
      
      // 1. Fazer login no Firebase com o token customizado
      final credential = await firebase_auth.FirebaseAuth.instance.signInWithCustomToken(token);
      
      if (credential.user == null) {
        throw Exception('Falha ao autenticar com token customizado');
      }

      _currentUser = credential.user;
      
      // 2. Salvar estado de login
      await UserCacheService.saveLastLogin();
      
      _setLoginProgress(LoginProgress.success);
      
      AppLogger.info('✅ Login com Custom Token realizado com sucesso!');
      notifyListeners();
      
      return true;
    } catch (e) {
      AppLogger.error('❌ Erro no login com Custom Token', e);
      _setLoginProgress(LoginProgress.error);
      _setError('Erro ao autenticar. Tente novamente.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout
  Future<void> logout() async {
    AppLogger.debug('Iniciando logout...');
    _setLoading(true);
    
    try {
      // 1. Fazer signOut no Firebase (se estiver logado via Firebase)
      if (_currentUser != null) {
        AppLogger.debug('Fazendo signOut no Firebase...');
        await AuthService.signOut();
        _currentUser = null;
      }
      
      // 2. Limpar estado de login via OTP (resetar variável E SharedPreferences)
      AppLogger.debug('Limpando estado de login OTP...');
      _isLoggedInOtp = false; // Resetar variável em memória primeiro
      await _saveOtpLoginState(false); // Depois salvar no SharedPreferences
      
      // 3. Limpar dados locais (cache, secure storage, prefs)
      AppLogger.debug('Limpando dados locais...');
      await _clearLocalData();
      
      // 4. Limpar cache do usuário (memória e local)
      UserHelper.clearCache();
      await UserHelper.clearLocalCache();
      
      AppLogger.debug('Dados locais limpos');

      // 5. Limpar progresso de login
      _loginProgress = LoginProgress.idle;
      _errorMessage = null;

      AppLogger.debug('Verificando estado antes de notificar...');
      AppLogger.debug('currentUser: ${_currentUser != null}');
      AppLogger.debug('isLoggedInOtp: $_isLoggedInOtp');
      AppLogger.debug('isLoggedIn: $isLoggedIn');
      
      AppLogger.debug('Notificando listeners...');
      notifyListeners();
      
      AppLogger.info('Logout realizado com sucesso!');
      AppLogger.debug('currentUser após logout: ${_currentUser != null}');
      AppLogger.debug('isLoggedInOtp após logout: $_isLoggedInOtp');
      AppLogger.debug('isLoggedIn após logout: $isLoggedIn');
    } catch (e) {
      AppLogger.error('Erro no logout', e);
      _setError('Erro ao fazer logout: $e');
      // Garantir que mesmo em caso de erro, limpamos o estado
      _currentUser = null;
      _isLoggedInOtp = false; // Garantir reset da variável
      _loginProgress = LoginProgress.idle;
      try {
        await _saveOtpLoginState(false); // Tentar salvar mesmo em caso de erro
      } catch (_) {
        // Ignorar erro ao salvar, mas garantir que a variável está resetada
      }
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Limpar todos os dados locais do usuário
  Future<void> _clearLocalData() async {
    try {
      // Limpar cache do usuário
      await UserCacheService.clearCache();
      AppLogger.debug('Cache do usuário limpo');
      
      // Limpar todos os dados sensíveis do secure storage
      await SecureStorageService.clearAll();
      AppLogger.debug('Dados sensíveis limpos');
      
      // Limpar dados do SharedPreferences (incluindo estado de login OTP)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
      await prefs.remove(_isLoggedInKey); // Limpar estado de login OTP
      // Garantir que a variável em memória também está resetada
      _isLoggedInOtp = false;
      AppLogger.debug('SharedPreferences limpo (incluindo estado de login OTP)');
      AppLogger.debug('Variável _isLoggedInOtp resetada para: $_isLoggedInOtp');
      
    } catch (e) {
      AppLogger.error('Erro ao limpar dados locais', e);
      // Mesmo em caso de erro, garantir que a variável está resetada
      _isLoggedInOtp = false;
    }
  }

  /// Redefinir senha por email
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.resetPassword(email);
      return true;
    } catch (e) {
      _setError('Erro ao redefinir senha: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Redefinir senha usando CPF (busca email no PostgreSQL)
  /// 
  /// **REFATORADO**: Agora usa GetUserByCpfUseCase (Clean Architecture)
  Future<bool> resetPasswordByCpf(String cpf) async {
    _setLoading(true);
    _clearError();

    try {
      AppLogger.sensitive('Iniciando recuperação de senha com CPF', cpf);

      // 1. Buscar usuário usando UseCase (Clean Architecture)
      final getUserUseCase = await AuthUseCaseFactory.createGetUserByCpfUseCase();
      final result = await getUserUseCase(cpf: cpf);

      if (result.isError) {
        throw Exception(result.errorMessage ?? 'Erro ao buscar usuário');
      }

      final user = result.dataOrNull;
      if (user == null) {
        throw Exception('CPF não cadastrado');
      }

      final email = user.email;
      AppLogger.info('Email encontrado via UseCase');

      // 2. Enviar email de redefinição de senha via Firebase
      AppLogger.debug('Enviando email de redefinição de senha...');
      await AuthService.resetPassword(email);

      AppLogger.info('Email de redefinição enviado com sucesso!');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao recuperar senha', e);
      
      // Traduzir erros
      String errorMessage = 'Erro ao recuperar senha';
      
      if (e.toString().contains('CPF não cadastrado')) {
        errorMessage = 'CPF não cadastrado no sistema';
      } else if (e.toString().contains('user-not-found')) {
        errorMessage = 'Email não encontrado no Firebase';
      } else if (e.toString().contains('network') || 
                 e.toString().contains('timeout') ||
                 e.toString().contains('Connection')) {
        errorMessage = 'Erro de conexão. Verifique sua internet.';
      } else {
        errorMessage = 'Erro ao enviar email de recuperação: $e';
      }
      
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verificar se email está verificado
  bool get isEmailVerified => AuthService.isEmailVerified;

  /// Reenviar email de verificação
  Future<void> sendEmailVerification() async {
    try {
      await AuthService.sendEmailVerification();
    } catch (e) {
      _setError('Erro ao enviar verificação: $e');
    }
  }

  /// Atualizar perfil do usuário
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? personalData,
    Map<String, dynamic>? addressData,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Atualizar no Firebase
      await AuthService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
      );

      // Atualizar no PostgreSQL (se houver dados)
      if (personalData != null || addressData != null) {
        // Aqui você precisaria do ID do usuário no PostgreSQL
        // await DatabaseService.updateUser(
        //   userId: _currentUser?.uid ?? '',
        //   personalData: personalData,
        //   addressData: addressData,
        // );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao atualizar perfil: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Métodos auxiliares
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoginProgress(LoginProgress progress) {
    _loginProgress = progress;
    notifyListeners();
  }

  /// Limpar estado
  void clearState() {
    _currentUser = null;
    _isLoading = false;
    _errorMessage = null;
    _loginProgress = LoginProgress.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authStateSubscription?.cancel();
    _authStateSubscription = null;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}

