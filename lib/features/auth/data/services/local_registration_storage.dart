import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Serviço para armazenar progresso do cadastro LOCALMENTE
///
/// Estratégia:
/// 1. Durante o cadastro: salva apenas localmente (rápido, offline)
/// 2. Ao fechar o app: persiste no Firestore (analytics + retomada em outro dispositivo)
/// 3. Ao completar: limpa local + Firestore e salva em 'users'
class LocalRegistrationStorage {
  static const _storage = FlutterSecureStorage();
  static const _progressKey = 'registration_progress_local';
  static const _cpfKey = 'last_registration_cpf';

  /// Salva progresso localmente
  static Future<void> saveLocal(RegistrationProgress progress) async {
    try {
      AppLogger.debug(
          'Salvando progresso localmente - step: ${progress.currentStep}');

      // Usa toJson() que converte DateTime para String ISO 8601
      final jsonData = jsonEncode(progress.toJson());
      await _storage.write(key: _progressKey, value: jsonData);

      // Também salva o CPF separadamente para verificação rápida
      await _storage.write(key: _cpfKey, value: progress.cpf);

      AppLogger.info('Progresso salvo localmente com sucesso');
    } catch (e) {
      AppLogger.error('Erro ao salvar progresso localmente', e);
      rethrow;
    }
  }

  /// Busca progresso armazenado localmente
  static Future<RegistrationProgress?> getLocal() async {
    try {
      AppLogger.debug('Buscando progresso local');

      final jsonData = await _storage.read(key: _progressKey);
      if (jsonData == null || jsonData.isEmpty) {
        AppLogger.debug('Nenhum progresso local encontrado');
        return null;
      }

      final map = jsonDecode(jsonData) as Map<String, dynamic>;

      // Usa fromJson() que trata DateTime automaticamente
      final progress = RegistrationProgress.fromJson(map);
      AppLogger.info(
          'Progresso local encontrado - step: ${progress.currentStep}');

      return progress;
    } catch (e) {
      AppLogger.error('Erro ao buscar progresso local', e);
      return null;
    }
  }

  /// Busca último CPF usado (verificação rápida)
  static Future<String?> getLastCpf() async {
    try {
      final cpf = await _storage.read(key: _cpfKey);
      if (cpf != null && cpf.isNotEmpty) {
        AppLogger.debug(
            'CPF encontrado no storage local: ${cpf.substring(0, 3)}***');
        return cpf;
      }
      AppLogger.debug('Nenhum CPF armazenado localmente');
      return null;
    } catch (e) {
      AppLogger.error('Erro ao buscar CPF local', e);
      return null;
    }
  }

  /// Limpa progresso local
  static Future<void> clearLocal() async {
    try {
      AppLogger.debug('Limpando progresso local');
      await _storage.delete(key: _progressKey);
      await _storage.delete(key: _cpfKey);
      AppLogger.info('Progresso local limpo com sucesso');
    } catch (e) {
      AppLogger.error('Erro ao limpar progresso local', e);
    }
  }

  /// Verifica se existe progresso local válido
  static Future<bool> hasLocalProgress() async {
    final progress = await getLocal();
    return progress != null && !progress.isComplete && !progress.isStale;
  }
}
