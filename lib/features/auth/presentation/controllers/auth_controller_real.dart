import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neves_capital/shared/services/auth_service.dart';
import 'package:neves_capital/shared/services/database_service.dart';
import 'package:neves_capital/shared/services/biometric_service.dart';
import 'package:neves_capital/shared/services/user_cache_service.dart';
import 'package:neves_capital/shared/services/secure_storage_service.dart';

/// Estados de progresso do login
enum LoginProgress {
  idle,
  searchingUser,
  authenticating,
  success,
  error,
}

/// Controller para gerenciar autenticação real (Firebase + PostgreSQL)
class AuthController extends ChangeNotifier {
  firebase_auth.User? _currentUser;
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  String? _errorMessage;
  LoginProgress _loginProgress = LoginProgress.idle;
  bool _isDisposed = false;
  StreamSubscription<firebase_auth.User?>? _authStateSubscription;

  // Getters
  firebase_auth.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isBiometricAvailable => _isBiometricAvailable;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  LoginProgress get loginProgress => _loginProgress;
  bool get isDisposed => _isDisposed;

  /// Inicializar controller (otimizado)
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      // Verificar usuário atual do Firebase primeiro (mais rápido)
      _currentUser = AuthService.currentUser;
      print('🔍 AuthController.initialize() - _currentUser: ${_currentUser?.uid}');
      print('🔍 AuthController.initialize() - isLoggedIn: $isLoggedIn');
      
      // Escutar mudanças de autenticação
      _authStateSubscription = AuthService.authStateChanges.listen((firebase_auth.User? user) {
        if (_isDisposed) {
          print('⚠️ AuthController - authStateChanges ignorado - controller disposed');
          return;
        }
        print('');
        print('🔥 AuthController - authStateChanges RECEBIDO');
        print('🔥 User do evento: ${user?.uid}');
        print('🔥 _currentUser antes: ${_currentUser?.uid}');
        print('🔥 isLoggedIn antes: $isLoggedIn');
        _currentUser = user;
        print('🔥 _currentUser depois: ${_currentUser?.uid}');
        print('🔥 isLoggedIn depois: $isLoggedIn');
        print('🔥 Chamando notifyListeners()');
        notifyListeners();
        print('🔥 notifyListeners() concluído');
        print('');
      });
      
