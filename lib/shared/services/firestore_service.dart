import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neves_capital/shared/services/encryption_service.dart';
import 'package:neves_capital/core/utils/app_logger.dart';

/// Serviço para gerenciar dados dos usuários no Firestore
///
/// Substitui DatabaseService (PostgreSQL) por Firestore
///
/// **IMPORTANTE:**
/// - Dados sensíveis são criptografados antes de salvar
/// - Não usa Firebase Auth - autenticação é feita via OTP
class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Criar novo usuário no Firestore
  ///
  /// Dados sensíveis (CPF, email, telefone) são criptografados antes de salvar.
  /// Hash é gerado para permitir busca sem descriptografar todos os dados.
  ///
  /// **Nota:** userId é gerado automaticamente (document ID) ou pode ser passado.
  static Future<String> createUser({
    String?
        userId, // Opcional - se não fornecido, Firestore gera automaticamente
    required String email,
    required String fullName,
    required String cpf,
    String? phone,
    DateTime? birthDate,
    String? motherName,
    bool? isPep,
    String? occupation,
    String? incomeRange,
    String? cep,
    String? address,
    String? neighborhood,
    String? city,
    String? state,
    String? number,
    String? complement,
  }) async {
    try {
      final docId = userId ?? _firestore.collection('users').doc().id;
      AppLogger.debug('Criando usuário no Firestore');

      // Criptografar dados sensíveis
      final emailEncrypted = await EncryptionService.encrypt(email);
      final cpfEncrypted = await EncryptionService.encrypt(cpf);
      String? phoneEncrypted;
      String? phoneHash;
      if (phone != null && phone.isNotEmpty) {
        phoneEncrypted = await EncryptionService.encrypt(phone);
        phoneHash = EncryptionService.hash(phone);
      }

      // Gerar hash para busca (não reversível, seguro)
      final emailHash = EncryptionService.hash(email);
      final cpfHash = EncryptionService.hash(cpf);

      // Preparar dados do usuário
      final userData = <String, dynamic>{
        'displayName': fullName,
        'emailEncrypted': emailEncrypted,
        'emailHash': emailHash,
        'cpfEncrypted': cpfEncrypted,
        'cpfHash': cpfHash,
        'kycStatus': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Adicionar telefone se fornecido
      if (phoneEncrypted != null && phoneHash != null) {
        userData['phoneEncrypted'] = phoneEncrypted;
        userData['phoneHash'] = phoneHash;
      }

      // Adicionar dados pessoais adicionais se fornecidos
      if (birthDate != null) {
        userData['birthDate'] = Timestamp.fromDate(birthDate);
      }
      if (motherName != null) {
        userData['motherName'] = motherName;
      }
      if (isPep != null) {
        userData['isPep'] = isPep;
      }
      if (occupation != null) {
        userData['occupation'] = occupation;
      }
      if (incomeRange != null) {
        userData['incomeRange'] = incomeRange;
      }

      // Adicionar endereço se fornecido
      // Modelagem: endereço como objeto aninhado com todos os campos
      // Campos obrigatórios: street (ou address), city, state
      // Campos opcionais: cep, number, complement, neighborhood
      final hasRequiredAddressFields = (address != null && address.isNotEmpty) && 
                                      (city != null && city.isNotEmpty) && 
                                      (state != null && state.isNotEmpty);
      
      if (hasRequiredAddressFields) {
        userData['address'] = {
          'cep': cep?.trim() ?? '',
          'street': address.trim(),
          'number': number?.trim() ?? '',
          'complement': complement?.trim() ?? '',
          'neighborhood': neighborhood?.trim() ?? '',
          'city': city.trim(),
          'state': state.trim(),
        };
        AppLogger.info('✅ Endereço adicionado ao usuário: ${city}/${state}');
        AppLogger.debug('  - CEP: ${cep ?? "não informado"}');
        AppLogger.debug('  - Rua: $address');
        AppLogger.debug('  - Número: ${number ?? "não informado"}');
        AppLogger.debug('  - Bairro: ${neighborhood ?? "não informado"}');
      } else {
        AppLogger.warning('⚠️ Endereço não adicionado - campos obrigatórios ausentes:');
        AppLogger.warning('  - address: ${address != null && address.isNotEmpty}');
        AppLogger.warning('  - city: ${city != null && city.isNotEmpty}');
        AppLogger.warning('  - state: ${state != null && state.isNotEmpty}');
      }

      // Salvar no Firestore
      await _firestore.collection('users').doc(docId).set(userData);

      AppLogger.info('Usuário criado com sucesso no Firestore');
      return docId;
    } catch (e) {
      AppLogger.error('Erro ao criar usuário no Firestore', e);
      rethrow;
    }
  }

  /// Buscar usuário por CPF
  ///
  /// Usa hash do CPF para busca eficiente sem descriptografar todos os dados.
  static Future<Map<String, dynamic>?> getUserByCpf(String cpf) async {
    try {
      AppLogger.debug('Buscando usuário por CPF no Firestore');

      // Gerar hash do CPF para busca
      final cpfHash = EncryptionService.hash(cpf);

      // Buscar no Firestore usando hash
      final querySnapshot = await _firestore
          .collection('users')
          .where('cpfHash', isEqualTo: cpfHash)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        AppLogger.warning('Usuário não encontrado com CPF fornecido');
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();

      // Descriptografar dados sensíveis
      final decryptedData = await _decryptUserData(data);

      // Adicionar ID do documento
      decryptedData['id'] = doc.id;

      AppLogger.info('Usuário encontrado no Firestore');
      return decryptedData;
    } catch (e) {
      AppLogger.error('Erro ao buscar usuário por CPF', e);
      return null;
    }
  }

  /// Buscar usuário por email
  ///
  /// Usa hash do email para busca eficiente.
  static Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      AppLogger.debug('Buscando usuário por email no Firestore');

      // Gerar hash do email para busca
      final emailHash = EncryptionService.hash(email);

      // Buscar no Firestore usando hash
      final querySnapshot = await _firestore
          .collection('users')
          .where('emailHash', isEqualTo: emailHash)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        AppLogger.warning('Usuário não encontrado com email fornecido');
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();

      // Descriptografar dados sensíveis
      final decryptedData = await _decryptUserData(data);

      // Adicionar ID do documento
      decryptedData['id'] = doc.id;

      AppLogger.info('Usuário encontrado no Firestore');
      return decryptedData;
    } catch (e) {
      AppLogger.error('Erro ao buscar usuário por email', e);
      return null;
    }
  }

  /// Buscar usuário pelo ID do documento (usado após backend retornar userId)
  static Future<Map<String, dynamic>?> getUserByDocumentId(String docId) async {
    try {
      AppLogger.debug('Buscando usuário pelo ID do documento no Firestore');

      final doc = await _firestore.collection('users').doc(docId).get();
      if (!doc.exists) {
        AppLogger.warning('Usuário não encontrado com ID fornecido');
        return null;
      }

      final data = doc.data()!;

      // Descriptografar dados sensíveis
      final decryptedData = await _decryptUserData(data);

      // Adicionar ID do documento
      decryptedData['id'] = doc.id;

      AppLogger.info('Usuário encontrado no Firestore');
      return decryptedData;
    } catch (e) {
      AppLogger.error('Erro ao buscar usuário pelo ID do documento', e);
      return null;
    }
  }

  /// Vincula o documento do usuário ao UID do Firebase Auth
  static Future<void> linkUserDocumentToFirebaseUid({
    required String userId,
    required String firebaseUid,
  }) async {
    try {
      AppLogger.debug(
          'Vinculando documento $userId ao Firebase UID ${firebaseUid.substring(0, 6)}...');

      await _firestore.collection('users').doc(userId).set(
        {
          'ownerUid': firebaseUid,
          'ownerLinkedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      AppLogger.info('Documento vinculado ao Firebase UID com sucesso');
    } catch (e) {
      AppLogger.error('Erro ao vincular documento ao Firebase UID', e);
      rethrow;
    }
  }

  /// Verificar se CPF já está cadastrado
  ///
  /// Retorna true se CPF existe, false caso contrário.
  ///
  /// **Nota:** Não requer autenticação - Security Rules devem permitir leitura pública para busca.
  static Future<Map<String, dynamic>> checkCpf(String cpf) async {
    try {
      AppLogger.info('🔍 [FIRESTORE] Verificando se CPF está cadastrado...');
      AppLogger.sensitive('CPF completo', cpf);

      final cpfHash = EncryptionService.hash(cpf);
      AppLogger.debug(
          '📝 [FIRESTORE] CPF Hash gerado: ${cpfHash.substring(0, 16)}...');

      AppLogger.debug(
          '🔎 [FIRESTORE] Buscando na collection "users" com cpfHash...');
      final querySnapshot = await _firestore
          .collection('users')
          .where('cpfHash', isEqualTo: cpfHash)
          .limit(1)
          .get();

      final exists = querySnapshot.docs.isNotEmpty;
      final docCount = querySnapshot.docs.length;

      AppLogger.info(
          '📊 [FIRESTORE] Resultado: ${exists ? "✅ ENCONTRADO" : "❌ NÃO ENCONTRADO"} ($docCount documentos)');

      if (exists) {
        final doc = querySnapshot.docs.first;
        AppLogger.debug('📄 [FIRESTORE] Document ID: ${doc.id}');
        AppLogger.debug('📄 [FIRESTORE] Campos: ${doc.data().keys.join(", ")}');
      }

      return {
        'success': true,
        'exists': exists,
        'message': exists ? 'CPF já cadastrado' : 'CPF não cadastrado',
      };
    } catch (e, stackTrace) {
      AppLogger.error('❌ [FIRESTORE] Erro ao verificar CPF: $e', e, stackTrace);

      return {
        'success': false,
        'exists': false,
        'message':
            'Erro ao verificar CPF. Verifique sua conexão e tente novamente.',
      };
    }
  }

  /// Atualizar dados do usuário
  static Future<bool> updateUser({
    required String userId,
    String? fullName,
    String? email,
    String? cpf,
    String? phone,
    DateTime? birthDate,
    String? motherName,
    bool? isPep,
    String? occupation,
    String? incomeRange,
    String? cep,
    String? address,
    String? neighborhood,
    String? city,
    String? state,
    String? number,
    String? complement,
    String? selfieUrl,
    String? frontDocumentUrl,
    String? backDocumentUrl,
    String? documentType,
  }) async {
    try {
      AppLogger.debug('Iniciando atualização do usuário no Firestore');
      if (cpf != null) AppLogger.sensitive('CPF a atualizar', cpf);
      if (email != null) AppLogger.sensitive('Email a atualizar', email);
      if (phone != null) AppLogger.sensitive('Telefone a atualizar', phone);

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Atualizar nome se fornecido
      if (fullName != null && fullName.isNotEmpty) {
        updates['displayName'] = fullName;
      }

      // Atualizar email se fornecido (criptografar)
      if (email != null && email.isNotEmpty) {
        updates['emailEncrypted'] = await EncryptionService.encrypt(email);
        updates['emailHash'] = EncryptionService.hash(email);
      }

      // Atualizar CPF se fornecido (criptografar)
      if (cpf != null && cpf.isNotEmpty) {
        updates['cpfEncrypted'] = await EncryptionService.encrypt(cpf);
        updates['cpfHash'] = EncryptionService.hash(cpf);
      }

      // Atualizar telefone se fornecido (criptografar)
      if (phone != null && phone.isNotEmpty) {
        updates['phoneEncrypted'] = await EncryptionService.encrypt(phone);
        updates['phoneHash'] = EncryptionService.hash(phone);
      }

      // Atualizar dados pessoais adicionais
      if (birthDate != null) {
        updates['birthDate'] = Timestamp.fromDate(birthDate);
      }
      if (motherName != null && motherName.isNotEmpty) {
        updates['motherName'] = motherName;
      }
      if (isPep != null) {
        updates['isPep'] = isPep;
      }
      if (occupation != null && occupation.isNotEmpty) {
        updates['occupation'] = occupation;
      }
      if (incomeRange != null && incomeRange.isNotEmpty) {
        updates['incomeRange'] = incomeRange;
      }

      // Atualizar endereço se fornecido
      // Modelagem: endereço como objeto aninhado com todos os campos
      // Campos obrigatórios: street (ou address), city, state
      // Campos opcionais: cep, number, complement, neighborhood
      final hasRequiredAddressFields = (address != null && address.isNotEmpty) && 
                                      (city != null && city.isNotEmpty) && 
                                      (state != null && state.isNotEmpty);
      
      if (hasRequiredAddressFields) {
        updates['address'] = {
          'cep': cep?.trim() ?? '',
          'street': address.trim(),
          'number': number?.trim() ?? '',
          'complement': complement?.trim() ?? '',
          'neighborhood': neighborhood?.trim() ?? '',
          'city': city.trim(),
          'state': state.trim(),
        };
        AppLogger.info('✅ Endereço atualizado: ${city}/${state}');
        AppLogger.debug('  - CEP: ${cep ?? "não informado"}');
        AppLogger.debug('  - Rua: $address');
        AppLogger.debug('  - Número: ${number ?? "não informado"}');
        AppLogger.debug('  - Bairro: ${neighborhood ?? "não informado"}');
      } else if (cep != null || address != null || city != null || state != null) {
        // Se pelo menos um campo de endereço foi fornecido, mas não todos obrigatórios
        AppLogger.warning('⚠️ Endereço parcial fornecido - campos obrigatórios ausentes:');
        AppLogger.warning('  - address: ${address != null && address.isNotEmpty}');
        AppLogger.warning('  - city: ${city != null && city.isNotEmpty}');
        AppLogger.warning('  - state: ${state != null && state.isNotEmpty}');
      }

      // Atualizar URLs dos documentos KYC se fornecidas
      if (selfieUrl != null && selfieUrl.isNotEmpty) {
        updates['kycDocuments.selfieUrl'] = selfieUrl;
      }
      if (frontDocumentUrl != null && frontDocumentUrl.isNotEmpty) {
        updates['kycDocuments.frontDocumentUrl'] = frontDocumentUrl;
      }
      if (backDocumentUrl != null && backDocumentUrl.isNotEmpty) {
        updates['kycDocuments.backDocumentUrl'] = backDocumentUrl;
      }
      if (documentType != null && documentType.isNotEmpty) {
        updates['kycDocuments.documentType'] = documentType;
      }

      AppLogger.debug(
          'Campos a atualizar: ${updates.keys.join(", ")} (${updates.length} campos)');

      await _firestore.collection('users').doc(userId).update(updates);

      AppLogger.info('Usuário atualizado com sucesso no Firestore');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao atualizar usuário no Firestore', e);
      return false;
    }
  }

  /// Descriptografar dados do usuário
  static Future<Map<String, dynamic>> _decryptUserData(
      Map<String, dynamic> data) async {
    final decrypted = <String, dynamic>{};

    // Copiar dados não sensíveis
    decrypted['displayName'] = data['displayName'];
    decrypted['kycStatus'] = data['kycStatus'] ?? 'pending';
    decrypted['createdAt'] = data['createdAt'];
    decrypted['updatedAt'] = data['updatedAt'];

    // Descriptografar email
    if (data['emailEncrypted'] != null) {
      try {
        decrypted['email'] =
            await EncryptionService.decrypt(data['emailEncrypted'] as String);
      } catch (e) {
        AppLogger.warning('Erro ao descriptografar email');
        decrypted['email'] = null;
      }
    }

    // Descriptografar CPF
    if (data['cpfEncrypted'] != null) {
      try {
        decrypted['cpf'] =
            await EncryptionService.decrypt(data['cpfEncrypted'] as String);
      } catch (e) {
        AppLogger.warning('Erro ao descriptografar CPF');
        decrypted['cpf'] = null;
      }
    }

    // Descriptografar telefone
    if (data['phoneEncrypted'] != null) {
      try {
        decrypted['phone'] =
            await EncryptionService.decrypt(data['phoneEncrypted'] as String);
      } catch (e) {
        AppLogger.warning('Erro ao descriptografar telefone');
        decrypted['phone'] = null;
      }
    }

    // Copiar endereço (não é sensível)
    if (data['address'] != null) {
      decrypted['address'] = data['address'];
    }

    // Copiar dados pessoais adicionais (não sensíveis)
    if (data['birthDate'] != null) {
      decrypted['birthDate'] = data['birthDate'];
    }
    if (data['motherName'] != null) {
      decrypted['motherName'] = data['motherName'];
    }
    if (data['isPep'] != null) {
      decrypted['isPep'] = data['isPep'];
    }
    if (data['occupation'] != null) {
      decrypted['occupation'] = data['occupation'];
    }
    if (data['incomeRange'] != null) {
      decrypted['incomeRange'] = data['incomeRange'];
    }
    if (data['documentType'] != null) {
      decrypted['documentType'] = data['documentType'];
    }

    // Copiar dados da loja
    if (data['store'] != null) {
      decrypted['store'] = data['store'];
    }

    // Copiar chaves PIX
    if (data['pixKeys'] != null) {
      decrypted['pixKeys'] = data['pixKeys'];
    }

    return decrypted;
  }

  /// Obter usuário atual (logado)
  ///
  /// **Nota:** Não usa Firebase Auth. O estado de login é gerenciado pelo AuthController.
  /// Use getUserByCpf() ou getUserByDocumentId() diretamente.
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    // Não implementado - usar getUserByCpf() ou getUserByDocumentId() diretamente
    // O estado de login é gerenciado pelo AuthController via SharedPreferences
    return null;
  }
}
