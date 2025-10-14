import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/result.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

/// Implementação remota usando Firebase Auth + API protegida
class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource({
    firebase_auth.FirebaseAuth? firebaseAuth,
    http.Client? httpClient,
    String? baseUrl,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _client = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final http.Client _client;
  final String _baseUrl;

  @override
  Future<Result<RemoteAuthSession>> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return const Error(message: 'Usuário não encontrado');
      }

      final idToken = await user.getIdToken();
      if (idToken == null) {
        return const Error(message: 'Token de sessão indisponível');
      }
      final profileResult = await _fetchCurrentUser(idToken);
      if (profileResult.isError) {
        return Error(message: profileResult.errorMessage ?? 'Erro ao sincronizar usuário');
      }

      return Success(RemoteAuthSession(
        user: profileResult.dataOrNull!,
        idToken: idToken,
      ));
    } on firebase_auth.FirebaseAuthException catch (error) {
      return Error(message: _mapFirebaseError(error));
    } catch (error) {
      return Error(message: 'Erro inesperado ao fazer login: $error');
    }
  }

  @override
  Future<Result<RemoteAuthSession>> register({
    required String email,
    required String password,
    required String name,
    String? phone,
    String? document,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        return const Error(message: 'Não foi possível criar usuário');
      }

      await user.updateDisplayName(name);
      final idToken = await user.getIdToken();
      if (idToken == null) {
        return const Error(message: 'Token de sessão indisponível');
      }

      final response = await _client.post(
        Uri.parse('$_baseUrl/users'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'document': document,
        }),
      );

      if (response.statusCode >= 400) {
        final message = _parseErrorMessage(response.body) ?? 'Erro ao criar perfil';
        return Error(message: message);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final userModel = UserModel.fromJson(json);

      return Success(RemoteAuthSession(user: userModel, idToken: idToken));
    } on firebase_auth.FirebaseAuthException catch (error) {
      return Error(message: _mapFirebaseError(error));
    } catch (error) {
      return Error(message: 'Erro inesperado ao registrar: $error');
    }
  }

  @override
  Future<Result<UserModel>> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return const Error(message: 'Usuário não autenticado');
    }

    final idToken = await user.getIdToken();
    if (idToken == null) {
      return const Error(message: 'Token de sessão indisponível');
    }
    return _fetchCurrentUser(idToken);
  }

  @override
  Future<Result<UserModel>> updateProfile({
    required String name,
    String? phone,
    String? avatar,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      return const Error(message: 'Usuário não autenticado');
    }

    try {
      await user.updateDisplayName(name);
      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        return const Error(message: 'Token de sessão indisponível');
      }
      final response = await _client.put(
        Uri.parse('$_baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
          'avatar': avatar,
        }),
      );

      if (response.statusCode >= 400) {
        final message = _parseErrorMessage(response.body) ?? 'Erro ao atualizar perfil';
        return Error(message: message);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Success(UserModel.fromJson(json));
    } catch (error) {
      return Error(message: 'Erro inesperado ao atualizar perfil: $error');
    }
  }

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      return const Error(message: 'Usuário não autenticado');
    }

    try {
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return const Success(null);
    } on firebase_auth.FirebaseAuthException catch (error) {
      return Error(message: _mapFirebaseError(error));
    } catch (error) {
      return Error(message: 'Erro ao alterar senha: $error');
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _firebaseAuth.signOut();
      return const Success(null);
    } catch (error) {
      return Error(message: 'Erro ao finalizar sessão: $error');
    }
  }

  Future<Result<UserModel>> _fetchCurrentUser(String idToken) async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode >= 400) {
        final message = _parseErrorMessage(response.body) ?? 'Erro ao sincronizar usuário';
        return Error(message: message);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return Success(UserModel.fromJson(json));
    } catch (error) {
      return Error(message: 'Erro ao carregar usuário: $error');
    }
  }

  String _mapFirebaseError(firebase_auth.FirebaseAuthException exception) {
    switch (exception.code) {
      case 'invalid-email':
        return 'Email inválido';
      case 'user-disabled':
        return 'Usuário desativado';
      case 'user-not-found':
        return 'Usuário não encontrado';
      case 'wrong-password':
        return 'Credenciais inválidas';
      case 'email-already-in-use':
        return 'Email já está em uso';
      case 'weak-password':
        return 'Senha muito fraca';
      default:
        return exception.message ?? 'Erro de autenticação';
    }
  }

  String? _parseErrorMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