      // Verificar disponibilidade biométrica em paralelo (não bloqueia)
      _checkBiometricAvailability();
      
    } catch (e) {
      _setError('Erro ao inicializar: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Verificar disponibilidade biométrica em background
  void _checkBiometricAvailability() async {
    try {
      _isBiometricAvailable = await BiometricService.isAvailable();
      print('🔍 Biometria disponível: $_isBiometricAvailable');
    } catch (e) {
      print('❌ Erro ao verificar biometria: $e');
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

    String? postgresUserId;
    firebase_auth.User? firebaseUser;

    try {
      // ==========================================
      // ETAPA 1: GRAVAR NO POSTGRESQL PRIMEIRO
      // ==========================================
      print('📝 Etapa 1: Criando usuário no PostgreSQL...');
      
      final postgresResult = await DatabaseService.createUser(
        email: email,
        password: password,
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

      // ==========================================
      // VALIDAÇÃO CRÍTICA: VERIFICAR SE POSTGRESQL FOI CRIADO
      // ==========================================
      if (postgresResult['success'] != true || postgresResult['user_id'] == null) {
        throw Exception('Falha ao criar usuário no PostgreSQL. Resposta inválida.');
      }

      postgresUserId = postgresResult['user_id'] as String;
      print('✅ Usuário criado no PostgreSQL: $postgresUserId');

      // ==========================================
      // ETAPA 2: GRAVAR NO FIREBASE (SOMENTE SE POSTGRESQL OK)
      // ==========================================
      print('');
      print('✅ PostgreSQL confirmado! Prosseguindo para Firebase...');
      print('📝 Etapa 2: Criando usuário no Firebase...');
      print('⚠️  ATENÇÃO: Se você está vendo esta mensagem e a API estava desligada,');
      print('⚠️  significa que há um problema no fluxo do código!');
      print('');
      
      try {
        final credential = await AuthService.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (credential.user == null) {
          throw Exception('Falha ao criar conta no Firebase');
        }

        firebaseUser = credential.user;
        print('✅ Usuário criado no Firebase: ${firebaseUser?.uid}');

        // Atualizar displayName no Firebase
        await firebaseUser?.updateDisplayName(fullName);
        await firebaseUser?.reload();
        firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
        print('✅ DisplayName atualizado: $fullName');

        // ==========================================
        // SUCESSO: AMBOS OS BANCOS SINCRONIZADOS
        // ==========================================
        _currentUser = firebaseUser;
        notifyListeners();
        print('✅ Cadastro completo! Usuário em PostgreSQL e Firebase');
        
        return true;

      } catch (firebaseError) {
        // ==========================================
        // ROLLBACK: DELETAR DO POSTGRESQL
        // ==========================================
        print('❌ Erro ao criar no Firebase: $firebaseError');
        print('🔄 ROLLBACK: Deletando usuário do PostgreSQL...');
        
        try {
          await DatabaseService.deleteUser(postgresUserId);
          print('✅ Rollback concluído - Usuário removido do PostgreSQL');
        } catch (deleteError) {
          print('❌ ERRO CRÍTICO: Falha no rollback! Usuário órfão no PostgreSQL: $postgresUserId');
          print('❌ Erro do rollback: $deleteError');
        }

        throw Exception('Erro ao criar no Firebase: $firebaseError');
      }

    } catch (e) {
      print('');
      print('═══════════════════════════════════════════════');
      print('❌ ERRO NO CADASTRO - NADA FOI GRAVADO');
      print('═══════════════════════════════════════════════');
      print('Erro: $e');
      print('PostgreSQL foi criado? ${postgresUserId != null ? "SIM (ID: $postgresUserId)" : "NÃO"}');
      print('Firebase foi criado? ${firebaseUser != null ? "SIM (UID: ${firebaseUser.uid})" : "NÃO"}');
      print('═══════════════════════════════════════════════');
      print('');
      
      _setError('Erro no cadastro: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login com CPF e senha (otimizado)
  Future<bool> loginWithCpf({
    required String cpf,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    _setLoginProgress(LoginProgress.searchingUser);

    try {
      print('🔐 Iniciando login otimizado com CPF: $cpf');
      
      // 1. Buscar usuário (com cache otimizado)
      final userData = await DatabaseService.getUserByCpf(cpf);
      
      if (userData == null) {
        throw Exception('CPF não cadastrado');
      }

      final email = userData['email'] as String;
      final mode = userData['mode'] as String?;
      print('✅ Usuário encontrado: $email (${mode ?? 'API'})');

      // 2. Fazer login no Firebase com email + senha
      _setLoginProgress(LoginProgress.authenticating);
      print('🔐 Fazendo login no Firebase...');
      
      final credential = await AuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Erro ao fazer login no Firebase');
      }

      _currentUser = credential.user;
      
      // 3. SEMPRE atualizar e recarregar displayName para garantir que está correto
      final userFullName = userData['name'] as String?;
      
      if (userFullName != null && userFullName.isNotEmpty) {
        final currentDisplayName = _currentUser?.displayName;
        print('📝 displayName atual: "$currentDisplayName"');
        print('📝 displayName esperado: "$userFullName"');
        
        // Verificar se precisa atualizar
        if (currentDisplayName != userFullName) {
          print('📝 Atualizando displayName...');
          await _currentUser?.updateDisplayName(userFullName);
          await _currentUser?.reload();
          _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
          print('✅ DisplayName atualizado para: ${_currentUser?.displayName}');
        } else {
          print('✅ DisplayName já está correto');
        }
        
        // Sempre recarregar o usuário para garantir dados frescos
        await _currentUser?.reload();
        _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      }
      
      // 4. Salvar timestamp do login para otimizações futuras
      await UserCacheService.saveLastLogin();
      
      _setLoginProgress(LoginProgress.success);
      
      print('');
      print('✅✅✅ Login realizado com sucesso! ✅✅✅');
      print('✅ _currentUser setado: ${_currentUser?.uid}');
      print('✅ isLoggedIn: $isLoggedIn');
      print('✅ Chamando notifyListeners()...');
      
      // Notificar para atualizar UI
      notifyListeners();
      
      print('✅ notifyListeners() concluído');
      print('');
      
      return true;
      
    } catch (e) {
      print('❌ Erro no login: $e');
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

  /// Logout
  Future<void> logout() async {
    print('🔐 Iniciando logout...');
    _setLoading(true);
    
    try {
      print('🔐 Fazendo signOut no Firebase...');
      await AuthService.signOut();
      
      print('🔐 Limpando _currentUser...');
      _currentUser = null;
      
      // Limpar dados locais (cache, secure storage, prefs)
      print('🔐 Limpando dados locais...');
      await _clearLocalData();
      print('🔐 Dados locais limpos');

      // Limpar progresso de login
      _loginProgress = LoginProgress.idle;
      _errorMessage = null;

      print('🔐 Notificando listeners...');
      notifyListeners();
      
      print('✅ Logout realizado com sucesso!');
      print('✅ _currentUser após logout: $_currentUser');
      print('✅ isLoggedIn após logout: $isLoggedIn');
    } catch (e) {
      print('❌ Erro no logout: $e');
      _setError('Erro ao fazer logout: $e');
      // Garantir que mesmo em caso de erro, limpamos o estado
      _currentUser = null;
      _loginProgress = LoginProgress.idle;
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
      print('🗑️ Cache do usuário limpo');
      
      // Limpar todos os dados sensíveis do secure storage
      await SecureStorageService.clearAll();
      print('🗑️ Dados sensíveis limpos');
      
      // Limpar dados do SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
      print('🗑️ SharedPreferences limpo');
      
    } catch (e) {
      print('❌ Erro ao limpar dados locais: $e');
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
  Future<bool> resetPasswordByCpf(String cpf) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔐 Iniciando recuperação de senha com CPF: $cpf');

      // 1. Buscar usuário por CPF no PostgreSQL
      final userData = await DatabaseService.getUserByCpf(cpf);

      if (userData == null) {
        throw Exception('CPF não cadastrado');
      }

      final email = userData['email'] as String;
      print('✅ Email encontrado: $email');

      // 2. Enviar email de redefinição de senha via Firebase
      print('📧 Enviando email de redefinição de senha...');
      await AuthService.resetPassword(email);

      print('✅ Email de redefinição enviado com sucesso!');
      return true;
    } catch (e) {
      print('❌ Erro ao recuperar senha: $e');
      
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
