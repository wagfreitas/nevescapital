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
const auth_module_1 = __webpack_require__(20);
const database_module_1 = __webpack_require__(21);
const health_controller_1 = __webpack_require__(22);
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
        controllers: [health_controller_1.HealthController],
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
const encryption_service_1 = __webpack_require__(11);
let UsersModule = class UsersModule {
};
exports.UsersModule = UsersModule;
exports.UsersModule = UsersModule = __decorate([
    (0, common_1.Module)({
        controllers: [users_controller_1.UsersController],
        providers: [users_service_1.UsersService, encryption_service_1.EncryptionService],
        exports: [users_service_1.UsersService],
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
        const encrypted = buffer.toString('utf8');
        const decrypted = this.encryptionService.decrypt(encrypted);
        if (!decrypted) {
            throw new Error('Falha na descriptografia');
        }
        return decrypted;
    }
    async create(createUserDto) {
        const client = await this.pool.connect();
        try {
            await client.query('BEGIN');
            const cpfEncrypted = this.encryptToBytea(createUserDto.cpf);
            const existingCpf = await client.query('SELECT id FROM users WHERE cpf_encrypted = $1', [cpfEncrypted]);
            if (existingCpf.rows.length > 0) {
                throw new common_1.ConflictException('CPF já cadastrado');
            }
            const emailEncrypted = this.encryptToBytea(createUserDto.email);
            const existingEmail = await client.query('SELECT id FROM users WHERE email_encrypted = $1', [emailEncrypted]);
            if (existingEmail.rows.length > 0) {
                throw new common_1.ConflictException('Email já cadastrado');
            }
            const fullNameEncrypted = this.encryptToBytea(createUserDto.fullName);
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
            const cpfEncrypted = this.encryptToBytea(cpf);
            const result = await this.pool.query(`SELECT 
          u.id,
          u.full_name,
          u.cpf_encrypted,
          u.email_encrypted,
          u.kyc_status,
          u.created_at
        FROM users u
        WHERE u.cpf_encrypted = $1 AND u.deleted_at IS NULL`, [cpfEncrypted]);
            if (result.rows.length === 0) {
                throw new common_1.NotFoundException('Usuário não encontrado');
            }
            const user = result.rows[0];
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
/* 21 */
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
                    const pool = new pg_1.Pool({
                        host: process.env.DB_HOST,
                        port: parseInt(process.env.DB_PORT || '5432'),
                        database: process.env.DB_NAME,
                        user: process.env.DB_USER,
                        password: process.env.DB_PASSWORD,
                        ssl: false,
                        max: 10,
                        idleTimeoutMillis: 30000,
                        connectionTimeoutMillis: 2000,
                    });
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
/* 22 */
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