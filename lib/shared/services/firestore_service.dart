import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:neves_capital/shared/services/encryption_service.dart';
import 'package:neves_capital/shared/services/firebase_storage_service.dart';
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
    String? userId, // Opcional - se não fornecido, Firestore gera automaticamente
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
      final hasRequiredAddressFields = (address != null && address.isNotEmpty) && 
                                      (city != null && city.isNotEmpty) && 
                                      (state != null && state.isNotEmpty);
      
      if (hasRequiredAddressFields) {
        userData['address'] = <String, dynamic>{
          'street': address,
          'city': city,
          'state': state,
        };
        
        if (cep != null && cep.isNotEmpty) {
          userData['address']!['cep'] = cep;
        }
        if (neighborhood != null && neighborhood.isNotEmpty) {
          userData['address']!['neighborhood'] = neighborhood;
        }
        if (number != null && number.isNotEmpty) {
          userData['address']!['number'] = number;
        }
        if (complement != null && complement.isNotEmpty) {
          userData['address']!['complement'] = complement;
        }
      }

      await _firestore.collection('users').doc(docId).set(userData);

      AppLogger.info('✅ Usuário criado no Firestore: $docId');
      return docId;
    } catch (e) {
      AppLogger.error('Erro ao criar usuário no Firestore', e);
      rethrow;
    }
  }

  /// Buscar usuário por CPF
  ///
  /// Usa hash do CPF para buscar no Firestore sem descriptografar todos os dados.
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
      await _firestore.collection('users').doc(userId).update({
        'ownerUid': firebaseUid,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      AppLogger.info('✅ Usuário vinculado ao Firebase Auth UID');
    } catch (e) {
      AppLogger.error('Erro ao vincular usuário ao Firebase Auth UID', e);
      rethrow;
    }
  }

  /// Descriptografar dados do usuário
  static Future<Map<String, dynamic>> _decryptUserData(Map<String, dynamic> data) async {
    final decrypted = <String, dynamic>{};

    // Copiar campos não criptografados
    if (data['displayName'] != null) {
      decrypted['displayName'] = data['displayName'];
    }
    if (data['kycStatus'] != null) {
      decrypted['kycStatus'] = data['kycStatus'];
    }
    if (data['createdAt'] != null) {
      decrypted['createdAt'] = data['createdAt'];
    }
    if (data['updatedAt'] != null) {
      decrypted['updatedAt'] = data['updatedAt'];
    }
    if (data['ownerUid'] != null) {
      decrypted['ownerUid'] = data['ownerUid'];
    }

    // Descriptografar CPF
    if (data['cpfEncrypted'] != null) {
      try {
        decrypted['cpf'] = await EncryptionService.decrypt(data['cpfEncrypted'] as String);
      } catch (e) {
        AppLogger.error('Erro ao descriptografar CPF', e);
      }
    }

    // Descriptografar email
    if (data['emailEncrypted'] != null) {
      try {
        decrypted['email'] = await EncryptionService.decrypt(data['emailEncrypted'] as String);
      } catch (e) {
        AppLogger.error('Erro ao descriptografar email', e);
      }
    }

    // Descriptografar telefone
    if (data['phoneEncrypted'] != null) {
      try {
        decrypted['phone'] = await EncryptionService.decrypt(data['phoneEncrypted'] as String);
      } catch (e) {
        AppLogger.error('Erro ao descriptografar telefone', e);
      }
    }

    // Copiar dados pessoais
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

    // Copiar endereço
    if (data['address'] != null) {
      decrypted['address'] = data['address'];
    }

    // Copiar dados da loja
    if (data['storeName'] != null) {
      decrypted['storeName'] = data['storeName'];
    }
    if (data['businessType'] != null) {
      decrypted['businessType'] = data['businessType'];
    }
    // Manter compatibilidade com formato antigo (objeto aninhado)
    if (data['store'] != null) {
      decrypted['store'] = data['store'];
    }

    // Copiar chaves PIX
    if (data['pixKeys'] != null) {
      decrypted['pixKeys'] = data['pixKeys'];
    }

    // Copiar dados bancários
    if (data['bankAccount'] != null) {
      decrypted['bankAccount'] = data['bankAccount'];
    }

    return decrypted;
  }

  /// Salvar dados bancários do usuário
  ///
  /// Salva como objeto aninhado `bankAccount` no documento do usuário.
  /// Estrutura:
  /// ```dart
  /// bankAccount: {
  ///   bankCode: '001',
  ///   bankName: 'Banco do Brasil S.A.',
  ///   branch: '1234',
  ///   branchDigit: '5',
  ///   account: '12345678',
  ///   accountDigit: '9',
  ///   updatedAt: Timestamp
  /// }
  /// ```
  static Future<bool> saveBankAccount({
    required String userId,
    required String bankCode,
    required String bankName,
    required String branch,
    String? branchDigit,
    required String account,
    String? accountDigit,
  }) async {
    try {
      AppLogger.debug('Salvando dados bancários no Firestore');

      final bankAccountData = <String, dynamic>{
        'bankCode': bankCode,
        'bankName': bankName,
        'branch': branch.trim(),
        'account': account.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Adicionar dígitos se fornecidos
      if (branchDigit != null && branchDigit.isNotEmpty) {
        bankAccountData['branchDigit'] = branchDigit.trim();
      }
      if (accountDigit != null && accountDigit.isNotEmpty) {
        bankAccountData['accountDigit'] = accountDigit.trim();
      }

      await _firestore.collection('users').doc(userId).update({
        'bankAccount': bankAccountData,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      AppLogger.info('✅ Dados bancários salvos com sucesso');
      AppLogger.debug('  - Banco: $bankCode - $bankName');
      AppLogger.debug('  - Agência: $branch${branchDigit != null ? "-$branchDigit" : ""}');
      AppLogger.debug('  - Conta: $account${accountDigit != null ? "-$accountDigit" : ""}');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao salvar dados bancários no Firestore', e);
      return false;
    }
  }

  /// Obter dados bancários do usuário
  ///
  /// Retorna o objeto `bankAccount` do documento do usuário, ou null se não existir.
  static Future<Map<String, dynamic>?> getBankAccount(String userId) async {
    try {
      AppLogger.debug('Buscando dados bancários no Firestore');

      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        AppLogger.warning('Usuário não encontrado');
        return null;
      }

      final data = doc.data()!;
      if (data['bankAccount'] == null) {
        AppLogger.info('Dados bancários não encontrados para o usuário');
        return null;
      }

      final bankAccount = data['bankAccount'] as Map<String, dynamic>;
      AppLogger.info('✅ Dados bancários encontrados');
      return bankAccount;
    } catch (e) {
      AppLogger.error('Erro ao buscar dados bancários no Firestore', e);
      return null;
    }
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

  /// Deletar todos os dados de um usuário específico
  ///
  /// Esta função realiza uma limpeza completa dos dados do usuário:
  /// 1. Deleta o documento do usuário na collection `users` do Firestore
  /// 2. Deleta a conta de autenticação do Firebase Auth (se existir e o usuário atual for o mesmo)
  /// 3. Deleta todos os arquivos do Storage (documentos KYC)
  ///
  /// **Parâmetros:**
  /// - `userId`: ID do documento do usuário na collection `users`
  /// - `deleteAuthAccount`: Se `true`, tenta deletar a conta do Firebase Auth.
  ///   Requer que o usuário atual seja o mesmo que será deletado.
  ///
  /// **Retorna:**
  /// - `true` se a limpeza foi bem-sucedida
  /// - `false` se houve algum erro (mas pode ter deletado parcialmente)
  ///
  /// **Nota:** Esta operação é irreversível. Use com cuidado.
  static Future<bool> deleteUserData({
    required String userId,
    bool deleteAuthAccount = true,
  }) async {
    try {
      AppLogger.info('🗑️ Iniciando limpeza completa dos dados do usuário: $userId');

      // 1. Buscar o documento do usuário para obter informações (como ownerUid)
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        AppLogger.warning('⚠️ Usuário não encontrado no Firestore: $userId');
        return false;
      }

      final userData = userDoc.data()!;
      final ownerUid = userData['ownerUid'] as String?;

      AppLogger.debug('📄 Documento encontrado. ownerUid: ${ownerUid ?? "não vinculado"}');

      // 2. Deletar arquivos do Storage (documentos KYC)
      try {
        AppLogger.debug('📦 Deletando arquivos do Storage...');
        await FirebaseStorageService.deleteUserKycDocuments(userId);
        AppLogger.info('✅ Arquivos do Storage deletados');
      } catch (e) {
        AppLogger.warning('⚠️ Erro ao deletar arquivos do Storage (continuando): $e');
        // Continua mesmo se falhar, pois pode não haver arquivos
      }

      // 3. Deletar conta do Firebase Auth (se solicitado e possível)
      if (deleteAuthAccount && ownerUid != null) {
        try {
          final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
          if (currentUser != null && currentUser.uid == ownerUid) {
            AppLogger.debug('🔐 Deletando conta do Firebase Auth...');
            await currentUser.delete();
            AppLogger.info('✅ Conta do Firebase Auth deletada');
          } else {
            AppLogger.warning('⚠️ Não foi possível deletar conta do Firebase Auth: usuário não corresponde');
          }
        } catch (e) {
          AppLogger.warning('⚠️ Erro ao deletar conta do Firebase Auth (continuando): $e');
          // Continua mesmo se falhar
        }
      }

      // 4. Deletar subcollections (vendas, etc.)
      try {
        AppLogger.debug('🗂️ Deletando subcollections...');
        
        // Deletar vendas
        final salesSnapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('sales')
            .get();
        
        final batch = _firestore.batch();
        for (var doc in salesSnapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        
        AppLogger.info('✅ Subcollections deletadas');
      } catch (e) {
        AppLogger.warning('⚠️ Erro ao deletar subcollections (continuando): $e');
      }

      // 5. Deletar documento do usuário
      AppLogger.debug('📄 Deletando documento do usuário...');
      await _firestore.collection('users').doc(userId).delete();
      AppLogger.info('✅ Documento do usuário deletado');

      AppLogger.info('✅ Limpeza completa dos dados do usuário concluída');
      return true;
    } catch (e) {
      AppLogger.error('❌ Erro durante limpeza dos dados do usuário', e);
      return false;
    }
  }

  /// Salvar venda do usuário
  ///
  /// Salva a venda como documento na subcollection `sales` do usuário.
  /// Estrutura: `users/{userId}/sales/{saleId}`
  ///
  /// **Vantagens desta arquitetura:**
  /// - Escalável: sem limite de documentos por subcollection
  /// - Seguro: regras de segurança aplicadas automaticamente
  /// - Eficiente: queries diretas na subcollection do usuário
  /// - Organizado: dados agrupados por usuário
  ///
  /// **Estrutura do documento:**
  /// ```dart
  /// {
  ///   saleId: 'auto-generated',
  ///   valorCentavos: 42454,
  ///   valorLiquidoCentavos: 41180, // 97% do valor
  ///   nomeEstabelecimento: 'Loja do João',
  ///   ramoAtuacao: 'Alimentação',
  ///   cardBrand: 'Visa',
  ///   cardLastFour: '1234',
  ///   cardNumber: '•••• 1234', // mascarado
  ///   createdAt: Timestamp,
  ///   status: 'completed' // ou 'pending', 'failed'
  /// }
  /// ```
  static Future<String?> saveSale({
    required String userId,
    required int valorCentavos,
    required String nomeEstabelecimento,
    required String ramoAtuacao,
    String? cardBrand,
    String? cardLastFour,
    String? cardNumber, // número mascarado
    String? bankCode,
    String? branch,
    String? account,
    String status = 'completed',
  }) async {
    try {
      AppLogger.debug('Salvando venda no Firestore');

      // Calcular valor líquido (97% do valor)
      final valorLiquidoCentavos = (valorCentavos * 0.97).round();

      // Gerar ID único para a venda
      final saleId = _firestore.collection('users').doc(userId).collection('sales').doc().id;

      final saleData = <String, dynamic>{
        'saleId': saleId,
        'valorCentavos': valorCentavos,
        'valorLiquidoCentavos': valorLiquidoCentavos,
        'nomeEstabelecimento': nomeEstabelecimento,
        'ramoAtuacao': ramoAtuacao,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Adicionar dados do cartão se fornecidos
      if (cardBrand != null) {
        saleData['cardBrand'] = cardBrand;
      }
      if (cardLastFour != null) {
        saleData['cardLastFour'] = cardLastFour;
      }
      if (cardNumber != null) {
        saleData['cardNumber'] = cardNumber; // já vem mascarado
      }
      if (bankCode != null) saleData['bankCode'] = bankCode;
      if (branch != null) saleData['branch'] = branch;
      if (account != null) saleData['account'] = account;

      // Salvar na subcollection
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sales')
          .doc(saleId)
          .set(saleData);

      AppLogger.info('✅ Venda salva com sucesso: $saleId');
      AppLogger.debug('  - Valor: R\$ ${(valorCentavos / 100).toStringAsFixed(2)}');
      AppLogger.debug('  - Valor Líquido: R\$ ${(valorLiquidoCentavos / 100).toStringAsFixed(2)}');
      AppLogger.debug('  - Estabelecimento: $nomeEstabelecimento');

      return saleId;
    } catch (e) {
      AppLogger.error('Erro ao salvar venda no Firestore', e);
      return null;
    }
  }

  /// Buscar vendas do usuário
  ///
  /// Retorna lista de vendas ordenadas por data (mais recente primeiro).
  /// Limite padrão: 50 vendas.
  static Future<List<Map<String, dynamic>>> getUserSales({
    required String userId,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      AppLogger.debug('Buscando vendas do usuário no Firestore');

      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('sales')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      // Aplicar filtros de data se fornecidos
      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final querySnapshot = await query.get();

      final sales = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      AppLogger.info('✅ ${sales.length} venda(s) encontrada(s)');
      return sales;
    } catch (e) {
      AppLogger.error('Erro ao buscar vendas do usuário', e);
      return [];
    }
  }

  /// Verificar se CPF existe no Firestore
  ///
  /// Retorna um Map com:
  /// - `success`: bool indicando se a operação foi bem-sucedida
  /// - `exists`: bool indicando se o CPF existe no banco
  static Future<Map<String, dynamic>> checkCpf(String cpf) async {
    try {
      AppLogger.debug('Verificando se CPF existe no Firestore');

      // Gerar hash do CPF para busca
      final cpfHash = EncryptionService.hash(cpf);

      // Buscar no Firestore usando hash
      final querySnapshot = await _firestore
          .collection('users')
          .where('cpfHash', isEqualTo: cpfHash)
          .limit(1)
          .get();

      final exists = querySnapshot.docs.isNotEmpty;

      AppLogger.info('CPF ${exists ? "encontrado" : "não encontrado"} no Firestore');
      return {
        'success': true,
        'exists': exists,
      };
    } catch (e) {
      AppLogger.error('Erro ao verificar CPF no Firestore', e);
      return {
        'success': false,
        'exists': false,
      };
    }
  }

  /// Atualizar dados do usuário no Firestore
  ///
  /// Atualiza apenas os campos fornecidos. Dados sensíveis são criptografados antes de salvar.
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
    String? storeName,
    String? businessType,
    String? selfieUrl,
    String? frontDocumentUrl,
    String? backDocumentUrl,
    String? documentType,
  }) async {
    try {
      AppLogger.debug('Atualizando usuário no Firestore');

      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Atualizar nome
      if (fullName != null) {
        updateData['displayName'] = fullName;
      }

      // Atualizar CPF (criptografar)
      if (cpf != null && cpf.isNotEmpty) {
        final cpfEncrypted = await EncryptionService.encrypt(cpf);
        final cpfHash = EncryptionService.hash(cpf);
        updateData['cpfEncrypted'] = cpfEncrypted;
        updateData['cpfHash'] = cpfHash;
      }

      // Atualizar email (criptografar)
      if (email != null && email.isNotEmpty) {
        final emailEncrypted = await EncryptionService.encrypt(email);
        final emailHash = EncryptionService.hash(email);
        updateData['emailEncrypted'] = emailEncrypted;
        updateData['emailHash'] = emailHash;
      }

      // Atualizar telefone (criptografar)
      if (phone != null && phone.isNotEmpty) {
        final phoneEncrypted = await EncryptionService.encrypt(phone);
        final phoneHash = EncryptionService.hash(phone);
        updateData['phoneEncrypted'] = phoneEncrypted;
        updateData['phoneHash'] = phoneHash;
      }

      // Atualizar dados pessoais
      if (birthDate != null) {
        updateData['birthDate'] = Timestamp.fromDate(birthDate);
      }
      if (motherName != null) {
        updateData['motherName'] = motherName;
      }
      if (isPep != null) {
        updateData['isPep'] = isPep;
      }
      if (occupation != null) {
        updateData['occupation'] = occupation;
      }
      if (incomeRange != null) {
        updateData['incomeRange'] = incomeRange;
      }

      // Atualizar endereço
      if (address != null || city != null || state != null) {
        // Buscar endereço atual para preservar campos não fornecidos
        final userDoc = await _firestore.collection('users').doc(userId).get();
        Map<String, dynamic>? currentAddress;
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['address'] != null) {
            currentAddress = Map<String, dynamic>.from(userData['address'] as Map);
          }
        }

        currentAddress ??= <String, dynamic>{};

        if (address != null) {
          currentAddress['street'] = address;
        }
        if (city != null) {
          currentAddress['city'] = city;
        }
        if (state != null) {
          currentAddress['state'] = state;
        }
        if (cep != null) {
          currentAddress['cep'] = cep;
        }
        if (neighborhood != null) {
          currentAddress['neighborhood'] = neighborhood;
        }
        if (number != null) {
          currentAddress['number'] = number;
        }
        if (complement != null) {
          currentAddress['complement'] = complement;
        }

        updateData['address'] = currentAddress;
      }

      // Atualizar dados da loja
      if (storeName != null || businessType != null) {
        // Buscar dados da loja atuais para preservar campos não fornecidos
        final userDoc = await _firestore.collection('users').doc(userId).get();
        Map<String, dynamic>? currentStore;
        
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null && userData['store'] != null) {
            currentStore = Map<String, dynamic>.from(userData['store'] as Map);
          }
        }

        currentStore ??= <String, dynamic>{};

        if (storeName != null) {
          currentStore['storeName'] = storeName;
          // Manter compatibilidade com formato antigo
          updateData['storeName'] = storeName;
        }
        if (businessType != null) {
          currentStore['businessType'] = businessType;
          // Manter compatibilidade com formato antigo
          updateData['businessType'] = businessType;
        }

        updateData['store'] = currentStore;
      }

      // Atualizar URLs de documentos KYC
      if (selfieUrl != null) {
        updateData['selfieUrl'] = selfieUrl;
      }
      if (frontDocumentUrl != null) {
        updateData['frontDocumentUrl'] = frontDocumentUrl;
      }
      if (backDocumentUrl != null) {
        updateData['backDocumentUrl'] = backDocumentUrl;
      }
      if (documentType != null) {
        updateData['documentType'] = documentType;
      }

      // Atualizar documento
      await _firestore.collection('users').doc(userId).update(updateData);

      AppLogger.info('✅ Usuário atualizado no Firestore');
      AppLogger.debug('Campos atualizados: ${updateData.keys.join(", ")}');
      return true;
    } catch (e) {
      AppLogger.error('Erro ao atualizar usuário no Firestore', e);
      return false;
    }
  }
}
