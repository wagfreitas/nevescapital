import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Serviço para upload de arquivos no Firebase Storage
class FirebaseStorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload de selfie do usuário
  /// Retorna a URL pública da imagem
  static Future<String?> uploadSelfie({
    required String userId,
    required String filePath,
  }) async {
    try {
      final file = File(filePath);
      final fileName = 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users/$userId/kyc/$fileName');

      AppLogger.debug('Uploading selfie para: users/$userId/kyc/$fileName');

      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'type': 'selfie',
          },
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      AppLogger.info('Selfie uploaded com sucesso: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      AppLogger.error('Erro ao fazer upload da selfie: $e');
      return null;
    }
  }

  /// Upload de documento (frente ou verso)
  /// Retorna a URL pública da imagem
  static Future<String?> uploadDocument({
    required String userId,
    required String filePath,
    required String documentSide, // 'front' ou 'back'
  }) async {
    try {
      final file = File(filePath);
      final fileName =
          'document_${documentSide}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('users/$userId/kyc/$fileName');

      AppLogger.debug(
          'Uploading documento ($documentSide) para: users/$userId/kyc/$fileName');

      final uploadTask = await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedAt': DateTime.now().toIso8601String(),
            'type': 'document',
            'side': documentSide,
          },
        ),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      AppLogger.info(
          'Documento ($documentSide) uploaded com sucesso: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      AppLogger.error('Erro ao fazer upload do documento ($documentSide): $e');
      return null;
    }
  }

  /// Upload de múltiplos arquivos KYC (selfie + documentos)
  /// Retorna um Map com as URLs
  static Future<Map<String, String?>> uploadKycDocuments({
    required String userId,
    required String selfiePath,
    required String frontDocumentPath,
    required String backDocumentPath,
  }) async {
    AppLogger.info('Iniciando upload de documentos KYC para userId: $userId');

    final results = <String, String?>{};

    // Upload paralelo para melhor performance
    final futures = await Future.wait([
      uploadSelfie(userId: userId, filePath: selfiePath),
      uploadDocument(
          userId: userId, filePath: frontDocumentPath, documentSide: 'front'),
      uploadDocument(
          userId: userId, filePath: backDocumentPath, documentSide: 'back'),
    ]);

    results['selfieUrl'] = futures[0];
    results['frontDocumentUrl'] = futures[1];
    results['backDocumentUrl'] = futures[2];

    AppLogger.info('Upload de documentos KYC concluído');
    AppLogger.debug('Selfie URL: ${results['selfieUrl']}');
    AppLogger.debug('Front Document URL: ${results['frontDocumentUrl']}');
    AppLogger.debug('Back Document URL: ${results['backDocumentUrl']}');

    return results;
  }

  /// Deleta arquivo do Storage
  static Future<bool> deleteFile(String fileUrl) async {
    try {
      final ref = _storage.refFromURL(fileUrl);
      await ref.delete();
      AppLogger.info('Arquivo deletado com sucesso: $fileUrl');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao deletar arquivo: $e');
      return false;
    }
  }

  /// Deleta todos os documentos KYC de um usuário
  static Future<void> deleteUserKycDocuments(String userId) async {
    try {
      final ref = _storage.ref().child('users/$userId/kyc');
      final listResult = await ref.listAll();

      for (final item in listResult.items) {
        await item.delete();
        AppLogger.debug('Arquivo deletado: ${item.fullPath}');
      }

      AppLogger.info(
          'Todos os documentos KYC do usuário $userId foram deletados');
    } catch (e) {
      AppLogger.error('Erro ao deletar documentos KYC: $e');
    }
  }
}
