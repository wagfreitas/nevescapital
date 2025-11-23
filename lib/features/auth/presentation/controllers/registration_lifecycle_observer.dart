import 'dart:async';

import 'package:flutter/material.dart';
import 'package:neves_capital/features/auth/data/services/registration_service.dart';
import 'package:neves_capital/features/auth/data/services/local_registration_storage.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Observer do ciclo de vida com estratégia de salvamento inteligente:
///
/// 1. Durante navegação: salva LOCALMENTE (rápido, offline)
/// 2. Ao fechar app: persiste no FIRESTORE (analytics + backup)
/// 3. Ao completar cadastro: limpa tudo
///
/// Isso reduz chamadas ao Firestore e melhora performance.
class RegistrationLifecycleObserver extends WidgetsBindingObserver {
  final RegistrationProgress Function() getCurrentProgress;
  final bool Function()? shouldSaveProgress;
  final Duration saveDelay;
  bool _isSaving = false;
  bool _hasSavedToFirestore = false; // Flag para evitar salvamentos duplicados
  Timer? _pendingSaveTimer;
  DateTime? _lastFirestoreSave;

  RegistrationLifecycleObserver({
    required this.getCurrentProgress,
    this.shouldSaveProgress,
    this.saveDelay = const Duration(seconds: 2),
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    AppLogger.debug('[TELA] Lifecycle state alterado: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _cancelScheduledSave();
        break;
      case AppLifecycleState.inactive:
        // MUDANÇA: Salva no Firestore IMEDIATAMENTE no inactive
        // Este é o primeiro estado antes do app fechar
        _cancelScheduledSave();
        AppLogger.info(
            '[TELA] App inactive - salvando IMEDIATAMENTE no Firestore');
        _saveToFirestore();
        break;
      case AppLifecycleState.paused:
        // Backup: também tenta salvar no paused
        AppLogger.info('[TELA] App pausado - tentativa adicional de salvar');
        _saveToFirestore();
        break;
      case AppLifecycleState.hidden:
        _scheduleSave(localOnly: true);
        break;
      case AppLifecycleState.detached:
        // Última tentativa se ainda não salvou
        _cancelScheduledSave();
        AppLogger.info(
            '[TELA] App detached - última tentativa de salvar no Firestore');
        _saveToFirestore();
        break;
    }
  }

  void dispose() {
    _cancelScheduledSave();
  }

  /// Salva imediatamente (sem timer) - usar antes de navegar
  Future<void> saveNow({bool localOnly = true}) async {
    if (localOnly) {
      await _saveLocal();
    } else {
      await _saveToFirestore();
    }
  }

  void _scheduleSave({bool localOnly = false}) {
    if (_pendingSaveTimer != null) return;

    AppLogger.debug(
        'Agendando salvamento ${localOnly ? "LOCAL" : "COMPLETO"} para ${saveDelay.inMilliseconds}ms');
    _pendingSaveTimer = Timer(saveDelay, () {
      _pendingSaveTimer = null;
      if (localOnly) {
        _saveLocal();
      } else {
        _saveToFirestore();
      }
    });
  }

  void _cancelScheduledSave() {
    if (_pendingSaveTimer != null) {
      AppLogger.debug('Cancelando salvamento agendado (app retomado)');
      _pendingSaveTimer!.cancel();
      _pendingSaveTimer = null;
    }
  }

  /// Salva progresso localmente (rápido, para retomada imediata)
  Future<void> _saveLocal() async {
    if (_isSaving) return;

    final canSave = shouldSaveProgress?.call() ?? true;
    if (!canSave) {
      AppLogger.debug('Tela não está ativa - ignorando salvamento local.');
      return;
    }

    try {
      _isSaving = true;
      final progress = getCurrentProgress();

      AppLogger.debug(
          'Salvando progresso localmente - step: ${progress.currentStep}');
      await LocalRegistrationStorage.saveLocal(progress);
    } catch (e) {
      AppLogger.error('Erro ao salvar progresso localmente', e);
    } finally {
      _isSaving = false;
    }
  }

  /// Salva progresso no Firestore (para analytics e retomada em outro dispositivo)
  Future<void> _saveToFirestore() async {
    if (_isSaving) {
      AppLogger.debug(
          '[TELA] Salvamento já em progresso - ignorando chamada duplicada');
      return;
    }

    // Evita salvar no Firestore múltiplas vezes em curto intervalo
    if (_hasSavedToFirestore && _lastFirestoreSave != null) {
      final timeSinceLastSave = DateTime.now().difference(_lastFirestoreSave!);
      if (timeSinceLastSave.inSeconds < 5) {
        AppLogger.debug(
            '[TELA] Salvamento no Firestore feito há ${timeSinceLastSave.inSeconds}s - ignorando');
        return;
      }
    }

    try {
      _isSaving = true;
      final progress = getCurrentProgress();

      AppLogger.info(
          '[TELA] 🔥 INICIANDO salvamento Firestore - step: ${progress.currentStep}, cpf: ${progress.cpf.substring(0, 3)}***');

      // Salva no Firestore para analytics
      await RegistrationService.saveProgress(progress);

      _hasSavedToFirestore = true;
      _lastFirestoreSave = DateTime.now();

      AppLogger.info('[TELA] ✅ Progresso salvo no Firestore COM SUCESSO');

      // Também garante que está salvo localmente
      await LocalRegistrationStorage.saveLocal(progress);

      AppLogger.info('[TELA] ✅ Progresso salvo localmente também');
    } catch (e, stackTrace) {
      AppLogger.error(
          '[TELA] ❌ ERRO ao salvar progresso no Firestore: $e', stackTrace);
    } finally {
      _isSaving = false;
    }
  }
}
