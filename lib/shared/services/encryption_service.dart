import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Serviço de criptografia para dados sensíveis
/// 
/// Implementa AES-256-GCM para criptografia de dados sensíveis antes de salvar no Firestore
/// 
/// **IMPORTANTE:** Firestore não tem criptografia nativa de campo.
/// Dados sensíveis (CPF, telefone, email) devem ser criptografados antes de salvar.
class EncryptionService {
  // Chave de criptografia (deve ser de 32 bytes para AES-256)
  // Em produção, deve vir de variável de ambiente ou Remote Config
  static const String _defaultKey = 'your-32-character-secret-key!'; // ⚠️ TROCAR EM PRODUÇÃO
  
  // Storage seguro para chave
  static const _storage = FlutterSecureStorage();
  static const String _keyEncryptionKey = 'encryption_key';

  /// Obter chave de criptografia
  /// Prioridade: SecureStorage > Default
  static Future<String> _getEncryptionKey() async {
    try {
      final storedKey = await _storage.read(key: _keyEncryptionKey);
      if (storedKey != null && storedKey.isNotEmpty) {
        return storedKey;
      }
    } catch (e) {
      AppLogger.warning('Erro ao ler chave do storage');
    }
    
    // Retornar chave padrão (não recomendado para produção)
    return _defaultKey;
  }

  /// Salvar chave de criptografia de forma segura
  static Future<void> setEncryptionKey(String key) async {
    if (key.length < 32) {
      throw ArgumentError('Chave deve ter pelo menos 32 caracteres');
    }
    await _storage.write(key: _keyEncryptionKey, value: key);
  }

  /// Criptografar dados sensíveis usando AES-256-CBC
  /// 
  /// Retorna string criptografada em base64
  /// 
  /// Exemplo de uso:
  /// ```dart
  /// final encrypted = await EncryptionService.encrypt('12345678900');
  /// ```
  static Future<String> encrypt(String plaintext) async {
    if (plaintext.isEmpty) {
      throw ArgumentError('Texto não pode ser vazio');
    }

    try {
      final keyString = await _getEncryptionKey();
      final key = Key.fromBase64(base64Encode(utf8.encode(keyString.padRight(32).substring(0, 32))));
      final iv = IV.fromSecureRandom(16);

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final encrypted = encrypter.encrypt(plaintext, iv: iv);

      // Combinar IV + dados criptografados (IV:encrypted)
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      AppLogger.error('Erro ao criptografar', e);
      rethrow;
    }
  }

  /// Descriptografar dados sensíveis usando AES-256-CBC
  /// 
  /// Espera string no formato: base64(iv):base64(encrypted)
  /// 
  /// Exemplo de uso:
  /// ```dart
  /// final decrypted = await EncryptionService.decrypt(encryptedString);
  /// ```
  static Future<String> decrypt(String ciphertext) async {
    if (ciphertext.isEmpty) {
      throw ArgumentError('Texto criptografado não pode ser vazio');
    }

    try {
      final keyString = await _getEncryptionKey();
      final key = Key.fromBase64(base64Encode(utf8.encode(keyString.padRight(32).substring(0, 32))));

      // Separar IV e dados criptografados
      final parts = ciphertext.split(':');
      if (parts.length != 2) {
        throw Exception('Formato de dados criptografados inválido');
      }

      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);

      final encrypter = Encrypter(AES(key, mode: AESMode.cbc));
      final decrypted = encrypter.decrypt(encrypted, iv: iv);

      return decrypted;
    } catch (e) {
      AppLogger.error('Erro ao descriptografar', e);
      throw Exception('Falha na descriptografia. Dados podem estar corrompidos ou chave incorreta.');
    }
  }

  /// Gerar hash SHA-256 para busca (não reversível)
  /// 
  /// Usado para buscar usuários por CPF/Email sem precisar descriptografar todos os dados.
  /// 
  /// Exemplo:
  /// ```dart
  /// final cpfHash = EncryptionService.hash('12345678900');
  /// // Buscar no Firestore: where('cpfHash', '==', cpfHash)
  /// ```
  static String hash(String data) {
    if (data.isEmpty) {
      throw ArgumentError('Dados não podem ser vazios');
    }

    // Normalizar dados (remover formatação)
    final normalized = data.replaceAll(RegExp(r'[^\d]'), '');

    // Gerar hash SHA-256
    final bytes = utf8.encode(normalized);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

}

