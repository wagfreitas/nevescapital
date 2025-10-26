/******/ (() => { // webpackBootstrap
/******/ 	"use strict";
/******/ 	var __webpack_modules__ = ([
/* 0 */,
/* 1 */
/***/ ((module) => {

module.exports = require("@nestjs/core");

/***/ }),
/* 2 */
/***/ ((module) => {

module.exports = require("@nestjs/common");

/***/ }),
/* 3 */
/***/ ((module) => {

module.exports = require("@nestjs/swagger");

/***/ }),
/* 4 */
/***/ ((module) => {

module.exports = require("helmet");

/***/ }),
/* 5 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.AppModule = void 0;
const common_1 = __webpack_require__(2);
const config_1 = __webpack_require__(6);
const throttler_1 = __webpack_require__(7);
const users_module_1 = __webpack_require__(8);
const auth_module_1 = __webpack_require__(22);
const database_module_1 = __webpack_require__(23);
const health_controller_1 = __webpack_require__(24);
const migration_controller_1 = __webpack_require__(25);
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({
                isGlobal: true,
                envFilePath: '.env',
            }),
            throttler_1.ThrottlerModule.forRoot([{
                    ttl: 60000,
                    limit: 100,
                }]),
            database_module_1.DatabaseModule,
            users_module_1.UsersModule,
            auth_module_1.AuthModule,
        ],
        controllers: [health_controller_1.HealthController, migration_controller_1.MigrationController],
    })
], AppModule);


/***/ }),
/* 6 */
/***/ ((module) => {

module.exports = require("@nestjs/config");

/***/ }),
/* 7 */
/***/ ((module) => {

module.exports = require("@nestjs/throttler");

/***/ }),
/* 8 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.UsersModule = void 0;
const common_1 = __webpack_require__(2);
const users_service_1 = __webpack_require__(9);
const users_controller_1 = __webpack_require__(14);
const user_transaction_service_1 = __webpack_require__(20);
const user_transaction_controller_1 = __webpack_require__(21);
const encryption_service_1 = __webpack_require__(11);
let UsersModule = class UsersModule {
};
exports.UsersModule = UsersModule;
exports.UsersModule = UsersModule = __decorate([
    (0, common_1.Module)({
        controllers: [users_controller_1.UsersController, user_transaction_controller_1.UserTransactionController],
        providers: [users_service_1.UsersService, user_transaction_service_1.UserTransactionService, encryption_service_1.EncryptionService],
        exports: [users_service_1.UsersService, user_transaction_service_1.UserTransactionService],
    })
], UsersModule);


/***/ }),
/* 9 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var _a, _b;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.UsersService = void 0;
const common_1 = __webpack_require__(2);
const pg_1 = __webpack_require__(10);
const encryption_service_1 = __webpack_require__(11);
let UsersService = class UsersService {
    constructor(pool, encryptionService) {
        this.pool = pool;
        this.encryptionService = encryptionService;
    }
    encryptToBytea(text) {
        const encrypted = this.encryptionService.encrypt(text);
        if (!encrypted) {
            throw new Error('Falha na criptografia');
        }
        return encrypted;
    }
    decryptFromBytea(buffer) {
        try {
            let encrypted;
            if (Buffer.isBuffer(buffer)) {
                encrypted = buffer.toString('utf8');
            }
            else if (typeof buffer === 'string') {
                encrypted = buffer;
            }
            else {
                throw new Error('Formato de buffer inválido');
            }
            console.log(`🔐 Tentando descriptografar: ${encrypted.substring(0, 50)}...`);
            const decrypted = this.encryptionService.decrypt(encrypted);
            if (!decrypted) {
                throw new Error('Falha na descriptografia - resultado vazio');
            }
            console.log(`✅ Descriptografado com sucesso: ${decrypted}`);
            return decrypted;
        }
        catch (error) {
            console.error('❌ Erro na descriptografia:', error);
            throw new Error(`Falha na descriptografia: ${error.message}`);
        }
    }
    async create(createUserDto) {
        const client = await this.pool.connect();
        try {
            await client.query('BEGIN');
            console.log(`🔍 Criando usuário: ${createUserDto.fullName}...`);
            const fullNameEncrypted = this.encryptToBytea(createUserDto.fullName);
            const cpfEncrypted = this.encryptToBytea(createUserDto.cpf);
            const emailEncrypted = this.encryptToBytea(createUserDto.email);
            const userResult = await client.query(`INSERT INTO users (
          full_name,
          cpf_encrypted,
          email_encrypted,
          kyc_status
        ) VALUES ($1, $2, $3, $4)
        RETURNING id, created_at`, [fullNameEncrypted, cpfEncrypted, emailEncrypted, 'pending']);
            const userId = userResult.rows[0].id;
            if (createUserDto.phone) {
                const phoneEncrypted = this.encryptToBytea(createUserDto.phone);
                await client.query(`INSERT INTO user_phones (user_id, phone_encrypted, is_primary, phone_type)
           VALUES ($1, $2, true, 'mobile')`, [userId, phoneEncrypted]);
            }
            if (createUserDto.cep && createUserDto.address) {
                const streetEncrypted = this.encryptToBytea(createUserDto.address);
                const numberEncrypted = createUserDto.number ? this.encryptToBytea(createUserDto.number) : null;
                const complementEncrypted = createUserDto.complement ? this.encryptToBytea(createUserDto.complement) : null;
                const neighborhoodEncrypted = createUserDto.neighborhood ? this.encryptToBytea(createUserDto.neighborhood) : null;
                const cityEncrypted = createUserDto.city ? this.encryptToBytea(createUserDto.city) : this.encryptToBytea('');
                const stateEncrypted = createUserDto.state ? this.encryptToBytea(createUserDto.state) : this.encryptToBytea('');
                await client.query(`INSERT INTO user_addresses (
            user_id, 
            street_encrypted, 
            number_encrypted, 
            complement_encrypted, 
            neighborhood_encrypted,
            city_encrypted,
            state_encrypted,
            cep, 
            is_primary
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true)`, [
                    userId,
                    streetEncrypted,
                    numberEncrypted,
                    complementEncrypted,
                    neighborhoodEncrypted,
                    cityEncrypted,
                    stateEncrypted,
                    createUserDto.cep,
                ]);
            }
            await client.query('COMMIT');
            console.log(`✅ Usuário criado no PostgreSQL: ID ${userId}`);
            return {
                success: true,
                user_id: userId,
                created_at: userResult.rows[0].created_at,
                mode: 'POSTGRESQL',
            };
        }
        catch (error) {
            await client.query('ROLLBACK');
            console.error('Erro ao criar usuário:', error);
            throw error;
        }
        finally {
            client.release();
        }
    }
    async findByCpf(cpf) {
        try {
            console.log(`🔍 Buscando usuário por CPF: ${cpf}`);
            const result = await this.pool.query(`SELECT 
          u.id,
          u.full_name,
          u.cpf_encrypted,
          u.email_encrypted,
          u.kyc_status,
          u.created_at
        FROM users u
        WHERE u.deleted_at IS NULL`);
            console.log(`📊 Encontrados ${result.rows.length} usuários ativos`);
            let foundUser = null;
            for (const user of result.rows) {
                try {
                    const decryptedCpf = this.decryptFromBytea(user.cpf_encrypted);
                    console.log(`🔐 CPF descriptografado: ${decryptedCpf}`);
                    if (decryptedCpf === cpf) {
                        console.log(`✅ Usuário encontrado! ID: ${user.id}`);
                        foundUser = user;
                        break;
                    }
                }
                catch (error) {
                    console.error(`❌ Erro ao descriptografar CPF do usuário ${user.id}:`, error);
                    continue;
                }
            }
            if (!foundUser) {
                console.log(`⚠️  Nenhum usuário encontrado com CPF: ${cpf}`);
                throw new common_1.NotFoundException('Usuário não encontrado');
            }
            const user = foundUser;
            const phoneResult = await this.pool.query('SELECT phone_encrypted FROM user_phones WHERE user_id = $1 AND is_primary = true', [user.id]);
            const addressResult = await this.pool.query(`SELECT 
          street_encrypted,
          number_encrypted,
          complement_encrypted,
          neighborhood_encrypted,
          city_encrypted,
          state_encrypted,
          cep
        FROM user_addresses 
        WHERE user_id = $1 AND is_primary = true`, [user.id]);
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
        }
        catch (error) {
            console.error('Erro ao buscar usuário:', error);
            throw error;
        }
    }
    async verifyPassword(verifyPasswordDto) {
        throw new common_1.NotFoundException('Verificação de senha não implementada. Use Firebase Authentication.');
    }
    async update(id, updateUserDto) {
        const client = await this.pool.connect();
        try {
            await client.query('BEGIN');
            if (updateUserDto.fullName) {
                const fullNameEncrypted = this.encryptToBytea(updateUserDto.fullName);
                await client.query('UPDATE users SET full_name = $1, updated_at = NOW() WHERE id = $2', [fullNameEncrypted, id]);
            }
            if (updateUserDto.phone) {
                const phoneEncrypted = this.encryptToBytea(updateUserDto.phone);
                const existingPhone = await client.query('SELECT id FROM user_phones WHERE user_id = $1 AND is_primary = true', [id]);
                if (existingPhone.rows.length > 0) {
                    await client.query('UPDATE user_phones SET phone_encrypted = $1, updated_at = NOW() WHERE user_id = $2 AND is_primary = true', [phoneEncrypted, id]);
                }
                else {
                    await client.query('INSERT INTO user_phones (user_id, phone_encrypted, is_primary) VALUES ($1, $2, true)', [id, phoneEncrypted]);
                }
            }
            if (updateUserDto.cep || updateUserDto.address) {
                const updateFields = [];
                const values = [id];
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
                    const existingAddress = await client.query('SELECT id FROM user_addresses WHERE user_id = $1 AND is_primary = true', [id]);
                    if (existingAddress.rows.length > 0) {
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
        }
        catch (error) {
            await client.query('ROLLBACK');
            console.error('Erro ao atualizar usuário:', error);
            throw error;
        }
        finally {
            client.release();
        }
    }
    async remove(id) {
        const result = await this.pool.query('UPDATE users SET deleted_at = NOW() WHERE id = $1 RETURNING id', [id]);
        if (result.rows.length === 0) {
            throw new common_1.NotFoundException('Usuário não encontrado');
        }
        return {
            success: true,
            user_id: result.rows[0].id,
            mode: 'POSTGRESQL',
        };
    }
};
exports.UsersService = UsersService;
exports.UsersService = UsersService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, common_1.Inject)('DATABASE_POOL')),
    __metadata("design:paramtypes", [typeof (_a = typeof pg_1.Pool !== "undefined" && pg_1.Pool) === "function" ? _a : Object, typeof (_b = typeof encryption_service_1.EncryptionService !== "undefined" && encryption_service_1.EncryptionService) === "function" ? _b : Object])
], UsersService);


/***/ }),
/* 10 */
/***/ ((module) => {

module.exports = require("pg");

/***/ }),
/* 11 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.EncryptionService = void 0;
const common_1 = __webpack_require__(2);
const CryptoJS = __webpack_require__(12);
const bcrypt = __webpack_require__(13);
let EncryptionService = class EncryptionService {
    constructor() {
        this.encryptionKey = process.env.ENCRYPTION_KEY || 'your-32-character-secret-key!';
        this.saltRounds = 10;
    }
    encrypt(text) {
        if (!text)
            return null;
        try {
            const encrypted = CryptoJS.AES.encrypt(text, this.encryptionKey);
            return encrypted.toString();
        }
        catch (error) {
            console.error('Erro ao criptografar:', error);
            throw new Error('Falha na criptografia');
        }
    }
    decrypt(encryptedText) {
        if (!encryptedText)
            return null;
        try {
            const decrypted = CryptoJS.AES.decrypt(encryptedText, this.encryptionKey);
            return decrypted.toString(CryptoJS.enc.Utf8);
        }
        catch (error) {
            console.error('Erro ao descriptografar:', error);
            throw new Error('Falha na descriptografia');
        }
    }
    async hashPassword(password) {
        try {
            return await bcrypt.hash(password, this.saltRounds);
        }
        catch (error) {
            console.error('Erro ao gerar hash:', error);
            throw new Error('Falha ao processar senha');
        }
    }
    async verifyPassword(password, hash) {
        try {
            return await bcrypt.compare(password, hash);
        }
        catch (error) {
            console.error('Erro ao verificar senha:', error);
            return false;
        }
    }
};
exports.EncryptionService = EncryptionService;
exports.EncryptionService = EncryptionService = __decorate([
    (0, common_1.Injectable)()
], EncryptionService);


/***/ }),
/* 12 */
/***/ ((module) => {

module.exports = require("crypto-js");

/***/ }),
/* 13 */
/***/ ((module) => {

module.exports = require("bcrypt");

/***/ }),
/* 14 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var _a, _b, _c, _d;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.UsersController = void 0;
const common_1 = __webpack_require__(2);
const swagger_1 = __webpack_require__(3);
const throttler_1 = __webpack_require__(7);
const users_service_1 = __webpack_require__(9);
const create_user_dto_1 = __webpack_require__(15);
const update_user_dto_1 = __webpack_require__(17);
const verify_password_dto_1 = __webpack_require__(18);
const api_key_guard_1 = __webpack_require__(19);
let UsersController = class UsersController {
    constructor(usersService) {
        this.usersService = usersService;
    }
    create(createUserDto) {
        return this.usersService.create(createUserDto);
    }
    findByCpf(cpf) {
        return this.usersService.findByCpf(cpf);
    }
    verifyPassword(verifyPasswordDto) {
        return this.usersService.verifyPassword(verifyPasswordDto);
    }
    update(id, updateUserDto) {
        return this.usersService.update(id, updateUserDto);
    }
    remove(id) {
        return this.usersService.remove(id);
    }
};
exports.UsersController = UsersController;
__decorate([
    (0, common_1.Post)('register'),
    (0, throttler_1.Throttle)({ default: { limit: 10, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({ summary: 'Registrar novo usuário' }),
    (0, swagger_1.ApiResponse)({ status: 201, description: 'Usuário criado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 409, description: 'CPF ou email já cadastrado' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Dados inválidos' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_b = typeof create_user_dto_1.CreateUserDto !== "undefined" && create_user_dto_1.CreateUserDto) === "function" ? _b : Object]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "create", null);
__decorate([
    (0, common_1.Get)('cpf/:cpf'),
    (0, swagger_1.ApiOperation)({ summary: 'Buscar usuário por CPF' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Usuário encontrado' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Usuário não encontrado' }),
    __param(0, (0, common_1.Param)('cpf')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "findByCpf", null);
__decorate([
    (0, common_1.Post)('verify-password'),
    (0, swagger_1.ApiOperation)({ summary: 'Verificar senha do usuário' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Senha verificada' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Usuário não encontrado' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_c = typeof verify_password_dto_1.VerifyPasswordDto !== "undefined" && verify_password_dto_1.VerifyPasswordDto) === "function" ? _c : Object]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "verifyPassword", null);
__decorate([
    (0, common_1.Put)(':id'),
    (0, swagger_1.ApiOperation)({ summary: 'Atualizar dados do usuário' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Usuário atualizado' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Usuário não encontrado' }),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, typeof (_d = typeof update_user_dto_1.UpdateUserDto !== "undefined" && update_user_dto_1.UpdateUserDto) === "function" ? _d : Object]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "update", null);
__decorate([
    (0, common_1.Delete)(':id'),
    (0, swagger_1.ApiOperation)({ summary: 'Deletar usuário (soft delete)' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Usuário deletado' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Usuário não encontrado' }),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "remove", null);
exports.UsersController = UsersController = __decorate([
    (0, swagger_1.ApiTags)('Users'),
    (0, common_1.Controller)('api/users'),
    (0, common_1.UseGuards)(api_key_guard_1.ApiKeyGuard),
    (0, swagger_1.ApiSecurity)('api-key'),
    __metadata("design:paramtypes", [typeof (_a = typeof users_service_1.UsersService !== "undefined" && users_service_1.UsersService) === "function" ? _a : Object])
], UsersController);


/***/ }),
/* 15 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.CreateUserDto = void 0;
const class_validator_1 = __webpack_require__(16);
const swagger_1 = __webpack_require__(3);
class CreateUserDto {
}
exports.CreateUserDto = CreateUserDto;
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'user@example.com' }),
    (0, class_validator_1.IsEmail)({}, { message: 'Email inválido' }),
    __metadata("design:type", String)
], CreateUserDto.prototype, "email", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'SecurePass123!', minLength: 6 }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(6, { message: 'Senha deve ter pelo menos 6 caracteres' }),
    __metadata("design:type", String)
], CreateUserDto.prototype, "password", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'João Silva Santos' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(3, { message: 'Nome completo deve ter pelo menos 3 caracteres' }),
    __metadata("design:type", String)
], CreateUserDto.prototype, "fullName", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: '12345678901' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.Matches)(/^\d{11}$/, { message: 'CPF deve ter 11 dígitos' }),
    __metadata("design:type", String)
], CreateUserDto.prototype, "cpf", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: '11999999999' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.Matches)(/^\d{10,11}$/, { message: 'Telefone deve ter 10 ou 11 dígitos' }),
    __metadata("design:type", String)
], CreateUserDto.prototype, "phone", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: '01310100' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.Matches)(/^\d{8}$/, { message: 'CEP deve ter 8 dígitos' }),
    __metadata("design:type", String)
], CreateUserDto.prototype, "cep", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'Avenida Paulista' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateUserDto.prototype, "address", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'Bela Vista' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateUserDto.prototype, "neighborhood", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'São Paulo' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateUserDto.prototype, "city", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'SP' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.Matches)(/^[A-Z]{2}$/, { message: 'Estado deve ter 2 letras maiúsculas' }),
    __metadata("design:type", String)
], CreateUserDto.prototype, "state", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: '100' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateUserDto.prototype, "number", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'Apto 10' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreateUserDto.prototype, "complement", void 0);


/***/ }),
/* 16 */
/***/ ((module) => {

module.exports = require("class-validator");

/***/ }),
/* 17 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.UpdateUserDto = void 0;
const class_validator_1 = __webpack_require__(16);
const swagger_1 = __webpack_require__(3);
class UpdateUserDto {
}
exports.UpdateUserDto = UpdateUserDto;
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'João Silva Santos' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateUserDto.prototype, "fullName", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: '11999999999' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateUserDto.prototype, "phone", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: '01310100' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateUserDto.prototype, "cep", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'Avenida Paulista' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateUserDto.prototype, "address", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'Bela Vista' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateUserDto.prototype, "neighborhood", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'São Paulo' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateUserDto.prototype, "city", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'SP' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateUserDto.prototype, "state", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: '100' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateUserDto.prototype, "number", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'Apto 10' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], UpdateUserDto.prototype, "complement", void 0);


/***/ }),
/* 18 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.VerifyPasswordDto = void 0;
const class_validator_1 = __webpack_require__(16);
const swagger_1 = __webpack_require__(3);
class VerifyPasswordDto {
}
exports.VerifyPasswordDto = VerifyPasswordDto;
__decorate([
    (0, swagger_1.ApiProperty)({ example: '12345678901' }),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], VerifyPasswordDto.prototype, "cpf", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'SecurePass123!' }),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], VerifyPasswordDto.prototype, "password", void 0);


/***/ }),
/* 19 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.ApiKeyGuard = void 0;
const common_1 = __webpack_require__(2);
let ApiKeyGuard = class ApiKeyGuard {
    canActivate(context) {
        const request = context.switchToHttp().getRequest();
        const apiKey = request.headers['x-api-key'];
        if (!apiKey) {
            throw new common_1.UnauthorizedException('API Key não fornecida');
        }
        if (apiKey !== process.env.API_KEY) {
            throw new common_1.UnauthorizedException('API Key inválida');
        }
        return true;
    }
};
exports.ApiKeyGuard = ApiKeyGuard;
exports.ApiKeyGuard = ApiKeyGuard = __decorate([
    (0, common_1.Injectable)()
], ApiKeyGuard);


/***/ }),
/* 20 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var _a;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.UserTransactionService = void 0;
const common_1 = __webpack_require__(2);
const pg_1 = __webpack_require__(10);
let UserTransactionService = class UserTransactionService {
    constructor(pool) {
        this.pool = pool;
    }
    async saveTransaction(transaction) {
        const client = await this.pool.connect();
        try {
            await client.query('BEGIN');
            const transactionQuery = `
        INSERT INTO user_transactions (
          user_id, pagarme_order_id, pagarme_charge_id, amount, 
          status, establishment_name, customer_name, payment_method
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *
      `;
            const transactionResult = await client.query(transactionQuery, [
                transaction.user_id,
                transaction.pagarme_order_id,
                transaction.pagarme_charge_id,
                transaction.amount,
                transaction.status,
                transaction.establishment_name,
                transaction.customer_name,
                transaction.payment_method,
            ]);
            const savedTransaction = transactionResult.rows[0];
            await this.updateUserBalance(client, transaction.user_id);
            await this.logSync(client, {
                order_id: transaction.pagarme_order_id,
                charge_id: transaction.pagarme_charge_id,
                sync_status: 'synced',
                sync_attempts: 1,
            });
            await client.query('COMMIT');
            return savedTransaction;
        }
        catch (error) {
            await client.query('ROLLBACK');
            throw error;
        }
        finally {
            client.release();
        }
    }
    async updateUserBalance(client, userId) {
        const balanceQuery = `
      INSERT INTO user_balances (user_id, available_amount, waiting_funds, total_transactions, last_transaction_at)
      SELECT 
        $1,
        COALESCE(SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END), 0),
        COALESCE(SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END), 0),
        COUNT(*),
        MAX(created_at)
      FROM user_transactions 
      WHERE user_id = $1
      ON CONFLICT (user_id) 
      DO UPDATE SET
        available_amount = EXCLUDED.available_amount,
        waiting_funds = EXCLUDED.waiting_funds,
        total_transactions = EXCLUDED.total_transactions,
        last_transaction_at = EXCLUDED.last_transaction_at,
        last_updated = NOW()
    `;
        await client.query(balanceQuery, [userId]);
    }
    async logSync(client, syncLog) {
        const syncQuery = `
      INSERT INTO pagarme_sync_log (order_id, charge_id, sync_status, sync_attempts, last_sync_attempt)
      VALUES ($1, $2, $3, $4, NOW())
      ON CONFLICT (order_id) 
      DO UPDATE SET
        sync_status = EXCLUDED.sync_status,
        sync_attempts = EXCLUDED.sync_attempts,
        last_sync_attempt = EXCLUDED.last_sync_attempt,
        updated_at = NOW()
    `;
        await client.query(syncQuery, [
            syncLog.order_id,
            syncLog.charge_id,
            syncLog.sync_status,
            syncLog.sync_attempts,
        ]);
    }
    async getUserBalance(userId) {
        const query = `
      SELECT * FROM user_balances WHERE user_id = $1
    `;
        const result = await this.pool.query(query, [userId]);
        return result.rows[0] || null;
    }
    async getUserTransactions(userId, limit = 50, offset = 0) {
        const query = `
      SELECT * FROM user_transactions 
      WHERE user_id = $1 
      ORDER BY created_at DESC 
      LIMIT $2 OFFSET $3
    `;
        const result = await this.pool.query(query, [userId, limit, offset]);
        return result.rows;
    }
    async getUserStats(userId) {
        const query = `
      SELECT 
        COUNT(*) as total_transactions,
        SUM(amount) as total_amount,
        COUNT(CASE WHEN status = 'paid' THEN 1 END) as paid_transactions,
        SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) as paid_amount,
        COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_transactions,
        SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END) as pending_amount,
        COUNT(CASE WHEN status = 'failed' THEN 1 END) as failed_transactions
      FROM user_transactions 
      WHERE user_id = $1
    `;
        const result = await this.pool.query(query, [userId]);
        const stats = result.rows[0];
        return {
            totalTransactions: parseInt(stats.total_transactions) || 0,
            totalAmount: parseInt(stats.total_amount) || 0,
            paidTransactions: parseInt(stats.paid_transactions) || 0,
            paidAmount: parseInt(stats.paid_amount) || 0,
            pendingTransactions: parseInt(stats.pending_transactions) || 0,
            pendingAmount: parseInt(stats.pending_amount) || 0,
            failedTransactions: parseInt(stats.failed_transactions) || 0,
        };
    }
    async isTransactionSynced(orderId) {
        const query = `
      SELECT COUNT(*) FROM pagarme_sync_log 
      WHERE order_id = $1 AND sync_status = 'synced'
    `;
        const result = await this.pool.query(query, [orderId]);
        return parseInt(result.rows[0].count) > 0;
    }
    async markSyncFailed(orderId, errorMessage) {
        const query = `
      INSERT INTO pagarme_sync_log (order_id, sync_status, sync_attempts, error_message, last_sync_attempt)
      VALUES ($1, 'failed', 1, $2, NOW())
      ON CONFLICT (order_id) 
      DO UPDATE SET
        sync_status = 'failed',
        sync_attempts = pagarme_sync_log.sync_attempts + 1,
        error_message = EXCLUDED.error_message,
        last_sync_attempt = EXCLUDED.last_sync_attempt,
        updated_at = NOW()
    `;
        await this.pool.query(query, [orderId, errorMessage]);
    }
};
exports.UserTransactionService = UserTransactionService;
exports.UserTransactionService = UserTransactionService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof pg_1.Pool !== "undefined" && pg_1.Pool) === "function" ? _a : Object])
], UserTransactionService);


/***/ }),
/* 21 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
var _a, _b;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.UserTransactionController = void 0;
const common_1 = __webpack_require__(2);
const user_transaction_service_1 = __webpack_require__(20);
let UserTransactionController = class UserTransactionController {
    constructor(transactionService) {
        this.transactionService = transactionService;
    }
    async saveTransaction(transaction) {
        try {
            const isSynced = await this.transactionService.isTransactionSynced(transaction.pagarme_order_id);
            if (isSynced) {
                return {
                    success: false,
                    message: 'Transação já foi sincronizada',
                };
            }
            const savedTransaction = await this.transactionService.saveTransaction(transaction);
            return {
                success: true,
                data: savedTransaction,
                message: 'Transação salva com sucesso',
            };
        }
        catch (error) {
            return {
                success: false,
                message: 'Erro ao salvar transação',
                error: error.message,
            };
        }
    }
    async getUserBalance(userId) {
        try {
            const balance = await this.transactionService.getUserBalance(userId);
            if (!balance) {
                return {
                    success: true,
                    data: {
                        available_amount: 0,
                        waiting_funds: 0,
                        total_transactions: 0,
                    },
                };
            }
            return {
                success: true,
                data: balance,
            };
        }
        catch (error) {
            return {
                success: false,
                message: 'Erro ao buscar saldo',
                error: error.message,
            };
        }
    }
    async getUserTransactions(userId, limit = '50', offset = '0') {
        try {
            const transactions = await this.transactionService.getUserTransactions(userId, parseInt(limit), parseInt(offset));
            return {
                success: true,
                data: transactions,
                pagination: {
                    limit: parseInt(limit),
                    offset: parseInt(offset),
                    total: transactions.length,
                },
            };
        }
        catch (error) {
            return {
                success: false,
                message: 'Erro ao buscar histórico',
                error: error.message,
            };
        }
    }
    async getUserStats(userId) {
        try {
            const stats = await this.transactionService.getUserStats(userId);
            return {
                success: true,
                data: stats,
            };
        }
        catch (error) {
            return {
                success: false,
                message: 'Erro ao buscar estatísticas',
                error: error.message,
            };
        }
    }
    async getSyncStatus(orderId) {
        try {
            const isSynced = await this.transactionService.isTransactionSynced(orderId);
            return {
                success: true,
                data: {
                    order_id: orderId,
                    synced: isSynced,
                },
            };
        }
        catch (error) {
            return {
                success: false,
                message: 'Erro ao verificar status de sincronização',
                error: error.message,
            };
        }
    }
};
exports.UserTransactionController = UserTransactionController;
__decorate([
    (0, common_1.Post)(),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_b = typeof user_transaction_service_1.UserTransaction !== "undefined" && user_transaction_service_1.UserTransaction) === "function" ? _b : Object]),
    __metadata("design:returntype", Promise)
], UserTransactionController.prototype, "saveTransaction", null);
__decorate([
    (0, common_1.Get)('balance/:userId'),
    __param(0, (0, common_1.Param)('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], UserTransactionController.prototype, "getUserBalance", null);
__decorate([
    (0, common_1.Get)('history/:userId'),
    __param(0, (0, common_1.Param)('userId')),
    __param(1, (0, common_1.Query)('limit')),
    __param(2, (0, common_1.Query)('offset')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], UserTransactionController.prototype, "getUserTransactions", null);
__decorate([
    (0, common_1.Get)('stats/:userId'),
    __param(0, (0, common_1.Param)('userId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], UserTransactionController.prototype, "getUserStats", null);
__decorate([
    (0, common_1.Get)('sync-status/:orderId'),
    __param(0, (0, common_1.Param)('orderId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], UserTransactionController.prototype, "getSyncStatus", null);
exports.UserTransactionController = UserTransactionController = __decorate([
    (0, common_1.Controller)('transactions'),
    __metadata("design:paramtypes", [typeof (_a = typeof user_transaction_service_1.UserTransactionService !== "undefined" && user_transaction_service_1.UserTransactionService) === "function" ? _a : Object])
], UserTransactionController);


/***/ }),
/* 22 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.AuthModule = void 0;
const common_1 = __webpack_require__(2);
let AuthModule = class AuthModule {
};
exports.AuthModule = AuthModule;
exports.AuthModule = AuthModule = __decorate([
    (0, common_1.Module)({})
], AuthModule);


/***/ }),
/* 23 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.DatabaseModule = void 0;
const common_1 = __webpack_require__(2);
const pg_1 = __webpack_require__(10);
let DatabaseModule = class DatabaseModule {
};
exports.DatabaseModule = DatabaseModule;
exports.DatabaseModule = DatabaseModule = __decorate([
    (0, common_1.Global)(),
    (0, common_1.Module)({
        providers: [
            {
                provide: 'DATABASE_POOL',
                useFactory: () => {
                    const isCloudRun = !!process.env.INSTANCE_UNIX_SOCKET;
                    const config = {
                        database: process.env.DB_NAME,
                        user: process.env.DB_USER,
                        password: process.env.DB_PASSWORD,
                        max: 10,
                        idleTimeoutMillis: 30000,
                        connectionTimeoutMillis: 10000,
                    };
                    if (isCloudRun) {
                        config.host = process.env.INSTANCE_UNIX_SOCKET;
                        console.log(`🔌 Conectando via Unix socket: ${config.host}`);
                    }
                    else {
                        config.host = process.env.DB_HOST;
                        config.port = parseInt(process.env.DB_PORT || '5432');
                        config.ssl = false;
                        console.log(`🔌 Conectando via TCP: ${config.host}:${config.port}`);
                    }
                    const pool = new pg_1.Pool(config);
                    pool.on('connect', () => {
                        console.log('✅ Conectado ao PostgreSQL Cloud SQL');
                    });
                    pool.on('error', (err) => {
                        console.error('❌ Erro no pool PostgreSQL:', err);
                    });
                    return pool;
                },
            },
        ],
        exports: ['DATABASE_POOL'],
    })
], DatabaseModule);


/***/ }),
/* 24 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.HealthController = void 0;
const common_1 = __webpack_require__(2);
const swagger_1 = __webpack_require__(3);
let HealthController = class HealthController {
    check() {
        return {
            status: 'OK',
            timestamp: new Date().toISOString(),
            service: 'Neves Capital API',
            version: '1.0.0',
        };
    }
};
exports.HealthController = HealthController;
__decorate([
    (0, common_1.Get)(),
    (0, swagger_1.ApiOperation)({ summary: 'Health check endpoint' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], HealthController.prototype, "check", null);
exports.HealthController = HealthController = __decorate([
    (0, swagger_1.ApiTags)('Health'),
    (0, common_1.Controller)('health')
], HealthController);


/***/ }),
/* 25 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var _a;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.MigrationController = void 0;
const common_1 = __webpack_require__(2);
const pg_1 = __webpack_require__(10);
let MigrationController = class MigrationController {
    constructor(pool) {
        this.pool = pool;
    }
    async setupTables() {
        const client = await this.pool.connect();
        try {
            await client.query('BEGIN');
            await client.query(`
        CREATE TABLE IF NOT EXISTS user_transactions (
          id SERIAL PRIMARY KEY,
          user_id VARCHAR(255) NOT NULL,
          pagarme_order_id VARCHAR(255) UNIQUE NOT NULL,
          pagarme_charge_id VARCHAR(255),
          amount INTEGER NOT NULL,
          status VARCHAR(50) NOT NULL,
          establishment_name VARCHAR(255),
          customer_name VARCHAR(255),
          payment_method VARCHAR(50),
          created_at TIMESTAMP DEFAULT NOW(),
          updated_at TIMESTAMP DEFAULT NOW()
        )
      `);
            await client.query(`
        CREATE TABLE IF NOT EXISTS user_balances (
          user_id VARCHAR(255) PRIMARY KEY,
          available_amount INTEGER DEFAULT 0,
          waiting_funds INTEGER DEFAULT 0,
          total_transactions INTEGER DEFAULT 0,
          last_transaction_at TIMESTAMP,
          last_updated TIMESTAMP DEFAULT NOW()
        )
      `);
            await client.query(`
        CREATE TABLE IF NOT EXISTS pagarme_sync_log (
          id SERIAL PRIMARY KEY,
          order_id VARCHAR(255) NOT NULL,
          charge_id VARCHAR(255),
          sync_status VARCHAR(50) NOT NULL,
          sync_attempts INTEGER DEFAULT 0,
          last_sync_attempt TIMESTAMP,
          error_message TEXT,
          created_at TIMESTAMP DEFAULT NOW(),
          updated_at TIMESTAMP DEFAULT NOW()
        )
      `);
            await client.query(`
        CREATE INDEX IF NOT EXISTS idx_user_transactions_user_id ON user_transactions(user_id)
      `);
            await client.query(`
        CREATE INDEX IF NOT EXISTS idx_user_transactions_status ON user_transactions(status)
      `);
            await client.query(`
        CREATE INDEX IF NOT EXISTS idx_pagarme_sync_order_id ON pagarme_sync_log(order_id)
      `);
            await client.query(`
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
        END;
        $$ language 'plpgsql'
      `);
            await client.query(`
        DROP TRIGGER IF EXISTS update_user_transactions_updated_at ON user_transactions;
        CREATE TRIGGER update_user_transactions_updated_at 
            BEFORE UPDATE ON user_transactions 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
      `);
            await client.query(`
        DROP TRIGGER IF EXISTS update_user_balances_updated_at ON user_balances;
        CREATE TRIGGER update_user_balances_updated_at 
            BEFORE UPDATE ON user_balances 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
      `);
            await client.query(`
        DROP TRIGGER IF EXISTS update_pagarme_sync_log_updated_at ON pagarme_sync_log;
        CREATE TRIGGER update_pagarme_sync_log_updated_at 
            BEFORE UPDATE ON pagarme_sync_log 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
      `);
            await client.query('COMMIT');
            return {
                success: true,
                message: 'Tabelas criadas com sucesso!',
                tables: ['user_transactions', 'user_balances', 'pagarme_sync_log'],
            };
        }
        catch (error) {
            await client.query('ROLLBACK');
            throw error;
        }
        finally {
            client.release();
        }
    }
};
exports.MigrationController = MigrationController;
__decorate([
    (0, common_1.Post)('setup-tables'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], MigrationController.prototype, "setupTables", null);
exports.MigrationController = MigrationController = __decorate([
    (0, common_1.Controller)('migration'),
    __metadata("design:paramtypes", [typeof (_a = typeof pg_1.Pool !== "undefined" && pg_1.Pool) === "function" ? _a : Object])
], MigrationController);


/***/ })
/******/ 	]);
/************************************************************************/
/******/ 	// The module cache
/******/ 	var __webpack_module_cache__ = {};
/******/ 	
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/ 		// Check if module is in cache
/******/ 		var cachedModule = __webpack_module_cache__[moduleId];
/******/ 		if (cachedModule !== undefined) {
/******/ 			return cachedModule.exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = __webpack_module_cache__[moduleId] = {
/******/ 			// no module.id needed
/******/ 			// no module.loaded needed
/******/ 			exports: {}
/******/ 		};
/******/ 	
/******/ 		// Execute the module function
/******/ 		__webpack_modules__[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/ 	
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/ 	
/************************************************************************/
var __webpack_exports__ = {};
// This entry needs to be wrapped in an IIFE because it needs to be isolated against other modules in the chunk.
(() => {
var exports = __webpack_exports__;

Object.defineProperty(exports, "__esModule", ({ value: true }));
const core_1 = __webpack_require__(1);
const common_1 = __webpack_require__(2);
const swagger_1 = __webpack_require__(3);
const helmet_1 = __webpack_require__(4);
const app_module_1 = __webpack_require__(5);
async function bootstrap() {
    const app = await core_1.NestFactory.create(app_module_1.AppModule);
    app.use((0, helmet_1.default)());
    app.enableCors({
        origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
        credentials: true,
    });
    app.useGlobalPipes(new common_1.ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
    }));
    const config = new swagger_1.DocumentBuilder()
        .setTitle('Neves Capital API')
        .setDescription('API Backend for Neves Capital - PostgreSQL + Firebase')
        .setVersion('1.0')
        .addApiKey({ type: 'apiKey', name: 'x-api-key', in: 'header' }, 'api-key')
        .build();
    const document = swagger_1.SwaggerModule.createDocument(app, config);
    swagger_1.SwaggerModule.setup('api/docs', app, document);
    const port = process.env.PORT || 8080;
    await app.listen(port);
    console.log(`🚀 API rodando na porta ${port}`);
    console.log(`📚 Documentação: http://localhost:${port}/api/docs`);
    console.log(`💚 Health check: http://localhost:${port}/health`);
}
bootstrap();

})();

/******/ })()
;