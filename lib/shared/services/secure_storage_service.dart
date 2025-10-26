import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço de armazenamento seguro
/// 
/// Implementa MASVS-STORAGE-1 e MASVS-STORAGE-2:
/// - Dados sensíveis criptografados no dispositivo
/// - Usa Keychain (iOS) e KeyStore (Android)
/// - Proteção contra backup não criptografado
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      // MASVS-STORAGE-2: Proteção adicional no Android
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      // MASVS-STORAGE-1: Usa Keychain no iOS
      accessibility: KeychainAccessibility.first_unlock_this_device,
      synchronizable: false, // Não sincronizar com iCloud por segurança
    ),
  );

  // Keys para dados sensíveis
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserEmail = 'user_email';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyLastCpf = 'last_cpf'; // Para facilitar login
  
  /// Salvar token de autenticação
  /// MASVS-AUTH-1: Token armazenado de forma segura
  static Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _keyAuthToken, value: token);
  }

  /// Obter token de autenticação
  static Future<String?> getAuthToken() async {
    return await _storage.read(key: _keyAuthToken);
  }

  /// Remover token de autenticação
  static Future<void> removeAuthToken() async {
    await _storage.delete(key: _keyAuthToken);
  }

  /// Salvar ID do usuário
  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  /// Obter ID do usuário
  static Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  /// Salvar email do usuário
  static Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _keyUserEmail, value: email);
  }

  /// Obter email do usuário
  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  /// Salvar último CPF usado (para facilitar login)
  /// Nota: CPF não é dado altamente sensível, mas deve ser protegido
  static Future<void> saveLastCpf(String cpf) async {
    await _storage.write(key: _keyLastCpf, value: cpf);
  }

  /// Obter último CPF usado
  static Future<String?> getLastCpf() async {
    return await _storage.read(key: _keyLastCpf);
  }

  /// Verificar se biometria está habilitada
  static Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Habilitar/desabilitar biometria
  static Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(
      key: _keyBiometricEnabled,
      value: enabled.toString(),
    );
  }

  /// Limpar todos os dados sensíveis
  /// MASVS-AUTH-2: Logout seguro
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Verificar se usuário está autenticado
  static Future<bool> hasAuthToken() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Salvar múltiplos valores de uma vez
  static Future<void> saveUserSession({
    required String token,
    required String userId,
    required String email,
  }) async {
    await Future.wait([
      saveAuthToken(token),
      saveUserId(userId),
      saveUserEmail(email),
    ]);
  }

  /// Obter todos os dados da sessão
  static Future<Map<String, String?>> getUserSession() async {
    final results = await Future.wait([
      getAuthToken(),
      getUserId(),
      getUserEmail(),
    ]);

    return {
      'token': results[0],
      'userId': results[1],
      'email': results[2],
    };
  }
}

