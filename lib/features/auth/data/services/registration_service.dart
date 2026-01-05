import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neves_capital/features/auth/domain/entities/registration_progress.dart';
import 'package:neves_capital/shared/services/encryption_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Serviço para gerenciar o progresso do cadastro
///
/// Salva o estado do cadastro a cada passo, permitindo que o usuário
/// retome de onde parou caso abandone o processo
class RegistrationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'registration_progress';

  /// Salva ou atualiza o progresso do cadastro
  static Future<void> saveProgress(RegistrationProgress progress) async {
    try {
      AppLogger.info(
          '🔥 [FIRESTORE] INICIANDO salvamento - step: ${progress.currentStep}');

      // Gerar hash do CPF para busca
      final cpfHash = EncryptionService.hash(progress.cpf);
      AppLogger.debug('✓ Hash do CPF gerado: ${cpfHash.substring(0, 8)}...');

      // Criptografar CPF
      final cpfEncrypted = await EncryptionService.encrypt(progress.cpf);
      AppLogger.debug('✓ CPF criptografado');

      // Preparar dados - REMOVER campos null para não sobrescrever dados salvos
      final data = progress.toMap();
      // Remover campos null do map para não sobrescrever dados existentes no Firestore
      data.removeWhere((key, value) => value == null);
      data['cpfHash'] = cpfHash;
      data['cpfEncrypted'] = cpfEncrypted;
      data.remove('cpf'); // Remove CPF em texto claro
      AppLogger.debug('✓ Dados preparados (campos null removidos)');

      // Criptografar dados sensíveis
      if (progress.phone != null) {
        data['phoneEncrypted'] =
            await EncryptionService.encrypt(progress.phone!);
        data.remove('phone');
        AppLogger.debug('✓ Telefone criptografado');
      }
      if (progress.email != null) {
        data['emailEncrypted'] =
            await EncryptionService.encrypt(progress.email!);
        data.remove('email');
        AppLogger.debug('✓ Email criptografado');
      }

      // Converter DateTime para Timestamp
      data['lastUpdated'] = Timestamp.fromDate(progress.lastUpdated);
      if (progress.birthDate != null) {
        data['birthDate'] = Timestamp.fromDate(progress.birthDate!);
      }
      AppLogger.debug('✓ DateTime convertidos para Timestamp');

      // Salvar no Firestore usando merge para não sobrescrever campos existentes
      // Isso garante que dados de outras telas não sejam perdidos
      AppLogger.info(
          '🔥 [FIRESTORE] Escrevendo documento ${cpfHash.substring(0, 8)}... na collection $_collection (com merge)');
      await _firestore.collection(_collection).doc(cpfHash).set(
        data,
        SetOptions(merge: true), // MERGE: não sobrescreve campos que não estão no data
      );

      AppLogger.info('✅ [FIRESTORE] Progresso salvo COM SUCESSO no Firestore (merge aplicado)!');
    } catch (e, stackTrace) {
      AppLogger.error(
          '❌ [FIRESTORE] ERRO ao salvar progresso do cadastro: $e', e, stackTrace);
      rethrow;
    }
  }

  /// Busca o progresso do cadastro por CPF
  static Future<RegistrationProgress?> getProgress(String cpf) async {
    try {
      AppLogger.debug('Buscando progresso do cadastro');

      // Gerar hash do CPF
      final cpfHash = EncryptionService.hash(cpf);

      // Buscar no Firestore
      final doc = await _firestore.collection(_collection).doc(cpfHash).get();

      if (!doc.exists) {
        AppLogger.debug('Nenhum progresso encontrado para este CPF');
        return null;
      }

      final data = doc.data()!;

      // Descriptografar CPF
      final cpfEncrypted = data['cpfEncrypted'] as String;
      final cpfDecrypted = await EncryptionService.decrypt(cpfEncrypted);

      // Descriptografar dados sensíveis
      String? phone;
      if (data.containsKey('phoneEncrypted')) {
        phone =
            await EncryptionService.decrypt(data['phoneEncrypted'] as String);
      }

      String? email;
      if (data.containsKey('emailEncrypted')) {
        email =
            await EncryptionService.decrypt(data['emailEncrypted'] as String);
      }

      // Converter Timestamp para DateTime
      DateTime lastUpdated = DateTime.now();
      if (data['lastUpdated'] is Timestamp) {
        lastUpdated = (data['lastUpdated'] as Timestamp).toDate();
      }

      DateTime? birthDate;
      if (data.containsKey('birthDate') && data['birthDate'] is Timestamp) {
        birthDate = (data['birthDate'] as Timestamp).toDate();
      }

      // Reconstruir RegistrationProgress
      final progress = RegistrationProgress(
        cpf: cpfDecrypted,
        currentStep: data['currentStep'] as String,
        status: RegistrationStatus.values.firstWhere(
          (e) => e.toString() == 'RegistrationStatus.${data['status']}',
          orElse: () => RegistrationStatus.inProgress,
        ),
        lastUpdated: lastUpdated,
        phone: phone,
        email: email,
        fullName: data['fullName'] as String?,
        birthDate: birthDate,
        motherName: data['motherName'] as String?,
        isPep: data['isPep'] as bool?,
        occupation: data['occupation'] as String?,
        incomeRange: data['incomeRange'] as String?,
        selfiePath: data['selfiePath'] as String?,
        documentFrontPath: data['documentFrontPath'] as String?,
        documentBackPath: data['documentBackPath'] as String?,
        documentType: data['documentType'] as String?,
        cep: data['cep'] as String?,
        street: data['street'] as String?,
        number: data['number'] as String?,
        complement: data['complement'] as String?,
        neighborhood: data['neighborhood'] as String?,
        city: data['city'] as String?,
        state: data['state'] as String?,
      );

      AppLogger.info(
          'Progresso encontrado: step=${progress.currentStep}, status=${progress.status}');
      return progress;
    } catch (e) {
      AppLogger.error('Erro ao buscar progresso do cadastro', e);
      return null;
    }
  }

  /// Marca o cadastro como abandonado
  static Future<void> markAsAbandoned(String cpf) async {
    try {
      final progress = await getProgress(cpf);
      if (progress != null && progress.status != RegistrationStatus.completed) {
        await saveProgress(
          progress.copyWith(
            status: RegistrationStatus.abandoned,
            lastUpdated: DateTime.now(),
          ),
        );
        AppLogger.info('Cadastro marcado como abandonado');
      }
    } catch (e) {
      AppLogger.error('Erro ao marcar cadastro como abandonado', e);
    }
  }

  /// Marca o cadastro como completo
  static Future<void> markAsCompleted(String cpf) async {
    try {
      final progress = await getProgress(cpf);
      if (progress != null) {
        await saveProgress(
          progress.copyWith(
            currentStep: 'completed',
            status: RegistrationStatus.completed,
            lastUpdated: DateTime.now(),
          ),
        );
        AppLogger.info('Cadastro marcado como completo');
      }
    } catch (e) {
      AppLogger.error('Erro ao marcar cadastro como completo', e);
    }
  }

  /// Remove o progresso do cadastro (usado após finalização)
  static Future<void> deleteProgress(String cpf) async {
    try {
      final cpfHash = EncryptionService.hash(cpf);
      await _firestore.collection(_collection).doc(cpfHash).delete();
      AppLogger.info('Progresso do cadastro removido');
    } catch (e) {
      AppLogger.error('Erro ao remover progresso do cadastro', e);
    }
  }

  /// Verifica se existe cadastro em andamento ou abandonado
  static Future<bool> hasInProgressRegistration(String cpf) async {
    final progress = await getProgress(cpf);
    return progress != null &&
        progress.status != RegistrationStatus.completed &&
        !progress.isStale;
  }
}
