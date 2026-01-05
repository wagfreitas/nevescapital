import 'package:neves_capital/features/auth/data/services/registration_service.dart';
import 'package:neves_capital/features/auth/data/services/local_registration_storage.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Helper para garantir que dados sejam restaurados corretamente ao navegar
class RegistrationNavigationHelper {
  /// Salva o progresso atual e busca o progresso completo salvo
  /// Retorna o progresso completo com todos os dados já preenchidos
  /// IMPORTANTE: Busca primeiro para não perder dados de outras telas
  static Future<RegistrationProgress?> saveAndGetCompleteProgress({
    required RegistrationProgress currentProgress,
  }) async {
    try {
      // 1. PRIMEIRO buscar progresso completo salvo (para não perder dados de outras telas)
      AppLogger.debug('🔍 Buscando progresso completo salvo ANTES de salvar...');
      final savedProgress = await RegistrationService.getProgress(currentProgress.cpf);
      
      RegistrationProgress progressToSave;
      
      if (savedProgress != null) {
        AppLogger.debug('✅ Progresso completo encontrado - step: ${savedProgress.currentStep}');
        AppLogger.debug('📊 Dados salvos: phone=${savedProgress.phone != null}, email=${savedProgress.email != null}, fullName=${savedProgress.fullName != null}, cep=${savedProgress.cep != null}, occupation=${savedProgress.occupation != null}');
        AppLogger.debug('📊 Dados atuais: phone=${currentProgress.phone != null}, email=${currentProgress.email != null}, fullName=${currentProgress.fullName != null}, cep=${currentProgress.cep != null}, occupation=${currentProgress.occupation != null}');
        
        // 2. Mesclar: dados atuais têm prioridade (para a tela atual), mas dados salvos de outras telas são preservados
        progressToSave = _mergeProgress(savedProgress, currentProgress);
        AppLogger.debug('✅ Progresso mesclado criado - preservando dados de todas as telas');
        AppLogger.debug('📊 Dados mesclados: phone=${progressToSave.phone != null}, email=${progressToSave.email != null}, fullName=${progressToSave.fullName != null}, cep=${progressToSave.cep != null}, occupation=${progressToSave.occupation != null}');
      } else {
        AppLogger.debug('⚠️ Nenhum progresso salvo encontrado, usando progresso atual');
        progressToSave = currentProgress;
      }
      
      // 3. Salvar progresso mesclado (ou atual se não havia nada salvo)
      AppLogger.debug('💾 Salvando progresso mesclado - step: ${progressToSave.currentStep}');
      await RegistrationService.saveProgress(progressToSave);
      await LocalRegistrationStorage.saveLocal(progressToSave);
      AppLogger.debug('✅ Progresso salvo com sucesso - todos os dados preservados');
      
      return progressToSave;
    } catch (e, stackTrace) {
      AppLogger.error('❌ Erro ao salvar/buscar progresso: $e', e, stackTrace);
      // Em caso de erro, retornar progresso atual
      return currentProgress;
    }
  }

  /// Mescla dois progressos: dados atuais têm prioridade APENAS se não forem null
  /// Isso preserva dados de outras telas que não estão sendo editadas agora
  static RegistrationProgress _mergeProgress(
    RegistrationProgress saved, // Dados já salvos (preservar de outras telas)
    RegistrationProgress current, // Dados da tela atual (prioridade APENAS se não null)
  ) {
    // Função helper para preservar dados salvos se current for null
    T? preserveIfNull<T>(T? currentValue, T? savedValue) {
      return currentValue ?? savedValue;
    }
    
    return RegistrationProgress(
      cpf: saved.cpf,
      currentStep: current.currentStep, // Step atual é o da tela que está navegando
      status: saved.status,
      lastUpdated: DateTime.now(),
      // Dados básicos: usar atuais se não null, senão preservar salvos
      phone: preserveIfNull(current.phone, saved.phone),
      email: preserveIfNull(current.email, saved.email),
      fullName: preserveIfNull(current.fullName, saved.fullName),
      birthDate: preserveIfNull(current.birthDate, saved.birthDate),
      motherName: preserveIfNull(current.motherName, saved.motherName),
      // Dados de endereço: usar atuais se não null, senão preservar salvos
      cep: preserveIfNull(current.cep, saved.cep),
      street: preserveIfNull(current.street, saved.street),
      number: preserveIfNull(current.number, saved.number),
      complement: preserveIfNull(current.complement, saved.complement),
      neighborhood: preserveIfNull(current.neighborhood, saved.neighborhood),
      city: preserveIfNull(current.city, saved.city),
      state: preserveIfNull(current.state, saved.state),
      // Dados pessoais 2: usar atuais se não null, senão preservar salvos
      isPep: preserveIfNull(current.isPep, saved.isPep),
      occupation: preserveIfNull(current.occupation, saved.occupation),
      incomeRange: preserveIfNull(current.incomeRange, saved.incomeRange),
      // Dados de selfie e documentos: usar atuais se não null, senão preservar salvos
      selfiePath: preserveIfNull(current.selfiePath, saved.selfiePath),
      documentFrontPath: preserveIfNull(current.documentFrontPath, saved.documentFrontPath),
      documentBackPath: preserveIfNull(current.documentBackPath, saved.documentBackPath),
      documentType: preserveIfNull(current.documentType, saved.documentType),
    );
  }
}

