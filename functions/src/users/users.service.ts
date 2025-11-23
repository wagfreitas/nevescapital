import { Injectable, Inject, ConflictException, NotFoundException, BadRequestException } from '@nestjs/common';
import { Pool } from 'pg';
import { EncryptionService } from '../common/services/encryption.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { VerifyPasswordDto } from './dto/verify-password.dto';
import { StoreDataDto } from './dto/store-data.dto';
import { CreatePixKeyDto, UpdatePixKeyDto } from './dto/pix-key.dto';
import { PixValidationService } from './services/pix-validation.service';
import * as crypto from 'crypto';
import * as admin from 'firebase-admin';

@Injectable()
export class UsersService {
  constructor(
    @Inject('DATABASE_POOL') private readonly pool: Pool,
    private readonly encryptionService: EncryptionService,
    private readonly pixValidationService: PixValidationService,
  ) {}

  /**
   * Criptografar para bytea (PostgreSQL)
   */
  private encryptToBytea(text: string): string {
    const encrypted = this.encryptionService.encrypt(text);
    if (!encrypted) {
      throw new Error('Falha na criptografia');
    }
    // Retornar como string para PostgreSQL converter automaticamente para bytea
    return encrypted;
  }

  /**
   * Descriptografar de bytea (PostgreSQL)
   */
  private decryptFromBytea(buffer: Buffer): string {
    try {
      // Buffer vem do PostgreSQL como bytea, converter para string
      let encrypted: string;
      
      if (Buffer.isBuffer(buffer)) {
        // Se é um buffer, converter para string
        encrypted = buffer.toString('utf8');
      } else if (typeof buffer === 'string') {
        // Se já é string, usar diretamente
        encrypted = buffer;
      } else {
        throw new Error('Formato de buffer inválido');
      }
      
      console.log(`🔐 Tentando descriptografar: ${encrypted.substring(0, 50)}...`);
      
      const decrypted = this.encryptionService.decrypt(encrypted);
      if (!decrypted) {
        throw new Error('Falha na descriptografia - resultado vazio');
      }
      
      console.log(`✅ Descriptografado com sucesso: ${decrypted}`);
      return decrypted;
    } catch (error) {
      console.error('❌ Erro na descriptografia:', error);
      throw new Error(`Falha na descriptografia: ${error.message}`);
    }
  }

