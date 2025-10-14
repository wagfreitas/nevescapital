import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:neves_capital/shared/services/auth_service.dart';
import 'package:neves_capital/shared/services/database_service.dart';
import 'package:neves_capital/shared/services/biometric_service.dart';

/// Controller para gerenciar autenticação real (Firebase + PostgreSQL)
class AuthController extends ChangeNotifier {
  firebase_auth.User? _currentUser;
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  String? _errorMessage;

  // Getters
  firebase_auth.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isBiometricAvailable => _isBiometricAvailable;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  /// Inicializar controller
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      // Verificar disponibilidade biométrica
      _isBiometricAvailable = await BiometricService.isAvailable();
      
      // Verificar usuário atual do Firebase
      _currentUser = AuthService.currentUser;
      
      // Escutar mudanças de autenticação
      AuthService.authStateChanges.listen((firebase_auth.User? user) {
        _currentUser = user;
        notifyListeners();
      });
      
    } catch (e) {
      _setError('Erro ao inicializar: $e');
    } finally {
      _setLoading(false);
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
      // 1. Criar conta no Firebase
      final credential = await AuthService.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Falha ao criar conta no Firebase');
      }

      // 2. Salvar dados no PostgreSQL
      await DatabaseService.createUser(
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

      _currentUser = credential.user;
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError('Erro no cadastro: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Login com CPF e senha
  Future<bool> loginWithCpf({
    required String cpf,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // 1. Buscar usuário no PostgreSQL pelo CPF
      final userData = await DatabaseService.getUserByCpf(cpf);
      
      if (userData == null) {
        throw Exception('Usuário não encontrado');
      }

      // 2. Verificar senha
      final isPasswordValid = await DatabaseService.verifyPassword(cpf, password);
      
      if (!isPasswordValid) {
        throw Exception('Senha incorreta');
      }

      // 3. Fazer login no Firebase com email
      final credential = await AuthService.signInWithEmailAndPassword(
        email: userData['email'],
        password: password,
      );

      _currentUser = credential.user;
      notifyListeners();
      
      return true;
    } catch (e) {
      _setError('Erro no login: $e');
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
    _setLoading(true);
    
    try {
      await AuthService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Erro ao fazer logout: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Redefinir senha
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

  /// Limpar estado
  void clearState() {
    _currentUser = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
