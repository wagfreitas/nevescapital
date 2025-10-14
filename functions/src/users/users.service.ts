import { Injectable, Inject, ConflictException, NotFoundException } from '@nestjs/common';
import { Pool } from 'pg';
import { EncryptionService } from '../common/services/encryption.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { VerifyPasswordDto } from './dto/verify-password.dto';
import * as crypto from 'crypto';

@Injectable()
export class UsersService {
  constructor(
    @Inject('DATABASE_POOL') private readonly pool: Pool,
    private readonly encryptionService: EncryptionService,
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
    // Buffer vem do PostgreSQL como bytea, converter para string
    const encrypted = buffer.toString('utf8');
    const decrypted = this.encryptionService.decrypt(encrypted);
    if (!decrypted) {
      throw new Error('Falha na descriptografia');
    }
    return decrypted;
  }

  async create(createUserDto: CreateUserDto) {
    const client = await this.pool.connect();

    try {
      await client.query('BEGIN');

      // Verificar se CPF já existe
      const cpfEncrypted = this.encryptToBytea(createUserDto.cpf);
      const existingCpf = await client.query(
        'SELECT id FROM users WHERE cpf_encrypted = $1',
        [cpfEncrypted],
      );

      if (existingCpf.rows.length > 0) {
        throw new ConflictException('CPF já cadastrado');
      }

      // Verificar se email já existe
      const emailEncrypted = this.encryptToBytea(createUserDto.email);
      const existingEmail = await client.query(
        'SELECT id FROM users WHERE email_encrypted = $1',
        [emailEncrypted],
      );

      if (existingEmail.rows.length > 0) {
        throw new ConflictException('Email já cadastrado');
      }

      // Criptografar nome completo
      const fullNameEncrypted = this.encryptToBytea(createUserDto.fullName);

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
      const cpfEncrypted = this.encryptToBytea(cpf);

      const result = await this.pool.query(
        `SELECT 
          u.id,
          u.full_name,
          u.cpf_encrypted,
          u.email_encrypted,
          u.kyc_status,
          u.created_at
        FROM users u
        WHERE u.cpf_encrypted = $1 AND u.deleted_at IS NULL`,
        [cpfEncrypted],
      );

      if (result.rows.length === 0) {
        throw new NotFoundException('Usuário não encontrado');
      }

      const user = result.rows[0];

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

      return {
        id: user.id,
        email: this.decryptFromBytea(user.email_encrypted),
        full_name: this.decryptFromBytea(user.full_name),
        cpf: this.decryptFromBytea(user.cpf_encrypted),
        phone: phoneResult.rows[0] ? this.decryptFromBytea(phoneResult.rows[0].phone_encrypted) : null,
        address: addressResult.rows[0] ? {
          street: this.decryptFromBytea(addressResult.rows[0].street_encrypted),
          number: addressResult.rows[0].number_encrypted ? this.decryptFromBytea(addressResult.rows[0].number_encrypted) : null,
          complement: addressResult.rows[0].complement_encrypted ? this.decryptFromBytea(addressResult.rows[0].complement_encrypted) : null,
          neighborhood: addressResult.rows[0].neighborhood_encrypted ? this.decryptFromBytea(addressResult.rows[0].neighborhood_encrypted) : null,
          city: this.decryptFromBytea(addressResult.rows[0].city_encrypted),
          state: this.decryptFromBytea(addressResult.rows[0].state_encrypted),
          cep: addressResult.rows[0].cep,
        } : null,
        kyc_status: user.kyc_status,
        created_at: user.created_at,
        mode: 'POSTGRESQL',
      };
    } catch (error) {
      console.error('Erro ao buscar usuário:', error);
      throw error;
    }
  }

  async verifyPassword(verifyPasswordDto: VerifyPasswordDto) {
    // NOTA: A tabela users não tem campo password_hash
    // Precisamos adicionar esse campo ou usar Firebase apenas para autenticação
    throw new NotFoundException('Verificação de senha não implementada. Use Firebase Authentication.');
  }

  async update(id: string, updateUserDto: UpdateUserDto) {
    const client = await this.pool.connect();

    try {
      await client.query('BEGIN');

      // Atualizar nome se fornecido
      if (updateUserDto.fullName) {
        const fullNameEncrypted = this.encryptToBytea(updateUserDto.fullName);
        await client.query(
          'UPDATE users SET full_name = $1, updated_at = NOW() WHERE id = $2',
          [fullNameEncrypted, id],
        );
      }

      // Atualizar telefone se fornecido
      if (updateUserDto.phone) {
        const phoneEncrypted = this.encryptToBytea(updateUserDto.phone);
        
        // Verificar se já existe telefone
        const existingPhone = await client.query(
          'SELECT id FROM user_phones WHERE user_id = $1 AND is_primary = true',
          [id],
        );

        if (existingPhone.rows.length > 0) {
          // Atualizar
          await client.query(
            'UPDATE user_phones SET phone_encrypted = $1, updated_at = NOW() WHERE user_id = $2 AND is_primary = true',
            [phoneEncrypted, id],
          );
        } else {
          // Inserir
          await client.query(
            'INSERT INTO user_phones (user_id, phone_encrypted, is_primary) VALUES ($1, $2, true)',
            [id, phoneEncrypted],
          );
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
}
