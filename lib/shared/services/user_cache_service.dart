import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço para cache local de dados do usuário
class UserCacheService {
  static const String _cpfEmailKey = 'user_cpf_email_cache';
  static const String _lastLoginKey = 'last_login_timestamp';
  static const int _cacheExpiryHours = 24; // Cache válido por 24 horas

  /// Salvar email do usuário no cache local
  static Future<void> cacheUserEmail(String cpf, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'cpf': cpf,
        'email': email,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(_cpfEmailKey, jsonEncode(cacheData));
      print('💾 Email cacheado para CPF: $cpf');
    } catch (e) {
      print('❌ Erro ao salvar cache: $e');
    }
  }

  /// Buscar email do usuário no cache local
  static Future<String?> getCachedEmail(String cpf) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cpfEmailKey);
      
      if (cachedData == null) return null;
      
      final data = jsonDecode(cachedData);
      final cachedCpf = data['cpf'] as String;
      final email = data['email'] as String;
      final timestamp = data['timestamp'] as int;
      
      // Verificar se é o mesmo CPF e se o cache não expirou
      if (cachedCpf == cpf) {
        final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
        final cacheAgeHours = cacheAge / (1000 * 60 * 60);
        
        if (cacheAgeHours < _cacheExpiryHours) {
          print('✅ Email encontrado no cache: $email');
          return email;
        } else {
          print('⏰ Cache expirado, removendo...');
          await clearCache();
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Erro ao ler cache: $e');
      return null;
    }
  }

  /// Limpar cache do usuário
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cpfEmailKey);
      await prefs.remove(_lastLoginKey);
      print('🗑️ Cache limpo');
    } catch (e) {
      print('❌ Erro ao limpar cache: $e');
    }
  }

  /// Salvar timestamp do último login
  static Future<void> saveLastLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastLoginKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('❌ Erro ao salvar último login: $e');
    }
  }

  /// Verificar se o usuário fez login recentemente
  static Future<bool> hasRecentLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastLogin = prefs.getInt(_lastLoginKey);
      
      if (lastLogin == null) return false;
      
      final timeSinceLogin = DateTime.now().millisecondsSinceEpoch - lastLogin;
      final hoursSinceLogin = timeSinceLogin / (1000 * 60 * 60);
      
      return hoursSinceLogin < 1; // Login recente se foi há menos de 1 hora
    } catch (e) {
      print('❌ Erro ao verificar último login: $e');
      return false;
    }
  }
}
