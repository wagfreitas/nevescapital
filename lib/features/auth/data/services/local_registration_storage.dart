import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Serviço para armazenar progresso do cadastro LOCALMENTE via SharedPreferences.
///
/// Estratégia simplificada (sem Firestore):
/// 1. Cada tela salva localmente ao avançar/voltar
/// 2. Ao reabrir o app, retoma de onde parou
/// 3. Ao completar cadastro, limpa tudo
class LocalRegistrationStorage {
  static const _progressKey = 'registration_progress_local';
  static const _cpfKey = 'last_registration_cpf';

  static Future<void> saveLocal(RegistrationProgress progress) async {
    try {
      AppLogger.debug(
          'Salvando progresso localmente - step: ${progress.currentStep}');

      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(progress.toJson());
      await prefs.setString(_progressKey, jsonData);
      await prefs.setString(_cpfKey, progress.cpf);

      AppLogger.info('Progresso salvo localmente com sucesso');
    } catch (e) {
      AppLogger.error('Erro ao salvar progresso localmente', e);
      rethrow;
    }
  }

  static Future<RegistrationProgress?> getLocal() async {
    try {
      AppLogger.debug('Buscando progresso local');

      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString(_progressKey);
      if (jsonData == null || jsonData.isEmpty) {
        AppLogger.debug('Nenhum progresso local encontrado');
        return null;
      }

      final map = jsonDecode(jsonData) as Map<String, dynamic>;
      final progress = RegistrationProgress.fromJson(map);
      AppLogger.info(
          'Progresso local encontrado - step: ${progress.currentStep}');

      return progress;
    } catch (e) {
      AppLogger.error('Erro ao buscar progresso local', e);
      return null;
    }
  }

  static Future<String?> getLastCpf() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cpf = prefs.getString(_cpfKey);
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

  static Future<void> clearLocal() async {
    try {
      AppLogger.debug('Limpando progresso local');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_progressKey);
      await prefs.remove(_cpfKey);
      AppLogger.info('Progresso local limpo com sucesso');
    } catch (e) {
      AppLogger.error('Erro ao limpar progresso local', e);
    }
  }

  static Future<bool> hasLocalProgress() async {
    final progress = await getLocal();
    return progress != null && !progress.isComplete && !progress.isStale;
  }
}
