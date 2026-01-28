import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import * as admin from 'firebase-admin';
import * as crypto from 'crypto';

@Injectable()
export class UsersService {
  private readonly db = admin.firestore();

  /**
   * Buscar usuário por CPF no Firestore
   */
  async findByCpf(cpf: string) {
    try {
      // Normalizar CPF (remover formatação)
      const normalizedCpf = cpf.replace(/\D/g, '');

      // Buscar no Firestore
      const usersRef = this.db.collection('users');
      const snapshot = await usersRef.where('cpf', '==', normalizedCpf).limit(1).get();

      if (snapshot.empty) {
        throw new NotFoundException('Usuário não encontrado');
      }

      const userDoc = snapshot.docs[0];
      const userData = userDoc.data();

      return {
        id: userDoc.id,
        cpf: userData.cpf,
        email: userData.email,
        full_name: userData.full_name || userData.name,
        phone: userData.phone,
        ...userData,
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new BadRequestException(`Erro ao buscar usuário: ${error.message}`);
    }
  }

  /**
   * Buscar usuário por email no Firestore
   */
  async findByEmail(email: string) {
    try {
      const usersRef = this.db.collection('users');
      const snapshot = await usersRef.where('email', '==', email.toLowerCase()).limit(1).get();

      if (snapshot.empty) {
        throw new NotFoundException('Usuário não encontrado');
      }

      const userDoc = snapshot.docs[0];
      const userData = userDoc.data();

      return {
        id: userDoc.id,
        ...userData,
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new BadRequestException(`Erro ao buscar usuário: ${error.message}`);
    }
  }

  /**
   * Buscar usuário por telefone no Firestore
   */
  async findByPhone(phone: string) {
    try {
      // Normalizar telefone (remover formatação)
      const normalizedPhone = phone.replace(/\D/g, '');

      console.log(`🔍 [UsersService] Buscando usuário por telefone: ${normalizedPhone.substring(0, 4)}****`);
      console.log(`📋 [UsersService] Firestore instance: ${this.db ? 'OK' : 'NULL'}`);

      // Verificar se o Admin SDK está inicializado corretamente
      const adminModule = require('firebase-admin');
      if (!adminModule.apps.length) {
        throw new Error('Firebase Admin SDK não está inicializado');
      }
      
      console.log(`📋 [UsersService] Firebase Admin apps: ${adminModule.apps.length}`);
      console.log(`📋 [UsersService] Project ID: ${adminModule.app().options.projectId}`);
      
      // IMPORTANTE: Verificar se estamos usando Admin SDK (não SDK do cliente)
      // O Admin SDK deve bypassar as regras do Firestore automaticamente
      // Se estiver usando SDK do cliente, as regras do Firestore serão aplicadas
      // Verificação: Admin SDK retorna instância de Firestore do admin
      const adminFirestoreType = adminModule.firestore.Firestore;
      const isAdminSdk = this.db.constructor.name === 'Firestore' || this.db instanceof adminFirestoreType;
      console.log(`📋 [UsersService] Usando Admin SDK: ${isAdminSdk} (tipo: ${this.db.constructor.name})`);
      
      // Se não for Admin SDK, há um problema grave
      if (!isAdminSdk) {
        console.error('🚨 ERRO CRÍTICO: Não está usando Admin SDK! As regras do Firestore serão aplicadas.');
        throw new Error('ERRO CRÍTICO: Não está usando Admin SDK! As regras do Firestore serão aplicadas.');
      }
      
      const usersRef = this.db.collection('users');
      
      // Admin SDK deve bypassar as regras do Firestore
      // Se houver erro de Permission_Denied, pode ser problema de:
      // 1. Permissões IAM do serviço Cloud Run (mais provável)
      // 2. ProjectId incorreto
      // 3. Credenciais não configuradas
      // 4. Admin SDK não inicializado corretamente (menos provável, já verificamos acima)
      
      // IMPORTANTE: O telefone é salvo como phoneHash (SHA-256) no Firestore
      // Precisamos gerar o hash do telefone normalizado para buscar
      const phoneHash = crypto.createHash('sha256').update(normalizedPhone).digest('hex');
      console.log(`🔍 [UsersService] Hash do telefone gerado: ${phoneHash.substring(0, 16)}...`);
      console.log(`🔍 [UsersService] Executando query no Firestore por phoneHash (Admin SDK bypassa regras)...`);
      const snapshot = await usersRef.where('phoneHash', '==', phoneHash).limit(1).get();

      console.log(`📊 [UsersService] Query executada. Documentos encontrados: ${snapshot.size}`);

      if (snapshot.empty) {
        console.log(`❌ [UsersService] Usuário não encontrado para telefone: ${normalizedPhone.substring(0, 4)}****`);
        return null;
      }

      const userDoc = snapshot.docs[0];
      const userData = userDoc.data();

      console.log(`✅ [UsersService] Usuário encontrado: ${userDoc.id}`);

      return {
        id: userDoc.id,
        cpf: userData.cpf,
        email: userData.email,
        full_name: userData.full_name || userData.name,
        phone: userData.phone,
        ...userData,
      };
    } catch (error: any) {
      console.error(`❌ [UsersService] Erro ao buscar usuário por telefone:`, {
        message: error.message,
        code: error.code,
        details: error.details,
        stack: error.stack,
      });

      // Se for erro de permissão, pode ser problema de:
      // 1. Permissões IAM do serviço Cloud Run (precisa de roles/datastore.user ou roles/firebase.admin)
      // 2. ProjectId incorreto
      // 3. Admin SDK não inicializado corretamente
      if (error.code === 7 || error.code === 'PERMISSION_DENIED' || error.message?.includes('Permission denied') || error.message?.includes('PERMISSION_DENIED')) {
        console.error(`🚨 [UsersService] ERRO DE PERMISSÃO DETECTADO`);
        console.error(`🚨 [UsersService] Possíveis causas:`);
        console.error(`   1. Serviço Cloud Run não tem permissão IAM (roles/datastore.user)`);
        console.error(`   2. ProjectId incorreto`);
        console.error(`   3. Admin SDK não inicializado corretamente`);
        throw new BadRequestException('Erro de permissão ao acessar Firestore. Verifique as permissões IAM do serviço Cloud Run e a configuração do Admin SDK.');
      }

      throw new BadRequestException(`Erro ao buscar usuário: ${error.message}`);
    }
  }

  /**
   * Buscar usuário por ID no Firestore
   */
  async findById(userId: string) {
    try {
      const userDoc = await this.db.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        throw new NotFoundException('Usuário não encontrado');
      }

      return {
        id: userDoc.id,
        ...userDoc.data(),
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new BadRequestException(`Erro ao buscar usuário: ${error.message}`);
    }
  }

  /**
   * Verificar se CPF existe (sem retornar dados sensíveis)
   */
  async checkByCpf(cpf: string) {
    try {
      await this.findByCpf(cpf);
      return { exists: true };
    } catch (error) {
      if (error instanceof NotFoundException) {
        return { exists: false };
      }
      throw error;
    }
  }

  /**
   * Criar usuário no Firestore
   */
  async create(createUserDto: any) {
    try {
      // Normalizar CPF
      const normalizedCpf = createUserDto.cpf.replace(/\D/g, '');

      // Verificar se já existe
      try {
        await this.findByCpf(normalizedCpf);
        throw new BadRequestException('CPF já cadastrado');
      } catch (error) {
        if (!(error instanceof NotFoundException)) {
          throw error;
        }
      }

      // Criar usuário no Firestore
      const userData = {
        cpf: normalizedCpf,
        email: createUserDto.email?.toLowerCase(),
        full_name: createUserDto.full_name || createUserDto.name,
        phone: createUserDto.phone?.replace(/\D/g, ''),
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };

      const userRef = await this.db.collection('users').add(userData);

      return {
        id: userRef.id,
        ...userData,
      };
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      throw new BadRequestException(`Erro ao criar usuário: ${error.message}`);
    }
  }

  /**
   * Atualizar usuário no Firestore
   */
  async update(userId: string, updateUserDto: any) {
    try {
      const userRef = this.db.collection('users').doc(userId);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw new NotFoundException('Usuário não encontrado');
      }

      const updateData: any = {
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      };

      if (updateUserDto.full_name) updateData.full_name = updateUserDto.full_name;
      if (updateUserDto.email) updateData.email = updateUserDto.email.toLowerCase();
      if (updateUserDto.phone) updateData.phone = updateUserDto.phone.replace(/\D/g, '');

      await userRef.update(updateData);

      const updatedDoc = await userRef.get();
      return {
        id: updatedDoc.id,
        ...updatedDoc.data(),
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new BadRequestException(`Erro ao atualizar usuário: ${error.message}`);
    }
  }

  /**
   * Remover usuário (soft delete)
   */
  async remove(userId: string) {
    try {
      const userRef = this.db.collection('users').doc(userId);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw new NotFoundException('Usuário não encontrado');
      }

      await userRef.update({
        deleted_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, message: 'Usuário removido com sucesso' };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new BadRequestException(`Erro ao remover usuário: ${error.message}`);
    }
  }

  /**
   * Deletar todos os dados de um usuário (hard delete completo)
   * 
   * Esta função realiza uma limpeza completa dos dados do usuário:
   * 1. Deleta todos os arquivos do Storage (documentos KYC)
   * 2. Deleta a conta de autenticação do Firebase Auth (se existir)
   * 3. Deleta o documento do usuário na collection `users` do Firestore
   * 
   * **ATENÇÃO:** Esta operação é irreversível!
   */
  async deleteUserDataComplete(userId: string) {
    try {
      console.log(`🗑️ [UsersService] Iniciando limpeza completa dos dados do usuário: ${userId}`);

      // 1. Buscar o documento do usuário para obter informações (como ownerUid)
      const userRef = this.db.collection('users').doc(userId);
      const userDoc = await userRef.get();

      if (!userDoc.exists) {
        throw new NotFoundException('Usuário não encontrado no Firestore');
      }

      const userData = userDoc.data()!;
      const ownerUid = userData['ownerUid'] as string | undefined;

      console.log(`📄 [UsersService] Documento encontrado. ownerUid: ${ownerUid || 'não vinculado'}`);

      const results = {
        storageDeleted: false,
        authDeleted: false,
        firestoreDeleted: false,
      };

      // 2. Deletar arquivos do Storage (documentos KYC)
      try {
        console.log('📦 [UsersService] Deletando arquivos do Storage...');
        const bucket = admin.storage().bucket();
        const folderPath = `users/${userId}/kyc`;
        
        const [files] = await bucket.getFiles({ prefix: folderPath });
        
        if (files.length > 0) {
          await Promise.all(files.map(file => file.delete()));
          console.log(`✅ [UsersService] ${files.length} arquivo(s) do Storage deletado(s)`);
        } else {
          console.log('ℹ️ [UsersService] Nenhum arquivo encontrado no Storage');
        }
        results.storageDeleted = true;
      } catch (error) {
        console.warn(`⚠️ [UsersService] Erro ao deletar arquivos do Storage (continuando): ${error.message}`);
        // Continua mesmo se falhar, pois pode não haver arquivos
      }

      // 3. Deletar conta do Firebase Auth (se existir)
      if (ownerUid) {
        try {
          console.log(`🔐 [UsersService] Deletando conta do Firebase Auth (UID: ${ownerUid})...`);
          await admin.auth().deleteUser(ownerUid);
          console.log('✅ [UsersService] Conta do Firebase Auth deletada');
          results.authDeleted = true;
        } catch (error: any) {
          // Se o usuário não existir no Auth, não é um erro crítico
          if (error.code === 'auth/user-not-found') {
            console.log('ℹ️ [UsersService] Usuário não encontrado no Firebase Auth (pode já ter sido deletado)');
          } else {
            console.warn(`⚠️ [UsersService] Erro ao deletar conta do Firebase Auth (continuando): ${error.message}`);
          }
        }
      } else {
        console.log('ℹ️ [UsersService] Usuário não possui conta no Firebase Auth (ownerUid não encontrado)');
      }

      // 4. Deletar documento do Firestore
      try {
        console.log('🗄️ [UsersService] Deletando documento do Firestore...');
        await userRef.delete();
        console.log('✅ [UsersService] Documento do Firestore deletado');
        results.firestoreDeleted = true;
      } catch (error) {
        console.error(`❌ [UsersService] Erro ao deletar documento do Firestore: ${error.message}`);
        throw new BadRequestException(`Erro ao deletar documento do Firestore: ${error.message}`);
      }

      console.log('✅ [UsersService] Limpeza completa dos dados do usuário concluída com sucesso');

      return {
        success: true,
        message: 'Dados do usuário deletados com sucesso',
        details: results,
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      console.error(`❌ [UsersService] Erro durante limpeza dos dados do usuário: ${error.message}`);
      throw new BadRequestException(`Erro ao deletar dados do usuário: ${error.message}`);
    }
  }

  /**
   * Verificar senha (delegado para Firebase Auth)
   */
  async verifyPassword(verifyPasswordDto: any) {
    // Esta funcionalidade deve ser feita no frontend usando Firebase Auth
    throw new BadRequestException('Verificação de senha deve ser feita via Firebase Auth no frontend');
  }

  /**
   * Sincronizar email do Firebase com Firestore
   */
  async syncFirebaseEmail(cpf: string, oldEmail: string) {
    try {
      const user = await this.findByCpf(cpf);
      
      // Buscar usuário no Firebase Auth pelo email antigo
      let firebaseUser;
      try {
        firebaseUser = await admin.auth().getUserByEmail(oldEmail);
      } catch (error) {
        throw new NotFoundException('Usuário não encontrado no Firebase Auth');
      }

      // Atualizar email no Firestore
      await this.db.collection('users').doc(user.id).update({
        email: firebaseUser.email,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, message: 'Email sincronizado com sucesso' };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new BadRequestException(`Erro ao sincronizar email: ${error.message}`);
    }
  }

  /**
   * Obter dados da loja (stub - implementar se necessário)
   */
  async getStoreData(userId: string) {
    try {
      const storeDoc = await this.db.collection('user_stores').doc(userId).get();
      
      if (!storeDoc.exists) {
        throw new NotFoundException('Dados da loja não encontrados');
      }

      return {
        id: storeDoc.id,
        ...storeDoc.data(),
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new BadRequestException(`Erro ao buscar dados da loja: ${error.message}`);
    }
  }

  /**
   * Criar ou atualizar dados da loja
   */
  async upsertStoreData(userId: string, storeDataDto: any) {
    try {
      const storeRef = this.db.collection('user_stores').doc(userId);
      
      await storeRef.set({
        ...storeDataDto,
        user_id: userId,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });

      const storeDoc = await storeRef.get();
      return {
        id: storeDoc.id,
        ...storeDoc.data(),
      };
    } catch (error) {
      throw new BadRequestException(`Erro ao salvar dados da loja: ${error.message}`);
    }
  }

  /**
   * Obter chaves PIX (stub - implementar se necessário)
   */
  async getPixKeys(userId: string) {
    try {
      const pixKeysRef = this.db.collection('user_pix_keys').where('user_id', '==', userId);
      const snapshot = await pixKeysRef.get();

      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));
    } catch (error) {
      throw new BadRequestException(`Erro ao buscar chaves PIX: ${error.message}`);
    }
  }

  /**
   * Adicionar chave PIX (stub - implementar se necessário)
   */
  async addPixKey(userId: string, createPixKeyDto: any) {
    try {
      const pixKeyRef = await this.db.collection('user_pix_keys').add({
        user_id: userId,
        ...createPixKeyDto,
        created_at: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });

      const pixKeyDoc = await pixKeyRef.get();
      return {
        id: pixKeyDoc.id,
        ...pixKeyDoc.data(),
      };
    } catch (error) {
      throw new BadRequestException(`Erro ao adicionar chave PIX: ${error.message}`);
    }
  }

  /**
   * Remover chave PIX (stub - implementar se necessário)
   */
  async removePixKey(userId: string, keyId: string) {
    try {
      const pixKeyRef = this.db.collection('user_pix_keys').doc(keyId);
      const pixKeyDoc = await pixKeyRef.get();

      if (!pixKeyDoc.exists) {
        throw new NotFoundException('Chave PIX não encontrada');
      }

      const pixKeyData = pixKeyDoc.data();
      if (pixKeyData?.user_id !== userId) {
        throw new BadRequestException('Chave PIX não pertence ao usuário');
      }

      await pixKeyRef.delete();

      return { success: true, message: 'Chave PIX removida com sucesso' };
    } catch (error) {
      if (error instanceof NotFoundException || error instanceof BadRequestException) {
        throw error;
      }
      throw new BadRequestException(`Erro ao remover chave PIX: ${error.message}`);
    }
  }

  /**
   * Atualizar último login do usuário
   */
  async updateLastLogin(userId: string) {
    try {
      const userRef = this.db.collection('users').doc(userId);
      await userRef.update({
        last_login: admin.firestore.FieldValue.serverTimestamp(),
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return { success: true };
    } catch (error) {
      console.error(`Erro ao atualizar último login: ${error.message}`);
      // Não lançar erro - não é crítico
      return { success: false };
    }
  }
}
