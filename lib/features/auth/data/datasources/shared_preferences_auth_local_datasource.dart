import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/result.dart';
import '../models/user_model.dart';
import 'auth_local_datasource.dart';

class SharedPreferencesAuthLocalDataSource implements AuthLocalDataSource {
  SharedPreferencesAuthLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  @override
  Future<Result<void>> saveToken(String token) async {
    final saved = await _prefs.setString(_tokenKey, token);
    if (!saved) {
      return const Error(message: 'Não foi possível salvar o token');
    }
    return const Success(null);
  }

  @override
  Future<Result<String?>> getToken() async {
    final token = _prefs.getString(_tokenKey);
    return Success(token);
  }

  @override
  Future<Result<void>> removeToken() async {
    await _prefs.remove(_tokenKey);
    return const Success(null);
  }

  @override
  Future<Result<void>> saveUser(UserModel user) async {
    final saved = await _prefs.setString(_userKey, jsonEncode(user.toJson()));
    if (!saved) {
      return const Error(message: 'Não foi possível salvar o usuário');
    }
    return const Success(null);
  }

  @override
  Future<Result<UserModel?>> getUser() async {
    final data = _prefs.getString(_userKey);
    if (data == null) {
      return const Success(null);
    }

    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return Success(UserModel.fromJson(json));
    } catch (_) {
      await _prefs.remove(_userKey);
      return const Error(message: 'Erro ao recuperar dados do usuário local');
    }
  }

  @override
  Future<Result<void>> removeUser() async {
    await _prefs.remove(_userKey);
    return const Success(null);
  }

  @override
  Future<Result<bool>> hasToken() async {
    return Success(_prefs.containsKey(_tokenKey));
  }
}
