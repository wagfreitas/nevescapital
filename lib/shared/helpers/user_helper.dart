import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Helper para obter usuário atual com cache local
/// Prioridade: AuthController (memória) > SharedPreferences (cache) > Firebase
class UserHelper {
  static firebase_auth.User? _cachedUser;
  static DateTime? _cacheTimestamp;
  static const int _cacheExpiryMinutes = 5; // Cache válido por 5 minutos

  /// Obter usuário atual (com cache)
  /// Retorna null se não encontrar
  static Future<firebase_auth.User?> getCurrentUser({
    firebase_auth.User? fromAuthController,
  }) async {
    // 1. Prioridade: Usuário do AuthController (memória)
    if (fromAuthController != null) {
      _cacheUser(fromAuthController);
      return fromAuthController;
    }

    // 2. Tentar cache em memória (válido por 5 minutos)
    if (_cachedUser != null && _cacheTimestamp != null) {
      final age = DateTime.now().difference(_cacheTimestamp!);
      if (age.inMinutes < _cacheExpiryMinutes) {
        print('✅ Usuário obtido do cache em memória');
        return _cachedUser;
      } else {
        // Cache expirado, limpar
        _cachedUser = null;
        _cacheTimestamp = null;
      }
    }

    // 3. Tentar cache local (SharedPreferences)
    final cachedUserData = await _getCachedUserFromStorage();
    if (cachedUserData != null) {
      final user = await _reconstructUserFromCache(cachedUserData);
      if (user != null) {
        _cacheUser(user);
        print('✅ Usuário obtido do cache local');
        return user;
      }
    }

    // 4. Último recurso: Buscar do Firebase (mas cacheia depois)
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _cacheUser(firebaseUser);
        await _saveUserToCache(firebaseUser);
        print('✅ Usuário obtido do Firebase e cacheado');
      }
      return firebaseUser;
    } catch (e) {
      print('❌ Erro ao buscar usuário do Firebase: $e');
      return null;
    }
  }

  /// Cachear usuário em memória
  static void _cacheUser(firebase_auth.User user) {
    _cachedUser = user;
    _cacheTimestamp = DateTime.now();
  }

  /// Salvar usuário no cache local (SharedPreferences)
  static Future<void> _saveUserToCache(firebase_auth.User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString('cached_firebase_user', jsonEncode(userData));
      print('💾 Usuário salvo no cache local');
    } catch (e) {
      print('❌ Erro ao salvar usuário no cache: $e');
    }
  }

  /// Obter usuário do cache local
  static Future<Map<String, dynamic>?>                                                                                                                      _getCachedUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_firebase_user');
      if (cachedData == null) return null;

      final userData = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = userData['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      final ageMinutes = age / (1000 * 60);

      // Verificar se cache não expirou (5 minutos)
      if (ageMinutes < _cacheExpiryMinutes) {
        return userData;
      } else {
        // Cache expirado, limpar
        await prefs.remove('cached_firebase_user');
        return null;
      }
    } catch (e) {
      print('❌ Erro ao ler cache local: $e');
      return null;
    }
  }

  /// Reconstruir objeto User do cache (simulado, pois não podemos recriar o objeto real)
  /// Retorna null pois precisamos do objeto real do Firebase
  /// Mas podemos retornar os dados para uso
  static Future<firebase_auth.User?> _reconstructUserFromCache(
      Map<String, dynamic> userData) async {
    // Não podemos reconstruir o objeto User do Firebase
    // Mas podemos validar se o usuário ainda existe no Firebase
    try {
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null && firebaseUser.uid == userData['uid']) {
        return firebaseUser;
      }
    } catch (e) {
      print('⚠️ Erro ao validar usuário do cache: $e');
    }
    return null;
  }

  /// Limpar cache do usuário
  static void clearCache() {
    _cachedUser = null;
    _cacheTimestamp = null;
  }

  /// Limpar cache local (SharedPreferences)
  static Future<void> clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_firebase_user');
      print('🗑️ Cache local limpo');
    } catch (e) {
      print('❌ Erro ao limpar cache local: $e');
    }
  }
}

