import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import * as crypto from 'crypto';
import { FirestoreRestService } from '../firebase-rest/firestore-rest.service';
import { AuthJwtService } from '../firebase-rest/auth-jwt.service';
import { StorageRestService } from '../firebase-rest/storage-rest.service';
import { serverTimestamp } from '../firebase-rest/firestore-rest.utils';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class UsersService {
  constructor(
    private readonly firestore: FirestoreRestService,
    private readonly authJwt: AuthJwtService,
    private readonly storage: StorageRestService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Buscar usuario por CPF no Firestore
   */
  async findByCpf(cpf: string) {
    try {
      // Normalizar CPF (remover formatacao)
      const normalizedCpf = cpf.replace(/\D/g, '');

      // Buscar no Firestore
      const results = await this.firestore.query('users', {
        where: [{ field: 'cpf', op: '==', value: normalizedCpf }],
        limit: 1,
      });

      if (results.length === 0) {
        throw new NotFoundException('Usuario nao encontrado');
      }

      const userDoc = results[0];
      const userData = userDoc.data;

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
      throw new BadRequestException(`Erro ao buscar usuario: ${error.message}`);
    }
  }

  /**
   * Buscar usuario por email no Firestore
   */
  async findByEmail(email: string) {
    try {
      const results = await this.firestore.query('users', {
        where: [{ field: 'email', op: '==', value: email.toLowerCase() }],
        limit: 1,
      });

      if (results.length === 0) {
        throw new NotFoundException('Usuario nao encontrado');
      }

      const userDoc = results[0];
      const userData = userDoc.data;

      return {
        id: userDoc.id,
        ...userData,
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new BadRequestException(`Erro ao buscar usuario: ${error.message}`);
    }
  }

  /**
   * Buscar usuario por telefone no Firestore
   */
  async findByPhone(phone: string) {
    try {
      // Normalizar telefone (remover formatacao)
      const normalizedPhone = phone.replace(/\D/g, '');

      console.log(`[UsersService] Buscando usuario por telefone: ${normalizedPhone.substring(0, 4)}****`);

      const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID', 'pagpagapp');
      console.log(`[UsersService] Project ID: ${projectId}`);

      // O telefone e salvo como phoneHash (SHA-256) no Firestore
      // Precisamos gerar o hash do telefone normalizado para buscar
      const phoneHash = crypto.createHash('sha256').update(normalizedPhone).digest('hex');
      console.log(`[UsersService] Hash do telefone gerado: ${phoneHash.substring(0, 16)}...`);
      console.log(`[UsersService] Executando query no Firestore por phoneHash...`);

      const results = await this.firestore.query('users', {
        where: [{ field: 'phoneHash', op: '==', value: phoneHash }],
        limit: 1,
      });

      console.log(`[UsersService] Query executada. Documentos encontrados: ${results.length}`);

      if (results.length === 0) {
        console.log(`[UsersService] Usuario nao encontrado para telefone: ${normalizedPhone.substring(0, 4)}****`);
        return null;
      }

      const userDoc = results[0];
      const userData = userDoc.data;

      console.log(`[UsersService] Usuario encontrado: ${userDoc.id}`);

      return {
        id: userDoc.id,
        cpf: userData.cpf,
        email: userData.email,
        full_name: userData.full_name || userData.name,
        phone: userData.phone,
        ...userData,
      };
    } catch (error: any) {
      console.error(`[UsersService] Erro ao buscar usuario por telefone:`, {
        message: error.message,
        code: error.code,
        details: error.details,
        stack: error.stack,
      });

      if (error.code === 7 || error.code === 'PERMISSION_DENIED' || error.message?.includes('Permission denied') || error.message?.includes('PERMISSION_DENIED')) {
        console.error(`[UsersService] ERRO DE PERMISSAO DETECTADO`);
        throw new BadRequestException('Erro de permissao ao acessar Firestore. Verifique as permissoes IAM do servico Cloud Run e a configuracao do Admin SDK.');
      }

      throw new BadRequestException(`Erro ao buscar usuario: ${error.message}`);
    }
  }

  /**
   * Buscar usuario por ID no Firestore
   */
  async findById(userId: string) {
    try {
      const userDoc = await this.firestore.getDocument('users', userId);

      if (!userDoc) {
        throw new NotFoundException('Usuario nao encontrado');
      }

      return {
        id: userDoc.id,
        ...userDoc.data,
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new BadRequestException(`Erro ao buscar usuario: ${error.message}`);
    }
  }

  /**
   * Verificar se CPF existe (sem retornar dados sensiveis)
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
   * Criar usuario no Firestore
   */
  async create(createUserDto: any) {
    try {
      // Normalizar CPF
      const normalizedCpf = createUserDto.cpf.replace(/\D/g, '');

      // Verificar se ja existe
      try {
        await this.findByCpf(normalizedCpf);
        throw new BadRequestException('CPF ja cadastrado');
      } catch (error) {
        if (!(error instanceof NotFoundException)) {
          throw error;
        }
      }

      // Criar usuario no Firestore
      const userData = {
        cpf: normalizedCpf,
        email: createUserDto.email?.toLowerCase(),
        full_name: createUserDto.full_name || createUserDto.name,
        phone: createUserDto.phone?.replace(/\D/g, ''),
        created_at: serverTimestamp(),
        updated_at: serverTimestamp(),
      };

      const userRef = await this.firestore.addDocument('users', userData);

      return {
        id: userRef.id,
        ...userData,
      };
    } catch (error) {
      if (error instanceof BadRequestException) {
        throw error;
      }
      throw new BadRequestException(`Erro ao criar usuario: ${error.message}`);
    }
  }

  /**
   * Atualizar usuario no Firestore
   */
  async update(userId: string, updateUserDto: any) {
    try {
      const userDoc = await this.firestore.getDocument('users', userId);

      if (!userDoc) {
        throw new NotFoundException('Usuario nao encontrado');
      }

      const updateData: any = {
        updated_at: serverTimestamp(),
      };

      if (updateUserDto.full_name) updateData.full_name = updateUserDto.full_name;
      if (updateUserDto.email) updateData.email = updateUserDto.email.toLowerCase();
      if (updateUserDto.phone) updateData.phone = updateUserDto.phone.replace(/\D/g, '');

      await this.firestore.updateDocument('users', userId, updateData);

      const updatedDoc = await this.firestore.getDocument('users', userId);
      return {
        id: updatedDoc!.id,
        ...updatedDoc!.data,
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new BadRequestException(`Erro ao atualizar usuario: ${error.message}`);
    }
  }

  /**
   * Remover usuario (soft delete)
   */
  async remove(userId: string) {
    try {
      const userDoc = await this.firestore.getDocument('users', userId);

      if (!userDoc) {
        throw new NotFoundException('Usuario nao encontrado');
      }

      await this.firestore.updateDocument('users', userId, {
        deleted_at: serverTimestamp(),
        updated_at: serverTimestamp(),
      });

      return { success: true, message: 'Usuario removido com sucesso' };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      throw new BadRequestException(`Erro ao remover usuario: ${error.message}`);
    }
  }

  /**
   * Deletar todos os dados de um usuario (hard delete completo)
   *
   * Esta funcao realiza uma limpeza completa dos dados do usuario:
   * 1. Deleta todos os arquivos do Storage (documentos KYC)
   * 2. Deleta o documento do usuario na collection `users` do Firestore
   *
   * **ATENCAO:** Esta operacao e irreversivel!
   */
  async deleteUserDataComplete(userId: string) {
    try {
      console.log(`[UsersService] Iniciando limpeza completa dos dados do usuario: ${userId}`);

      // 1. Buscar o documento do usuario para obter informacoes
      const userDoc = await this.firestore.getDocument('users', userId);

      if (!userDoc) {
        throw new NotFoundException('Usuario nao encontrado no Firestore');
      }

      const userData = userDoc.data;
      const ownerUid = userData['ownerUid'] as string | undefined;

      console.log(`[UsersService] Documento encontrado. ownerUid: ${ownerUid || 'nao vinculado'}`);

      const results = {
        storageDeleted: false,
        authDeleted: false,
        firestoreDeleted: false,
      };

      // 2. Deletar arquivos do Storage (documentos KYC)
      try {
        console.log('[UsersService] Deletando arquivos do Storage...');
        const folderPath = `users/${userId}/kyc`;
        const deletedCount = await this.storage.deleteFolder(folderPath);
        console.log(`[UsersService] ${deletedCount} arquivo(s) do Storage deletado(s)`);
        results.storageDeleted = true;
      } catch (error) {
        console.warn(`[UsersService] Erro ao deletar arquivos do Storage (continuando): ${error.message}`);
        // Continua mesmo se falhar, pois pode nao haver arquivos
      }

      // 3. Firebase Auth deletion skipped (no admin SDK, auth managed separately)
      if (ownerUid) {
        console.log(`[UsersService] ownerUid ${ownerUid} encontrado - auth deletion skipped (sem firebase-admin)`);
        // NOTE: Firebase Auth user deletion requires Admin SDK or Identity Toolkit REST API.
        // If needed in the future, implement via Google Identity Toolkit REST API.
        results.authDeleted = false;
      } else {
        console.log('[UsersService] Usuario nao possui conta no Firebase Auth (ownerUid nao encontrado)');
      }

      // 4. Deletar documento do Firestore
      try {
        console.log('[UsersService] Deletando documento do Firestore...');
        await this.firestore.deleteDocument('users', userId);
        console.log('[UsersService] Documento do Firestore deletado');
        results.firestoreDeleted = true;
      } catch (error) {
        console.error(`[UsersService] Erro ao deletar documento do Firestore: ${error.message}`);
        throw new BadRequestException(`Erro ao deletar documento do Firestore: ${error.message}`);
      }

      console.log('[UsersService] Limpeza completa dos dados do usuario concluida com sucesso');

      return {
        success: true,
        message: 'Dados do usuario deletados com sucesso',
        details: results,
      };
    } catch (error) {
      if (error instanceof NotFoundException) {
        throw error;
      }
      console.error(`[UsersService] Erro durante limpeza dos dados do usuario: ${error.message}`);
      throw new BadRequestException(`Erro ao deletar dados do usuario: ${error.message}`);
    }
  }

  /**
   * Verificar senha (delegado para Firebase Auth)
   */
  async verifyPassword(verifyPasswordDto: any) {
    // Esta funcionalidade deve ser feita no frontend usando Firebase Auth
    throw new BadRequestException('Verificacao de senha deve ser feita via Firebase Auth no frontend');
  }

  /**
   * Sincronizar email do Firebase com Firestore
   *
   * Since we no longer use firebase-admin, we look up the user by email
   * in Firestore instead of Firebase Auth.
   */
  async syncFirebaseEmail(cpf: string, oldEmail: string) {
    try {
      const user = await this.findByCpf(cpf);

      // Buscar usuario pelo email antigo no Firestore
      const emailResults = await this.firestore.query('users', {
        where: [{ field: 'email', op: '==', value: oldEmail.toLowerCase() }],
        limit: 1,
      });

      if (emailResults.length === 0) {
        throw new NotFoundException('Usuario nao encontrado com o email informado');
      }

      const foundUser = emailResults[0];

      // Atualizar email no Firestore
      await this.firestore.updateDocument('users', user.id, {
        email: foundUser.data.email,
        updated_at: serverTimestamp(),
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
   * Obter dados da loja (stub - implementar se necessario)
   */
  async getStoreData(userId: string) {
    try {
      const storeDoc = await this.firestore.getDocument('user_stores', userId);

      if (!storeDoc) {
        throw new NotFoundException('Dados da loja nao encontrados');
      }

      return {
        id: storeDoc.id,
        ...storeDoc.data,
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
      await this.firestore.setDocument('user_stores', userId, {
        ...storeDataDto,
        user_id: userId,
        updated_at: serverTimestamp(),
      }, true);

      const storeDoc = await this.firestore.getDocument('user_stores', userId);
      return {
        id: storeDoc!.id,
        ...storeDoc!.data,
      };
    } catch (error) {
      throw new BadRequestException(`Erro ao salvar dados da loja: ${error.message}`);
    }
  }

  /**
   * Obter chaves PIX (stub - implementar se necessario)
   */
  async getPixKeys(userId: string) {
    try {
      const results = await this.firestore.query('user_pix_keys', {
        where: [{ field: 'user_id', op: '==', value: userId }],
      });

      return results.map(doc => ({
        id: doc.id,
        ...doc.data,
      }));
    } catch (error) {
      throw new BadRequestException(`Erro ao buscar chaves PIX: ${error.message}`);
    }
  }

  /**
   * Adicionar chave PIX (stub - implementar se necessario)
   */
  async addPixKey(userId: string, createPixKeyDto: any) {
    try {
      const pixKeyRef = await this.firestore.addDocument('user_pix_keys', {
        user_id: userId,
        ...createPixKeyDto,
        created_at: serverTimestamp(),
        updated_at: serverTimestamp(),
      });

      const pixKeyDoc = await this.firestore.getDocument('user_pix_keys', pixKeyRef.id);
      return {
        id: pixKeyDoc!.id,
        ...pixKeyDoc!.data,
      };
    } catch (error) {
      throw new BadRequestException(`Erro ao adicionar chave PIX: ${error.message}`);
    }
  }

  /**
   * Remover chave PIX (stub - implementar se necessario)
   */
  async removePixKey(userId: string, keyId: string) {
    try {
      const pixKeyDoc = await this.firestore.getDocument('user_pix_keys', keyId);

      if (!pixKeyDoc) {
        throw new NotFoundException('Chave PIX nao encontrada');
      }

      if (pixKeyDoc.data?.user_id !== userId) {
        throw new BadRequestException('Chave PIX nao pertence ao usuario');
      }

      await this.firestore.deleteDocument('user_pix_keys', keyId);

      return { success: true, message: 'Chave PIX removida com sucesso' };
    } catch (error) {
      if (error instanceof NotFoundException || error instanceof BadRequestException) {
        throw error;
      }
      throw new BadRequestException(`Erro ao remover chave PIX: ${error.message}`);
    }
  }

  /**
   * Atualizar ultimo login do usuario
   */
  async updateLastLogin(userId: string) {
    try {
      await this.firestore.updateDocument('users', userId, {
        last_login: serverTimestamp(),
        updated_at: serverTimestamp(),
      });
      return { success: true };
    } catch (error) {
      console.error(`Erro ao atualizar ultimo login: ${error.message}`);
      // Nao lancar erro - nao e critico
      return { success: false };
    }
  }
}