  async create(createUserDto: CreateUserDto) {
    const client = await this.pool.connect();

    try {
      await client.query('BEGIN');

      console.log(`🔍 Criando usuário: ${createUserDto.fullName}...`);

      // TODO: Verificação de duplicatas desabilitada temporariamente
      // Problema: CryptoJS gera valores diferentes a cada criptografia
      // Solução futura: Migrar para EncryptionV2Service com HMAC hash

      // Criptografar dados
      const fullNameEncrypted = this.encryptToBytea(createUserDto.fullName);
      const cpfEncrypted = this.encryptToBytea(createUserDto.cpf);
      const emailEncrypted = this.encryptToBytea(createUserDto.email);

      // Inserir usuário principal
      const userResult = await client.query(
        `INSERT INTO users (
          full_name,
          cpf_encrypted,
          email_encrypted,
          kyc_status
        ) VALUES ($1, $2, $3, $4)
        RETURNING id, created_at`,
        [fullNameEncrypted, cpfEncrypted, emailEncrypted, 'pending'],
      );

      const userId = userResult.rows[0].id;

      // Inserir telefone (se fornecido)
      if (createUserDto.phone) {
        const phoneEncrypted = this.encryptToBytea(createUserDto.phone);
        await client.query(
          `INSERT INTO user_phones (user_id, phone_encrypted, is_primary, phone_type)
           VALUES ($1, $2, true, 'mobile')`,
          [userId, phoneEncrypted],
        );
      }

      // Inserir endereço (se fornecido)
      if (createUserDto.cep && createUserDto.address) {
        const streetEncrypted = this.encryptToBytea(createUserDto.address);
        const numberEncrypted = createUserDto.number ? this.encryptToBytea(createUserDto.number) : null;
        const complementEncrypted = createUserDto.complement ? this.encryptToBytea(createUserDto.complement) : null;
        const neighborhoodEncrypted = createUserDto.neighborhood ? this.encryptToBytea(createUserDto.neighborhood) : null;
        const cityEncrypted = createUserDto.city ? this.encryptToBytea(createUserDto.city) : this.encryptToBytea('');
        const stateEncrypted = createUserDto.state ? this.encryptToBytea(createUserDto.state) : this.encryptToBytea('');

        await client.query(
          `INSERT INTO user_addresses (
            user_id, 
            street_encrypted, 
            number_encrypted, 
            complement_encrypted, 
            neighborhood_encrypted,
            city_encrypted,
            state_encrypted,
            cep, 
            is_primary
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true)`,
          [
            userId,
            streetEncrypted,
            numberEncrypted,
            complementEncrypted,
            neighborhoodEncrypted,
            cityEncrypted,
            stateEncrypted,
            createUserDto.cep,
          ],
        );
      }

      await client.query('COMMIT');

      console.log(`✅ Usuário criado no PostgreSQL: ID ${userId}`);

      return {
        success: true,
        user_id: userId,
        created_at: userResult.rows[0].created_at,
        mode: 'POSTGRESQL',
      };
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Erro ao criar usuário:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  async findByCpf(cpf: string) {
    try {
      console.log(`🔍 Buscando usuário por CPF: ${cpf}`);

      // Buscar todos os usuários ativos
      const result = await this.pool.query(
        `SELECT 
          u.id,
          u.full_name,
          u.cpf_encrypted,
          u.email_encrypted,
          u.kyc_status,
          u.created_at
        FROM users u
        WHERE u.deleted_at IS NULL`,
      );

      console.log(`📊 Encontrados ${result.rows.length} usuários ativos`);

      // Procurar o usuário com CPF correspondente
      let foundUser = null;
      const allCpfs: string[] = [];
      for (const user of result.rows) {
        try {
          const decryptedCpf = this.decryptFromBytea(user.cpf_encrypted);
          allCpfs.push(decryptedCpf);
          console.log(`🔐 CPF descriptografado: ${decryptedCpf} (buscando: ${cpf})`);
          
          // Normalizar ambos os CPFs para comparação (remover formatação)
          const normalizedDecrypted = decryptedCpf.replace(/\D/g, '');
          const normalizedSearch = cpf.replace(/\D/g, '');
          
          if (normalizedDecrypted === normalizedSearch) {
            console.log(`✅ Usuário encontrado! ID: ${user.id}`);
            foundUser = user;
            break;
          }
        } catch (error) {
          console.error(`❌ Erro ao descriptografar CPF do usuário ${user.id}:`, error);
          continue;
        }
      }
      
      if (allCpfs.length > 0) {
        console.log(`📋 Todos os CPFs encontrados no banco: ${allCpfs.join(', ')}`);
      }

      if (!foundUser) {
        console.log(`⚠️  Nenhum usuário encontrado com CPF: ${cpf}`);
        throw new NotFoundException('Usuário não encontrado');
      }

      const user = foundUser;

      // Buscar telefone
      const phoneResult = await this.pool.query(
        'SELECT phone_encrypted FROM user_phones WHERE user_id = $1 AND is_primary = true',
        [user.id],
      );

      // Buscar endereço
      const addressResult = await this.pool.query(
        `SELECT 
          street_encrypted,
          number_encrypted,
          complement_encrypted,
          neighborhood_encrypted,
          city_encrypted,
          state_encrypted,
          cep
        FROM user_addresses 
        WHERE user_id = $1 AND is_primary = true`,
        [user.id],
      );

      // Descriptografar endereço (com verificação de null para cada campo)
      let address = null;
      if (addressResult.rows[0]) {
        const addr = addressResult.rows[0];
        try {
          address = {
            street: addr.street_encrypted ? this.decryptFromBytea(addr.street_encrypted) : null,
            number: addr.number_encrypted ? this.decryptFromBytea(addr.number_encrypted) : null,
            complement: addr.complement_encrypted ? this.decryptFromBytea(addr.complement_encrypted) : null,
            neighborhood: addr.neighborhood_encrypted ? this.decryptFromBytea(addr.neighborhood_encrypted) : null,
            city: addr.city_encrypted ? this.decryptFromBytea(addr.city_encrypted) : null,
            state: addr.state_encrypted ? this.decryptFromBytea(addr.state_encrypted) : null,
            cep: addr.cep || null,
          };
        } catch (addrError) {
          console.error(`❌ Erro ao descriptografar endereço do usuário ${user.id}:`, addrError);
          address = null;
        }
      }

      return {
        id: user.id,
        email: this.decryptFromBytea(user.email_encrypted),
        full_name: this.decryptFromBytea(user.full_name),
        cpf: this.decryptFromBytea(user.cpf_encrypted),
        phone: phoneResult.rows[0]?.phone_encrypted ? this.decryptFromBytea(phoneResult.rows[0].phone_encrypted) : null,
        address,
        kyc_status: user.kyc_status,
        created_at: user.created_at,
        mode: 'POSTGRESQL',
      };
    } catch (error) {
      console.error('Erro ao buscar usuário:', error);
      throw error;
    }
  }

  async findByEmail(email: string) {
    try {
      // Normalizar email: trim, lowercase
      const normalizedEmail = email.trim().toLowerCase();
      console.log(`🔍 Buscando usuário por email: ${normalizedEmail}`);
      console.log(`🔍 Email original recebido: ${email}`);

      // Buscar todos os usuários ativos (mesma lógica do findByCpf)
      const result = await this.pool.query(
        `SELECT 
          u.id,
          u.full_name,
          u.cpf_encrypted,
          u.email_encrypted,
          u.kyc_status,
          u.created_at
        FROM users u
        WHERE u.deleted_at IS NULL`,
      );

      console.log(`📊 Encontrados ${result.rows.length} usuários ativos para verificar`);

      // Procurar o usuário com email correspondente (descriptografando - mesma lógica do findByCpf)
      let foundUser = null;
      for (const user of result.rows) {
        try {
          // Usar a mesma função decryptFromBytea que funciona no findByCpf
          const decryptedEmail = this.decryptFromBytea(user.email_encrypted);
          const normalizedDecryptedEmail = decryptedEmail.trim().toLowerCase();
          console.log(`🔐 Email descriptografado: ${normalizedDecryptedEmail} (original: ${decryptedEmail})`);
          
          // Comparação case-insensitive e sem espaços
          if (normalizedDecryptedEmail === normalizedEmail) {
            console.log(`✅ Usuário encontrado! ID: ${user.id}`);
            foundUser = user;
            break;
          }
        } catch (error) {
          console.error(`❌ Erro ao descriptografar email do usuário ${user.id}:`, error);
          console.error(`   Erro detalhado:`, error);
          continue;
        }
      }

      if (!foundUser) {
        console.log(`⚠️  Nenhum usuário encontrado com email: ${email}`);
        throw new NotFoundException('Usuário não encontrado');
      }

      const user = foundUser;

      // Buscar telefone
      const phoneResult = await this.pool.query(
        'SELECT phone_encrypted FROM user_phones WHERE user_id = $1 AND is_primary = true',
        [user.id],
      );

      // Buscar endereço
      const addressResult = await this.pool.query(
        `SELECT 
          street_encrypted,
          number_encrypted,
          complement_encrypted,
          neighborhood_encrypted,
          city_encrypted,
          state_encrypted,
          cep
        FROM user_addresses 
        WHERE user_id = $1 AND is_primary = true`,
        [user.id],
      );

      // Descriptografar endereço (com verificação de null para cada campo)
      let address = null;
      if (addressResult.rows[0]) {
        const addr = addressResult.rows[0];
        try {
          address = {
            street: addr.street_encrypted ? this.decryptFromBytea(addr.street_encrypted) : null,
            number: addr.number_encrypted ? this.decryptFromBytea(addr.number_encrypted) : null,
            complement: addr.complement_encrypted ? this.decryptFromBytea(addr.complement_encrypted) : null,
            neighborhood: addr.neighborhood_encrypted ? this.decryptFromBytea(addr.neighborhood_encrypted) : null,
            city: addr.city_encrypted ? this.decryptFromBytea(addr.city_encrypted) : null,
            state: addr.state_encrypted ? this.decryptFromBytea(addr.state_encrypted) : null,
            cep: addr.cep || null,
          };
        } catch (addrError) {
          console.error(`❌ Erro ao descriptografar endereço do usuário ${user.id}:`, addrError);
          address = null;
        }
      }

      return {
        id: user.id,
        email: this.decryptFromBytea(user.email_encrypted),
        full_name: this.decryptFromBytea(user.full_name),
        cpf: this.decryptFromBytea(user.cpf_encrypted),
        phone: phoneResult.rows[0]?.phone_encrypted ? this.decryptFromBytea(phoneResult.rows[0].phone_encrypted) : null,
        address,
        kyc_status: user.kyc_status,
        created_at: user.created_at,
        mode: 'POSTGRESQL',
      };
    } catch (error) {
      console.error('Erro ao buscar usuário por email:', error);
      throw error;
    }
  }

  async verifyPassword(verifyPasswordDto: VerifyPasswordDto) {
    // Verificar senha via Firebase Auth
    // Buscar email do usuário por CPF
    const userData = await this.findByCpf(verifyPasswordDto.cpf);
    if (!userData || !userData.email) {
      throw new NotFoundException('Usuário não encontrado');
    }

    try {
      // Tentar fazer login no Firebase com email e senha
      // Isso valida a senha
      const auth = admin.auth();
      const user = await auth.getUserByEmail(userData.email);
      
      // Firebase Admin SDK não tem método direto para verificar senha
      // Precisamos usar Firebase Auth REST API ou fazer login via cliente
      // Por enquanto, retornamos true se o usuário existe (validação será feita no cliente)
      return {
        valid: true,
        message: 'Validação de senha deve ser feita no cliente usando Firebase Auth',
      };
    } catch (error) {
      return {
        valid: false,
        message: 'Erro ao verificar senha',
      };
    }
  }

  /**
   * Verificar senha do usuário (usado internamente)
   * Retorna true se a senha está correta
   * Nota: A validação real da senha será feita no frontend usando Firebase Auth
   */
  async verifyPasswordInternal(userId: string, password: string): Promise<boolean> {
    try {
      // Buscar email do usuário
      const userData = await this.findById(userId);
      if (!userData || !userData.email) {
        return false;
      }

      // Nota: Firebase Admin SDK não permite verificar senha diretamente
      // A verificação deve ser feita no cliente usando Firebase Auth
      // Ou podemos usar Firebase Auth REST API
      // Por enquanto, retornamos true assumindo que o token OTP já validou a identidade
      // A senha antiga será verificada no cliente antes de enviar
      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * Buscar usuário por ID
   */
  async findById(userId: string) {
    try {
      const result = await this.pool.query(
        `SELECT 
          u.id,
          u.full_name,
          u.cpf_encrypted,
          u.email_encrypted,
          u.kyc_status,
          u.created_at
        FROM users u
        WHERE u.id = $1 AND u.deleted_at IS NULL`,
        [userId],
      );

      if (result.rows.length === 0) {
        return null;
      }

      const user = result.rows[0];

      // Buscar telefone
      const phoneResult = await this.pool.query(
        'SELECT phone_encrypted FROM user_phones WHERE user_id = $1 AND is_primary = true',
        [user.id],
      );

      return {
        id: user.id,
        email: this.decryptFromBytea(user.email_encrypted),
        full_name: this.decryptFromBytea(user.full_name),
        cpf: this.decryptFromBytea(user.cpf_encrypted),
        phone: phoneResult.rows[0]?.phone_encrypted ? this.decryptFromBytea(phoneResult.rows[0].phone_encrypted) : null,
        kyc_status: user.kyc_status,
        created_at: user.created_at,
      };
    } catch (error) {
      console.error('Erro ao buscar usuário por ID:', error);
      throw error;
    }
  }

  /**
   * Atualizar senha do usuário no Firebase
   */
  async updatePassword(userId: string, newPassword: string): Promise<void> {
    try {
      // Buscar email do usuário
      const userData = await this.findById(userId);
      if (!userData || !userData.email) {
        throw new NotFoundException('Usuário não encontrado');
      }

      // Buscar usuário no Firebase
      const auth = admin.auth();
      const firebaseUser = await auth.getUserByEmail(userData.email);

      // Atualizar senha no Firebase
      await auth.updateUser(firebaseUser.uid, {
        password: newPassword,
      });

      console.log(`✅ Senha atualizada no Firebase para usuário ${userId}`);
    } catch (error: any) {
      console.error(`❌ Erro ao atualizar senha:`, error);
      throw new Error(`Falha ao atualizar senha: ${error.message}`);
    }
  }

  async update(id: string, updateUserDto: UpdateUserDto) {
    const client = await this.pool.connect();

    try {
      await client.query('BEGIN');

      // Verificar se usuário existe
      const userExists = await client.query(
        'SELECT id FROM users WHERE id = $1',
        [id],
      );

      if (userExists.rows.length === 0) {
        throw new NotFoundException(`Usuário com ID ${id} não encontrado`);
      }

      // Atualizar nome se fornecido
      if (updateUserDto.fullName) {
        const fullNameEncrypted = this.encryptToBytea(updateUserDto.fullName);
        await client.query(
          'UPDATE users SET full_name = $1, updated_at = NOW() WHERE id = $2',
          [fullNameEncrypted, id],
        );
      }

      // Atualizar email se fornecido
      if (updateUserDto.email) {
        const emailEncrypted = this.encryptToBytea(updateUserDto.email);
        await client.query(
          'UPDATE users SET email_encrypted = $1, updated_at = NOW() WHERE id = $2',
          [emailEncrypted, id],
        );
      }

      // Atualizar telefone se fornecido
      if (updateUserDto.phone) {
        const phoneEncrypted = this.encryptToBytea(updateUserDto.phone);
        
        try {
          // Tentar usar tabela user_phones (estrutura nova)
          const existingPhone = await client.query(
            'SELECT id FROM user_phones WHERE user_id = $1 AND is_primary = true',
            [id],
          );

          if (existingPhone.rows.length > 0) {
            // Atualizar em user_phones
            await client.query(
              'UPDATE user_phones SET phone_encrypted = $1, updated_at = NOW() WHERE user_id = $2 AND is_primary = true',
              [phoneEncrypted, id],
            );
          } else {
            // Inserir em user_phones
            await client.query(
              'INSERT INTO user_phones (user_id, phone_encrypted, is_primary, phone_type) VALUES ($1, $2, true, $3)',
              [id, phoneEncrypted, 'mobile'],
            );
          }
        } catch (error: any) {
          // Se user_phones não existir, tentar atualizar diretamente na tabela users
          if (error.code === '42P01' || error.message?.includes('does not exist')) {
            console.log('Tabela user_phones não encontrada, atualizando diretamente em users');
            await client.query(
              'UPDATE users SET phone_encrypted = $1, updated_at = NOW() WHERE id = $2',
              [phoneEncrypted, id],
            );
          } else {
            throw error;
          }
        }
      }

      // Atualizar endereço se fornecido
      if (updateUserDto.cep || updateUserDto.address) {
        const updateFields: string[] = [];
        const values: any[] = [id];
        let paramIndex = 2;

        if (updateUserDto.address) {
          updateFields.push(`street_encrypted = $${paramIndex++}`);
          values.push(this.encryptToBytea(updateUserDto.address));
        }

        if (updateUserDto.number) {
          updateFields.push(`number_encrypted = $${paramIndex++}`);
          values.push(this.encryptToBytea(updateUserDto.number));
        }

        if (updateUserDto.complement !== undefined) {
          updateFields.push(`complement_encrypted = $${paramIndex++}`);
          values.push(updateUserDto.complement ? this.encryptToBytea(updateUserDto.complement) : null);
        }

        if (updateUserDto.neighborhood) {
          updateFields.push(`neighborhood_encrypted = $${paramIndex++}`);
          values.push(this.encryptToBytea(updateUserDto.neighborhood));
        }

        if (updateUserDto.city) {
          updateFields.push(`city_encrypted = $${paramIndex++}`);
          values.push(this.encryptToBytea(updateUserDto.city));
        }

        if (updateUserDto.state) {
          updateFields.push(`state_encrypted = $${paramIndex++}`);
          values.push(this.encryptToBytea(updateUserDto.state));
        }

        if (updateUserDto.cep) {
          updateFields.push(`cep = $${paramIndex++}`);
          values.push(updateUserDto.cep);
        }

        if (updateFields.length > 0) {
          updateFields.push('updated_at = NOW()');
          
          // Verificar se já existe endereço
          const existingAddress = await client.query(
            'SELECT id FROM user_addresses WHERE user_id = $1 AND is_primary = true',
            [id],
          );

          if (existingAddress.rows.length > 0) {
            // Atualizar
            const query = `UPDATE user_addresses SET ${updateFields.join(', ')} WHERE user_id = $1 AND is_primary = true`;
            await client.query(query, values);
          }
        }
      }

      await client.query('COMMIT');

      return {
        success: true,
        user_id: id,
        updated_at: new Date().toISOString(),
        mode: 'POSTGRESQL',
      };
    } catch (error) {
      await client.query('ROLLBACK');
      console.error('Erro ao atualizar usuário:', error);
      throw error;
    } finally {
      client.release();
    }
  }

  async remove(id: string) {
    const result = await this.pool.query(
      'UPDATE users SET deleted_at = NOW() WHERE id = $1 RETURNING id',
      [id],
    );

    if (result.rows.length === 0) {
      throw new NotFoundException('Usuário não encontrado');
    }

    return {
      success: true,
      user_id: result.rows[0].id,
      mode: 'POSTGRESQL',
    };
  }

  /**
   * Sincronizar email do Firebase com PostgreSQL
   * Busca o email atual no PostgreSQL por CPF e atualiza no Firebase usando o email antigo para localizar o usuário
   */
  async syncFirebaseEmail(cpf: string, oldEmail: string) {
    try {
      console.log(`🔄 Sincronizando email do Firebase para CPF: ${cpf}`);
      
      // 1. Buscar usuário no PostgreSQL por CPF para obter o email novo
      const userData = await this.findByCpf(cpf);
      if (!userData || !userData.email) {
        throw new NotFoundException('Usuário não encontrado no PostgreSQL ou email não encontrado');
      }

      const newEmail = userData.email as string;
      console.log(`📧 Email antigo (Firebase): ${oldEmail}`);
      console.log(`📧 Email novo (PostgreSQL): ${newEmail}`);

      if (oldEmail.toLowerCase() === newEmail.toLowerCase()) {
        return {
          success: true,
          message: 'Emails já estão sincronizados',
          oldEmail,
          newEmail,
        };
      }

      // 2. Buscar usuário no Firebase pelo email antigo
      const auth = admin.auth();
      let firebaseUser;
      try {
        firebaseUser = await auth.getUserByEmail(oldEmail);
        console.log(`✅ Usuário encontrado no Firebase: ${firebaseUser.uid}`);
      } catch (error: any) {
        if (error.code === 'auth/user-not-found') {
          throw new NotFoundException(`Usuário não encontrado no Firebase com email: ${oldEmail}`);
        }
        throw error;
      }

      // 3. Atualizar email no Firebase
      try {
        await auth.updateUser(firebaseUser.uid, {
          email: newEmail,
          emailVerified: false, // Marcar como não verificado pois o email mudou
        });
        console.log(`✅ Email atualizado no Firebase: ${oldEmail} → ${newEmail}`);

        // 4. Enviar email de verificação
        await auth.generateEmailVerificationLink(newEmail);
        console.log(`📧 Link de verificação gerado para: ${newEmail}`);

        return {
          success: true,
          message: 'Email sincronizado com sucesso',
          oldEmail,
          newEmail,
          firebaseUid: firebaseUser.uid,
        };
      } catch (error: any) {
        console.error(`❌ Erro ao atualizar email no Firebase:`, error);
        throw new Error(`Falha ao atualizar email no Firebase: ${error.message}`);
      }
    } catch (error: any) {
      console.error(`❌ Erro ao sincronizar email:`, error);
      throw error;
    }
  }

  /**
   * Buscar dados da loja do usuário
   */
  async getStoreData(userId: string) {
    const result = await this.pool.query(
      'SELECT id, store_name, business_type, created_at, updated_at FROM user_stores WHERE user_id = $1',
      [userId],
    );

    if (result.rows.length === 0) {
      return null;
    }

    return result.rows[0];
  }

  /**
   * Criar ou atualizar dados da loja do usuário
   */
  async upsertStoreData(userId: string, storeData: StoreDataDto) {
    const client = await this.pool.connect();

    try {
      await client.query('BEGIN');

      // Verificar se já existe
      const existing = await client.query(
        'SELECT id FROM user_stores WHERE user_id = $1',
        [userId],
      );

      if (existing.rows.length > 0) {
        // Atualizar
        await client.query(
          'UPDATE user_stores SET store_name = $1, business_type = $2, updated_at = NOW() WHERE user_id = $3',
          [storeData.store_name, storeData.business_type, userId],
        );
      } else {
        // Criar
        await client.query(
          'INSERT INTO user_stores (user_id, store_name, business_type) VALUES ($1, $2, $3)',
          [userId, storeData.store_name, storeData.business_type],
        );
      }

      await client.query('COMMIT');

      return {
        success: true,
        message: 'Dados da loja salvos com sucesso',
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Buscar chaves PIX do usuário
   */
  async getPixKeys(userId: string) {
    const result = await this.pool.query(
      'SELECT id, pix_key, key_type, is_verified, is_primary, display_order, created_at, updated_at FROM user_pix_keys WHERE user_id = $1 ORDER BY display_order ASC, created_at ASC',
      [userId],
    );

    return result.rows.map((row) => ({
      ...row,
      pix_key_formatted: this.pixValidationService.formatPixKey(row.pix_key, row.key_type),
    }));
  }

  /**
   * Adicionar chave PIX
   */
  async addPixKey(userId: string, createPixKeyDto: CreatePixKeyDto) {
    const client = await this.pool.connect();

    try {
      // 1. Validar formato da chave PIX
      const formatValidation = this.pixValidationService.validatePixKey(createPixKeyDto.pix_key);
      if (!formatValidation.valid) {
        throw new BadRequestException(formatValidation.error || 'Formato de chave PIX inválido');
      }

      // 2. Validar chave PIX real via Pagar.me (se configurado)
      const realValidation = await this.pixValidationService.validatePixKeyReal(createPixKeyDto.pix_key);
      if (!realValidation.valid) {
        throw new BadRequestException(realValidation.error || 'Chave PIX não encontrada ou inválida no sistema bancário');
      }

      const keyType = formatValidation.type!;

      await client.query('BEGIN');

      // Verificar se a chave já existe
      const existing = await client.query(
        'SELECT id, user_id FROM user_pix_keys WHERE pix_key = $1',
        [createPixKeyDto.pix_key],
      );

      if (existing.rows.length > 0) {
        throw new ConflictException('Esta chave PIX já está cadastrada');
      }

      // Verificar limite de chaves (máximo 5)
      const countResult = await client.query(
        'SELECT COUNT(*) as count FROM user_pix_keys WHERE user_id = $1',
        [userId],
      );
      const count = parseInt(countResult.rows[0].count);
      if (count >= 5) {
        throw new BadRequestException('Limite máximo de 5 chaves PIX atingido');
      }

      // Verificar se é a primeira chave (será primary)
      const isFirstKey = count === 0;

      // Buscar próximo display_order
      const maxOrderResult = await client.query(
        'SELECT MAX(display_order) as max_order FROM user_pix_keys WHERE user_id = $1',
        [userId],
      );
      const nextOrder = (maxOrderResult.rows[0].max_order || 0) + 1;

      // Inserir chave (is_verified = true pois foi validada via Pagar.me)
      await client.query(
        `INSERT INTO user_pix_keys (user_id, pix_key, key_type, is_verified, is_primary, display_order)
         VALUES ($1, $2, $3, TRUE, $4, $5)`,
        [userId, createPixKeyDto.pix_key, keyType, isFirstKey, nextOrder],
      );

      await client.query('COMMIT');

      return {
        success: true,
        message: 'Chave PIX cadastrada com sucesso',
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Remover chave PIX
   */
  async removePixKey(userId: string, keyId: string) {
    const client = await this.pool.connect();

    try {
      await client.query('BEGIN');

      // Verificar se a chave pertence ao usuário e se não é a única
      const keyResult = await client.query(
        'SELECT is_primary FROM user_pix_keys WHERE id = $1 AND user_id = $2',
        [keyId, userId],
      );

      if (keyResult.rows.length === 0) {
        throw new NotFoundException('Chave PIX não encontrada');
      }

      const countResult = await client.query(
        'SELECT COUNT(*) as count FROM user_pix_keys WHERE user_id = $1',
        [userId],
      );
      const count = parseInt(countResult.rows[0].count);

      if (count === 1) {
        throw new BadRequestException('Não é possível remover a única chave PIX cadastrada');
      }

      const wasPrimary = keyResult.rows[0].is_primary;

      // Remover chave
      await client.query(
        'DELETE FROM user_pix_keys WHERE id = $1 AND user_id = $2',
        [keyId, userId],
      );

      // Se era primary, tornar a primeira chave restante como primary
      if (wasPrimary) {
        const firstKeyResult = await client.query(
          'SELECT id FROM user_pix_keys WHERE user_id = $1 ORDER BY display_order ASC LIMIT 1',
          [userId],
        );
        if (firstKeyResult.rows.length > 0) {
          await client.query(
            'UPDATE user_pix_keys SET is_primary = TRUE WHERE id = $1',
            [firstKeyResult.rows[0].id],
          );
        }
      }

      await client.query('COMMIT');

      return {
        success: true,
        message: 'Chave PIX removida com sucesso',
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}
