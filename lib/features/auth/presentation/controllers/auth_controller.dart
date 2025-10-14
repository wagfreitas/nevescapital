import 'package:flutter/material.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/services/biometric_service.dart';

/// Controller para gerenciar o estado da autenticação
class AuthController extends ChangeNotifier {
  AuthController({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required LogoutUseCase logoutUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        _getCurrentUserUseCase = getCurrentUserUseCase,
        _logoutUseCase = logoutUseCase;
  
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final LogoutUseCase _logoutUseCase;
  
  // Estado da autenticação
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isBiometricAvailable = false;
  
  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  bool get isBiometricAvailable => _isBiometricAvailable;
  
  /// Faz login do usuário
  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    
    final result = await _loginUseCase(
      email: email,
      password: password,
    );
    
    if (result.isSuccess) {
      _currentUser = result.dataOrNull;
      notifyListeners();
    } else {
      _setError(result.errorMessage ?? 'Erro ao fazer login');
    }
    
    _setLoading(false);
  }
  
  /// Faz logout do usuário
  Future<void> logout() async {
    _setLoading(true);
    _clearError();

    final result = await _logoutUseCase();
    if (result.isError) {
      _setError(result.errorMessage ?? 'Erro ao encerrar sessão');
    }

    _currentUser = null;
    _setLoading(false);
  }

  /// Registra novo usuário
  Future<void> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? document,
  }) async {
    _setLoading(true);
    _clearError();

    final result = await _registerUseCase(
      email: email,
      password: password,
      name: name,
      phone: phone,
      document: document,
    );

    if (result.isSuccess) {
      _currentUser = result.dataOrNull;
      notifyListeners();
    } else {
      _setError(result.errorMessage ?? 'Erro ao cadastrar usuário');
    }

    _setLoading(false);
  }

  /// Inicializa o controller e verifica disponibilidade biométrica
  Future<void> initialize() async {
    _isBiometricAvailable = await BiometricService.isAvailable();
    await _loadCurrentUser();
    notifyListeners();
  }

  Future<void> _loadCurrentUser() async {
    final result = await _getCurrentUserUseCase();
    if (result.isSuccess) {
      _currentUser = result.dataOrNull;
    }
  }

  /// Realiza login com autenticação biométrica
  Future<void> loginWithBiometric() async {
    _setLoading(true);
    _clearError();
    
    try {
      final bool authenticated = await BiometricService.authenticate(
        reason: 'Use sua biometria para fazer login no Pag Pag',
      );
      
      if (authenticated) {
        await _loadCurrentUser();
        if (_currentUser == null) {
          _setError('Nenhum usuário encontrado para login biométrico');
        } else {
          notifyListeners();
        }
      } else {
        _setError('Autenticação biométrica cancelada ou falhou');
      }
    } catch (e) {
      _setError('Erro na autenticação biométrica: $e');
    }
    
    _setLoading(false);
  }
  
  /// Define estado de carregamento
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// Define mensagem de erro
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }
  
  /// Limpa mensagem de erro
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
