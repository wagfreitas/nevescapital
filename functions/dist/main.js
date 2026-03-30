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
const health_controller_1 = __webpack_require__(35);
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
const config_1 = __webpack_require__(6);
const users_service_1 = __webpack_require__(9);
const users_controller_1 = __webpack_require__(12);
let UsersModule = class UsersModule {
};
exports.UsersModule = UsersModule;
exports.UsersModule = UsersModule = __decorate([
    (0, common_1.Module)({
        imports: [config_1.ConfigModule],
        controllers: [users_controller_1.UsersController],
        providers: [users_service_1.UsersService],
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
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.UsersService = void 0;
const common_1 = __webpack_require__(2);
const admin = __webpack_require__(10);
const crypto = __webpack_require__(11);
let UsersService = class UsersService {
    constructor() {
        this.db = admin.firestore();
    }
    async findByCpf(cpf) {
        try {
            const normalizedCpf = cpf.replace(/\D/g, '');
            const usersRef = this.db.collection('users');
            const snapshot = await usersRef.where('cpf', '==', normalizedCpf).limit(1).get();
            if (snapshot.empty) {
                throw new common_1.NotFoundException('Usuário não encontrado');
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
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao buscar usuário: ${error.message}`);
        }
    }
    async findByEmail(email) {
        try {
            const usersRef = this.db.collection('users');
            const snapshot = await usersRef.where('email', '==', email.toLowerCase()).limit(1).get();
            if (snapshot.empty) {
                throw new common_1.NotFoundException('Usuário não encontrado');
            }
            const userDoc = snapshot.docs[0];
            const userData = userDoc.data();
            return {
                id: userDoc.id,
                ...userData,
            };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao buscar usuário: ${error.message}`);
        }
    }
    async findByPhone(phone) {
        try {
            const normalizedPhone = phone.replace(/\D/g, '');
            console.log(`🔍 [UsersService] Buscando usuário por telefone: ${normalizedPhone.substring(0, 4)}****`);
            console.log(`📋 [UsersService] Firestore instance: ${this.db ? 'OK' : 'NULL'}`);
            const adminModule = __webpack_require__(10);
            if (!adminModule.apps.length) {
                throw new Error('Firebase Admin SDK não está inicializado');
            }
            console.log(`📋 [UsersService] Firebase Admin apps: ${adminModule.apps.length}`);
            console.log(`📋 [UsersService] Project ID: ${adminModule.app().options.projectId}`);
            const adminFirestoreType = adminModule.firestore.Firestore;
            const isAdminSdk = this.db.constructor.name === 'Firestore' || this.db instanceof adminFirestoreType;
            console.log(`📋 [UsersService] Usando Admin SDK: ${isAdminSdk} (tipo: ${this.db.constructor.name})`);
            if (!isAdminSdk) {
                console.error('🚨 ERRO CRÍTICO: Não está usando Admin SDK! As regras do Firestore serão aplicadas.');
                throw new Error('ERRO CRÍTICO: Não está usando Admin SDK! As regras do Firestore serão aplicadas.');
            }
            const usersRef = this.db.collection('users');
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
        }
        catch (error) {
            console.error(`❌ [UsersService] Erro ao buscar usuário por telefone:`, {
                message: error.message,
                code: error.code,
                details: error.details,
                stack: error.stack,
            });
            if (error.code === 7 || error.code === 'PERMISSION_DENIED' || error.message?.includes('Permission denied') || error.message?.includes('PERMISSION_DENIED')) {
                console.error(`🚨 [UsersService] ERRO DE PERMISSÃO DETECTADO`);
                console.error(`🚨 [UsersService] Possíveis causas:`);
                console.error(`   1. Serviço Cloud Run não tem permissão IAM (roles/datastore.user)`);
                console.error(`   2. ProjectId incorreto`);
                console.error(`   3. Admin SDK não inicializado corretamente`);
                throw new common_1.BadRequestException('Erro de permissão ao acessar Firestore. Verifique as permissões IAM do serviço Cloud Run e a configuração do Admin SDK.');
            }
            throw new common_1.BadRequestException(`Erro ao buscar usuário: ${error.message}`);
        }
    }
    async findById(userId) {
        try {
            const userDoc = await this.db.collection('users').doc(userId).get();
            if (!userDoc.exists) {
                throw new common_1.NotFoundException('Usuário não encontrado');
            }
            return {
                id: userDoc.id,
                ...userDoc.data(),
            };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao buscar usuário: ${error.message}`);
        }
    }
    async checkByCpf(cpf) {
        try {
            await this.findByCpf(cpf);
            return { exists: true };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                return { exists: false };
            }
            throw error;
        }
    }
    async create(createUserDto) {
        try {
            const normalizedCpf = createUserDto.cpf.replace(/\D/g, '');
            try {
                await this.findByCpf(normalizedCpf);
                throw new common_1.BadRequestException('CPF já cadastrado');
            }
            catch (error) {
                if (!(error instanceof common_1.NotFoundException)) {
                    throw error;
                }
            }
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
        }
        catch (error) {
            if (error instanceof common_1.BadRequestException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao criar usuário: ${error.message}`);
        }
    }
    async update(userId, updateUserDto) {
        try {
            const userRef = this.db.collection('users').doc(userId);
            const userDoc = await userRef.get();
            if (!userDoc.exists) {
                throw new common_1.NotFoundException('Usuário não encontrado');
            }
            const updateData = {
                updated_at: admin.firestore.FieldValue.serverTimestamp(),
            };
            if (updateUserDto.full_name)
                updateData.full_name = updateUserDto.full_name;
            if (updateUserDto.email)
                updateData.email = updateUserDto.email.toLowerCase();
            if (updateUserDto.phone)
                updateData.phone = updateUserDto.phone.replace(/\D/g, '');
            await userRef.update(updateData);
            const updatedDoc = await userRef.get();
            return {
                id: updatedDoc.id,
                ...updatedDoc.data(),
            };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao atualizar usuário: ${error.message}`);
        }
    }
    async remove(userId) {
        try {
            const userRef = this.db.collection('users').doc(userId);
            const userDoc = await userRef.get();
            if (!userDoc.exists) {
                throw new common_1.NotFoundException('Usuário não encontrado');
            }
            await userRef.update({
                deleted_at: admin.firestore.FieldValue.serverTimestamp(),
                updated_at: admin.firestore.FieldValue.serverTimestamp(),
            });
            return { success: true, message: 'Usuário removido com sucesso' };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao remover usuário: ${error.message}`);
        }
    }
    async deleteUserDataComplete(userId) {
        try {
            console.log(`🗑️ [UsersService] Iniciando limpeza completa dos dados do usuário: ${userId}`);
            const userRef = this.db.collection('users').doc(userId);
            const userDoc = await userRef.get();
            if (!userDoc.exists) {
                throw new common_1.NotFoundException('Usuário não encontrado no Firestore');
            }
            const userData = userDoc.data();
            const ownerUid = userData['ownerUid'];
            console.log(`📄 [UsersService] Documento encontrado. ownerUid: ${ownerUid || 'não vinculado'}`);
            const results = {
                storageDeleted: false,
                authDeleted: false,
                firestoreDeleted: false,
            };
            try {
                console.log('📦 [UsersService] Deletando arquivos do Storage...');
                const bucket = admin.storage().bucket();
                const folderPath = `users/${userId}/kyc`;
                const [files] = await bucket.getFiles({ prefix: folderPath });
                if (files.length > 0) {
                    await Promise.all(files.map(file => file.delete()));
                    console.log(`✅ [UsersService] ${files.length} arquivo(s) do Storage deletado(s)`);
                }
                else {
                    console.log('ℹ️ [UsersService] Nenhum arquivo encontrado no Storage');
                }
                results.storageDeleted = true;
            }
            catch (error) {
                console.warn(`⚠️ [UsersService] Erro ao deletar arquivos do Storage (continuando): ${error.message}`);
            }
            if (ownerUid) {
                try {
                    console.log(`🔐 [UsersService] Deletando conta do Firebase Auth (UID: ${ownerUid})...`);
                    await admin.auth().deleteUser(ownerUid);
                    console.log('✅ [UsersService] Conta do Firebase Auth deletada');
                    results.authDeleted = true;
                }
                catch (error) {
                    if (error.code === 'auth/user-not-found') {
                        console.log('ℹ️ [UsersService] Usuário não encontrado no Firebase Auth (pode já ter sido deletado)');
                    }
                    else {
                        console.warn(`⚠️ [UsersService] Erro ao deletar conta do Firebase Auth (continuando): ${error.message}`);
                    }
                }
            }
            else {
                console.log('ℹ️ [UsersService] Usuário não possui conta no Firebase Auth (ownerUid não encontrado)');
            }
            try {
                console.log('🗄️ [UsersService] Deletando documento do Firestore...');
                await userRef.delete();
                console.log('✅ [UsersService] Documento do Firestore deletado');
                results.firestoreDeleted = true;
            }
            catch (error) {
                console.error(`❌ [UsersService] Erro ao deletar documento do Firestore: ${error.message}`);
                throw new common_1.BadRequestException(`Erro ao deletar documento do Firestore: ${error.message}`);
            }
            console.log('✅ [UsersService] Limpeza completa dos dados do usuário concluída com sucesso');
            return {
                success: true,
                message: 'Dados do usuário deletados com sucesso',
                details: results,
            };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            console.error(`❌ [UsersService] Erro durante limpeza dos dados do usuário: ${error.message}`);
            throw new common_1.BadRequestException(`Erro ao deletar dados do usuário: ${error.message}`);
        }
    }
    async verifyPassword(verifyPasswordDto) {
        throw new common_1.BadRequestException('Verificação de senha deve ser feita via Firebase Auth no frontend');
    }
    async syncFirebaseEmail(cpf, oldEmail) {
        try {
            const user = await this.findByCpf(cpf);
            let firebaseUser;
            try {
                firebaseUser = await admin.auth().getUserByEmail(oldEmail);
            }
            catch (error) {
                throw new common_1.NotFoundException('Usuário não encontrado no Firebase Auth');
            }
            await this.db.collection('users').doc(user.id).update({
                email: firebaseUser.email,
                updated_at: admin.firestore.FieldValue.serverTimestamp(),
            });
            return { success: true, message: 'Email sincronizado com sucesso' };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao sincronizar email: ${error.message}`);
        }
    }
    async getStoreData(userId) {
        try {
            const storeDoc = await this.db.collection('user_stores').doc(userId).get();
            if (!storeDoc.exists) {
                throw new common_1.NotFoundException('Dados da loja não encontrados');
            }
            return {
                id: storeDoc.id,
                ...storeDoc.data(),
            };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao buscar dados da loja: ${error.message}`);
        }
    }
    async upsertStoreData(userId, storeDataDto) {
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
        }
        catch (error) {
            throw new common_1.BadRequestException(`Erro ao salvar dados da loja: ${error.message}`);
        }
    }
    async getPixKeys(userId) {
        try {
            const pixKeysRef = this.db.collection('user_pix_keys').where('user_id', '==', userId);
            const snapshot = await pixKeysRef.get();
            return snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data(),
            }));
        }
        catch (error) {
            throw new common_1.BadRequestException(`Erro ao buscar chaves PIX: ${error.message}`);
        }
    }
    async addPixKey(userId, createPixKeyDto) {
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
        }
        catch (error) {
            throw new common_1.BadRequestException(`Erro ao adicionar chave PIX: ${error.message}`);
        }
    }
    async removePixKey(userId, keyId) {
        try {
            const pixKeyRef = this.db.collection('user_pix_keys').doc(keyId);
            const pixKeyDoc = await pixKeyRef.get();
            if (!pixKeyDoc.exists) {
                throw new common_1.NotFoundException('Chave PIX não encontrada');
            }
            const pixKeyData = pixKeyDoc.data();
            if (pixKeyData?.user_id !== userId) {
                throw new common_1.BadRequestException('Chave PIX não pertence ao usuário');
            }
            await pixKeyRef.delete();
            return { success: true, message: 'Chave PIX removida com sucesso' };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException || error instanceof common_1.BadRequestException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao remover chave PIX: ${error.message}`);
        }
    }
    async updateLastLogin(userId) {
        try {
            const userRef = this.db.collection('users').doc(userId);
            await userRef.update({
                last_login: admin.firestore.FieldValue.serverTimestamp(),
                updated_at: admin.firestore.FieldValue.serverTimestamp(),
            });
            return { success: true };
        }
        catch (error) {
            console.error(`Erro ao atualizar último login: ${error.message}`);
            return { success: false };
        }
    }
};
exports.UsersService = UsersService;
exports.UsersService = UsersService = __decorate([
    (0, common_1.Injectable)()
], UsersService);


/***/ }),
/* 10 */
/***/ ((module) => {

module.exports = require("firebase-admin");

/***/ }),
/* 11 */
/***/ ((module) => {

module.exports = require("crypto");

/***/ }),
/* 12 */
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
var _a, _b, _c, _d, _e, _f;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.UsersController = void 0;
const common_1 = __webpack_require__(2);
const swagger_1 = __webpack_require__(3);
const throttler_1 = __webpack_require__(7);
const users_service_1 = __webpack_require__(9);
const create_user_dto_1 = __webpack_require__(13);
const update_user_dto_1 = __webpack_require__(15);
const verify_password_dto_1 = __webpack_require__(16);
const store_data_dto_1 = __webpack_require__(17);
const pix_key_dto_1 = __webpack_require__(18);
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
    checkByCpf(cpf) {
        return this.usersService.checkByCpf(cpf);
    }
    async findByEmail(email) {
        const decodedEmail = decodeURIComponent(email);
        console.log(`📧 Email recebido na URL: ${email}`);
        console.log(`📧 Email decodificado: ${decodedEmail}`);
        return this.usersService.findByEmail(decodedEmail);
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
    deleteUserDataComplete(id) {
        return this.usersService.deleteUserDataComplete(id);
    }
    syncFirebaseEmail(body) {
        return this.usersService.syncFirebaseEmail(body.cpf, body.oldEmail);
    }
    getStoreData(id) {
        return this.usersService.getStoreData(id);
    }
    upsertStoreData(id, storeDataDto) {
        return this.usersService.upsertStoreData(id, storeDataDto);
    }
    getPixKeys(id) {
        return this.usersService.getPixKeys(id);
    }
    addPixKey(id, createPixKeyDto) {
        return this.usersService.addPixKey(id, createPixKeyDto);
    }
    removePixKey(id, keyId) {
        return this.usersService.removePixKey(id, keyId);
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
    (0, common_1.Get)('check-cpf/:cpf'),
    (0, swagger_1.ApiOperation)({ summary: 'Verificar se CPF existe (sem retornar PII)' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Status do CPF retornado' }),
    __param(0, (0, common_1.Param)('cpf')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "checkByCpf", null);
__decorate([
    (0, common_1.Get)('email/:email'),
    (0, swagger_1.ApiOperation)({ summary: 'Buscar usuário por email' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Usuário encontrado' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Usuário não encontrado' }),
    __param(0, (0, common_1.Param)('email')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], UsersController.prototype, "findByEmail", null);
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
__decorate([
    (0, common_1.Delete)(':id/complete'),
    (0, swagger_1.ApiOperation)({
        summary: 'Deletar todos os dados do usuário (hard delete completo)',
        description: 'Deleta permanentemente: documentos KYC no Storage, conta do Firebase Auth e documento no Firestore. **ATENÇÃO: Operação irreversível!**'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Dados do usuário deletados com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Usuário não encontrado' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Erro ao deletar dados do usuário' }),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "deleteUserDataComplete", null);
__decorate([
    (0, common_1.Post)('sync-firebase-email'),
    (0, swagger_1.ApiOperation)({ summary: 'Sincronizar email do Firebase com Firestore' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Email sincronizado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Usuário não encontrado' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "syncFirebaseEmail", null);
__decorate([
    (0, common_1.Get)(':id/store'),
    (0, swagger_1.ApiOperation)({ summary: 'Buscar dados da loja do usuário' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Dados da loja encontrados' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Dados da loja não encontrados' }),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "getStoreData", null);
__decorate([
    (0, common_1.Put)(':id/store'),
    (0, swagger_1.ApiOperation)({ summary: 'Criar ou atualizar dados da loja do usuário' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Dados da loja salvos com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Usuário não encontrado' }),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, typeof (_e = typeof store_data_dto_1.StoreDataDto !== "undefined" && store_data_dto_1.StoreDataDto) === "function" ? _e : Object]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "upsertStoreData", null);
__decorate([
    (0, common_1.Get)(':id/pix-keys'),
    (0, swagger_1.ApiOperation)({ summary: 'Buscar chaves PIX do usuário' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Chaves PIX encontradas' }),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "getPixKeys", null);
__decorate([
    (0, common_1.Post)(':id/pix-keys'),
    (0, swagger_1.ApiOperation)({ summary: 'Adicionar chave PIX' }),
    (0, swagger_1.ApiResponse)({ status: 201, description: 'Chave PIX cadastrada com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Chave PIX inválida' }),
    (0, swagger_1.ApiResponse)({ status: 409, description: 'Chave PIX já cadastrada' }),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, typeof (_f = typeof pix_key_dto_1.CreatePixKeyDto !== "undefined" && pix_key_dto_1.CreatePixKeyDto) === "function" ? _f : Object]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "addPixKey", null);
__decorate([
    (0, common_1.Delete)(':id/pix-keys/:keyId'),
    (0, swagger_1.ApiOperation)({ summary: 'Remover chave PIX' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Chave PIX removida com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Chave PIX não encontrada' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Não é possível remover a única chave PIX' }),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Param)('keyId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], UsersController.prototype, "removePixKey", null);
exports.UsersController = UsersController = __decorate([
    (0, swagger_1.ApiTags)('Users'),
    (0, common_1.Controller)('api/users'),
    (0, common_1.UseGuards)(api_key_guard_1.ApiKeyGuard),
    (0, swagger_1.ApiSecurity)('api-key'),
    __metadata("design:paramtypes", [typeof (_a = typeof users_service_1.UsersService !== "undefined" && users_service_1.UsersService) === "function" ? _a : Object])
], UsersController);


/***/ }),
/* 13 */
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
const class_validator_1 = __webpack_require__(14);
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
/* 14 */
/***/ ((module) => {

module.exports = require("class-validator");

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
exports.UpdateUserDto = void 0;
const class_validator_1 = __webpack_require__(14);
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
    (0, swagger_1.ApiPropertyOptional)({ example: 'novoemail@exemplo.com' }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsEmail)({}, { message: 'Email inválido' }),
    __metadata("design:type", String)
], UpdateUserDto.prototype, "email", void 0);
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
/* 16 */
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
const class_validator_1 = __webpack_require__(14);
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
exports.StoreDataDto = void 0;
const class_validator_1 = __webpack_require__(14);
const swagger_1 = __webpack_require__(3);
class StoreDataDto {
}
exports.StoreDataDto = StoreDataDto;
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'Minha Loja LTDA' }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Nome da loja é obrigatório' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(3, { message: 'Nome da loja deve ter pelo menos 3 caracteres' }),
    (0, class_validator_1.MaxLength)(255, { message: 'Nome da loja deve ter no máximo 255 caracteres' }),
    __metadata("design:type", String)
], StoreDataDto.prototype, "store_name", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ example: 'Alimentação' }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Ramo de atividade é obrigatório' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(2, { message: 'Ramo de atividade deve ter pelo menos 2 caracteres' }),
    (0, class_validator_1.MaxLength)(100, { message: 'Ramo de atividade deve ter no máximo 100 caracteres' }),
    __metadata("design:type", String)
], StoreDataDto.prototype, "business_type", void 0);


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
exports.ReorderPixKeysDto = exports.UpdatePixKeyDto = exports.CreatePixKeyDto = void 0;
const class_validator_1 = __webpack_require__(14);
const swagger_1 = __webpack_require__(3);
class CreatePixKeyDto {
}
exports.CreatePixKeyDto = CreatePixKeyDto;
__decorate([
    (0, swagger_1.ApiProperty)({ example: '11999999999' }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Chave PIX é obrigatória' }),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], CreatePixKeyDto.prototype, "pix_key", void 0);
class UpdatePixKeyDto {
}
exports.UpdatePixKeyDto = UpdatePixKeyDto;
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: false }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsBoolean)(),
    __metadata("design:type", Boolean)
], UpdatePixKeyDto.prototype, "is_primary", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 1 }),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsInt)(),
    (0, class_validator_1.Min)(0),
    (0, class_validator_1.Max)(10),
    __metadata("design:type", Number)
], UpdatePixKeyDto.prototype, "display_order", void 0);
class ReorderPixKeysDto {
}
exports.ReorderPixKeysDto = ReorderPixKeysDto;
__decorate([
    (0, swagger_1.ApiProperty)({ example: ['uuid1', 'uuid2', 'uuid3'] }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Lista de IDs é obrigatória' }),
    (0, class_validator_1.IsString)({ each: true }),
    __metadata("design:type", Array)
], ReorderPixKeysDto.prototype, "key_ids", void 0);


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
const config_1 = __webpack_require__(6);
const email_template_service_1 = __webpack_require__(21);
const email_sender_service_1 = __webpack_require__(24);
const simple_otp_service_1 = __webpack_require__(28);
const whatsapp_service_1 = __webpack_require__(29);
const auth_controller_1 = __webpack_require__(31);
const whatsapp_webhook_controller_1 = __webpack_require__(34);
const users_module_1 = __webpack_require__(8);
let AuthModule = class AuthModule {
};
exports.AuthModule = AuthModule;
exports.AuthModule = AuthModule = __decorate([
    (0, common_1.Module)({
        imports: [config_1.ConfigModule, users_module_1.UsersModule],
        controllers: [auth_controller_1.AuthController, whatsapp_webhook_controller_1.WhatsAppWebhookController],
        providers: [
            email_template_service_1.EmailTemplateService,
            email_sender_service_1.EmailSenderService,
            simple_otp_service_1.SimpleOtpService,
            whatsapp_service_1.WhatsAppService,
        ],
        exports: [email_template_service_1.EmailTemplateService, email_sender_service_1.EmailSenderService, simple_otp_service_1.SimpleOtpService, whatsapp_service_1.WhatsAppService],
    })
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
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var _a;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.EmailTemplateService = void 0;
const common_1 = __webpack_require__(2);
const config_1 = __webpack_require__(6);
const admin = __webpack_require__(10);
const fs = __webpack_require__(22);
const path = __webpack_require__(23);
let EmailTemplateService = class EmailTemplateService {
    constructor(configService) {
        this.configService = configService;
    }
    async generatePasswordResetLink(email, actionCodeSettings) {
        const auth = admin.auth();
        const link = await auth.generatePasswordResetLink(email, actionCodeSettings);
        return link;
    }
    getLogoSource() {
        const hostedUrl = this.configService.get('LOGO_HOSTED_URL', 'https://apppagpag.firebaseapp.com/assets/icons/PagPag.png');
        const logoBase64 = this.getLogoAsBase64();
        if (logoBase64) {
            return `data:image/png;base64,${logoBase64}`;
        }
        return hostedUrl;
    }
    getLogoAsBase64() {
        const possiblePaths = [
            path.join(__dirname, '../../../assets/icons/PagPag.png'),
            path.join(__dirname, '../../assets/icons/PagPag.png'),
            path.join(process.cwd(), 'assets/icons/PagPag.png'),
            path.join(process.cwd(), '../assets/icons/PagPag.png'),
        ];
        for (const logoPath of possiblePaths) {
            try {
                if (fs.existsSync(logoPath)) {
                    const logoBuffer = fs.readFileSync(logoPath);
                    const base64 = logoBuffer.toString('base64');
                    console.log(`✅ Logo carregada de: ${logoPath}`);
                    return base64;
                }
            }
            catch (error) {
                console.warn(`⚠️ Não foi possível carregar logo de ${logoPath}:`, error);
                continue;
            }
        }
        console.warn('⚠️ Logo não encontrada localmente, usando URL hospedada');
        return null;
    }
    getPasswordResetTemplate(link, email) {
        const logoSource = this.getLogoSource();
        const possiblePaths = [
            path.join(__dirname, '../../../docs/firebase-email-templates/reset-password-template.html'),
            path.join(__dirname, '../../docs/firebase-email-templates/reset-password-template.html'),
            path.join(process.cwd(), 'docs/firebase-email-templates/reset-password-template.html'),
        ];
        for (const templatePath of possiblePaths) {
            try {
                if (fs.existsSync(templatePath)) {
                    let template = fs.readFileSync(templatePath, 'utf8');
                    template = template.replace(/%LINK%/g, link);
                    template = template.replace(/%EMAIL%/g, email);
                    template = template.replace(/<img[^>]*src="[^"]*PagPag\.png[^"]*"[^>]*>/gi, `<img src="${logoSource}" alt="Pag Pag Logo" style="max-width: 200px; height: auto; display: block; margin: 0 auto;" width="200">`);
                    console.log(`✅ Template carregado de: ${templatePath}`);
                    console.log(`✅ Logo usando: ${logoSource.startsWith('data:') ? 'Base64 (inline)' : 'URL hospedada'}`);
                    return template;
                }
            }
            catch (error) {
                console.warn(`⚠️ Não foi possível carregar template de ${templatePath}:`, error);
                continue;
            }
        }
        console.warn('⚠️ Template HTML não encontrado, usando fallback');
        return this.getFallbackTemplate(link, email, logoSource);
    }
    getFallbackTemplate(link, email, logoSource) {
        const logo = logoSource || this.getLogoSource();
        return `
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Redefinir Senha - Pag Pag</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f5f5f5;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 20px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; padding: 40px;">
          <tr>
            <td style="background-color: #122118; padding: 40px 30px; text-align: center; border-radius: 8px 8px 0 0;">
              <div style="text-align: center;">
                <img src="${logo}" alt="Pag Pag Logo" style="max-width: 200px; height: auto; display: block; margin: 0 auto;">
              </div>
            </td>
          </tr>
          <tr>
            <td style="padding: 40px 30px;">
              <h1 style="color: #122118; margin: 0 0 20px 0;">Redefinição de Senha</h1>
              <p style="color: #333; font-size: 16px; line-height: 1.6;">
                Olá,<br><br>
                Recebemos uma solicitação para redefinir a senha da sua conta <strong>${email}</strong> no Pag Pag.
              </p>
              <p style="margin: 30px 0; text-align: center;">
                <a href="${link}" style="background-color: #22C55E; color: #122118; text-decoration: none; padding: 14px 32px; border-radius: 25px; font-weight: 600; display: inline-block;">
                  Redefinir Senha
                </a>
              </p>
              <p style="color: #666; font-size: 14px;">
                Se você não solicitou esta redefinição, pode ignorar este email.
              </p>
            </td>
          </tr>
          <tr>
            <td style="background-color: #f9f9f9; padding: 20px; text-align: center; border-top: 1px solid #eee;">
              <p style="color: #999; font-size: 12px; margin: 0;">
                © 2024 Pag Pag. Todos os direitos reservados.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
    `;
    }
};
exports.EmailTemplateService = EmailTemplateService;
exports.EmailTemplateService = EmailTemplateService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof config_1.ConfigService !== "undefined" && config_1.ConfigService) === "function" ? _a : Object])
], EmailTemplateService);


/***/ }),
/* 22 */
/***/ ((module) => {

module.exports = require("fs");

/***/ }),
/* 23 */
/***/ ((module) => {

module.exports = require("path");

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
var _a, _b;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.EmailSenderService = void 0;
const common_1 = __webpack_require__(2);
const config_1 = __webpack_require__(6);
const email_template_service_1 = __webpack_require__(21);
let EmailSenderService = class EmailSenderService {
    constructor(emailTemplateService, configService) {
        this.emailTemplateService = emailTemplateService;
        this.configService = configService;
    }
    async sendPasswordResetEmail(email, actionCodeSettings) {
        try {
            const resetLink = await this.emailTemplateService.generatePasswordResetLink(email, actionCodeSettings);
            const htmlContent = this.emailTemplateService.getPasswordResetTemplate(resetLink, email);
            const emailProvider = this.configService.get('EMAIL_PROVIDER', 'sendgrid');
            switch (emailProvider) {
                case 'sendgrid':
                    await this.sendViaSendGrid(email, htmlContent);
                    break;
                case 'aws-ses':
                    await this.sendViaAwsSes(email, htmlContent);
                    break;
                case 'resend':
                    await this.sendViaResend(email, htmlContent);
                    break;
                default:
                    console.warn(`Provedor de email ${emailProvider} não configurado. Email não enviado.`);
                    throw new Error(`Email provider ${emailProvider} não configurado`);
            }
            console.log(`✅ Email de reset enviado para: ${email}`);
        }
        catch (error) {
            console.error('❌ Erro ao enviar email de reset:', error);
            throw error;
        }
    }
    async sendViaSendGrid(email, htmlContent) {
        try {
            const sendgrid = __webpack_require__(25);
            const apiKey = this.configService.get('SENDGRID_API_KEY');
            if (!apiKey) {
                throw new Error('SENDGRID_API_KEY não configurada');
            }
            sendgrid.setApiKey(apiKey);
            const msg = {
                to: email,
                from: this.configService.get('EMAIL_FROM', 'noreply@pagpag.com.br'),
                subject: 'Redefinir Senha - Pag Pag',
                html: htmlContent,
            };
            await sendgrid.send(msg);
        }
        catch (error) {
            if (error.code === 'MODULE_NOT_FOUND') {
                throw new Error('@sendgrid/mail não instalado. Execute: npm install @sendgrid/mail');
            }
            throw error;
        }
    }
    async sendViaAwsSes(email, htmlContent) {
        try {
            const { SESClient, SendEmailCommand } = __webpack_require__(26);
            const sesClient = new SESClient({
                region: this.configService.get('AWS_REGION', 'us-east-1'),
                credentials: {
                    accessKeyId: this.configService.get('AWS_ACCESS_KEY_ID'),
                    secretAccessKey: this.configService.get('AWS_SECRET_ACCESS_KEY'),
                },
            });
            const command = new SendEmailCommand({
                Source: this.configService.get('EMAIL_FROM', 'noreply@pagpag.com.br'),
                Destination: { ToAddresses: [email] },
                Message: {
                    Subject: { Data: 'Redefinir Senha - Pag Pag' },
                    Body: { Html: { Data: htmlContent } },
                },
            });
            await sesClient.send(command);
        }
        catch (error) {
            if (error.code === 'MODULE_NOT_FOUND') {
                throw new Error('@aws-sdk/client-ses não instalado. Execute: npm install @aws-sdk/client-ses');
            }
            throw error;
        }
    }
    async sendViaResend(email, htmlContent) {
        try {
            const { Resend } = __webpack_require__(27);
            const apiKey = this.configService.get('RESEND_API_KEY');
            if (!apiKey) {
                throw new Error('RESEND_API_KEY não configurada');
            }
            const resend = new Resend(apiKey);
            await resend.emails.send({
                from: this.configService.get('EMAIL_FROM', 'noreply@pagpag.com.br'),
                to: email,
                subject: 'Redefinir Senha - Pag Pag',
                html: htmlContent,
            });
        }
        catch (error) {
            if (error.code === 'MODULE_NOT_FOUND') {
                throw new Error('resend não instalado. Execute: npm install resend');
            }
            throw error;
        }
    }
};
exports.EmailSenderService = EmailSenderService;
exports.EmailSenderService = EmailSenderService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof email_template_service_1.EmailTemplateService !== "undefined" && email_template_service_1.EmailTemplateService) === "function" ? _a : Object, typeof (_b = typeof config_1.ConfigService !== "undefined" && config_1.ConfigService) === "function" ? _b : Object])
], EmailSenderService);


/***/ }),
/* 25 */
/***/ ((module) => {

module.exports = require("@sendgrid/mail");

/***/ }),
/* 26 */
/***/ ((module) => {

module.exports = require("@aws-sdk/client-ses");

/***/ }),
/* 27 */
/***/ ((module) => {

module.exports = require("resend");

/***/ }),
/* 28 */
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.SimpleOtpService = void 0;
const common_1 = __webpack_require__(2);
const admin = __webpack_require__(10);
let SimpleOtpService = class SimpleOtpService {
    constructor() {
        this.db = admin.firestore();
        this.otpCollection = 'otp_codes';
        this.otpExpirationMinutes = 10;
        this.maxAttempts = 5;
    }
    generateOtpCode() {
        return Math.floor(1000 + Math.random() * 9000).toString();
    }
    async sendOtp(phone) {
        try {
            const normalizedPhone = phone.replace(/\D/g, '');
            if (normalizedPhone.length < 10) {
                return {
                    success: false,
                    message: 'Número de telefone inválido',
                };
            }
            const code = this.generateOtpCode();
            const expiresAt = new Date();
            expiresAt.setMinutes(expiresAt.getMinutes() + this.otpExpirationMinutes);
            const otpDoc = {
                phone: normalizedPhone,
                code,
                expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
                attempts: 0,
                verified: false,
                createdAt: admin.firestore.FieldValue.serverTimestamp(),
            };
            const tQuery = Date.now();
            const oldOtps = await this.db
                .collection(this.otpCollection)
                .where('phone', '==', normalizedPhone)
                .get();
            console.log(`⏱️ [OTP-TIMING]   query OTPs antigos: ${Date.now() - tQuery}ms (found: ${oldOtps.size})`);
            const batch = this.db.batch();
            oldOtps.docs.forEach((doc) => {
                batch.delete(doc.ref);
            });
            const tWrite = Date.now();
            await batch.commit();
            await this.db.collection(this.otpCollection).add(otpDoc);
            console.log(`⏱️ [OTP-TIMING]   batch+add: ${Date.now() - tWrite}ms`);
            return {
                success: true,
                code,
                message: `Código OTP gerado. Para testes, use: ${code}`,
            };
        }
        catch (error) {
            console.error('Erro ao enviar OTP:', error?.message || error, error?.code);
            return {
                success: false,
                message: process.env.NODE_ENV === 'development'
                    ? `Erro ao gerar código OTP: ${error?.message || String(error)}`
                    : 'Erro ao gerar código OTP',
            };
        }
    }
    async verifyOtp(phone, code) {
        try {
            const normalizedPhone = phone.replace(/\D/g, '');
            const otpQuery = await this.db
                .collection(this.otpCollection)
                .where('phone', '==', normalizedPhone)
                .where('verified', '==', false)
                .orderBy('createdAt', 'desc')
                .limit(1)
                .get();
            if (otpQuery.empty) {
                return {
                    success: false,
                    message: 'Código OTP não encontrado ou já utilizado',
                };
            }
            const otpDoc = otpQuery.docs[0];
            const otpData = otpDoc.data();
            const expiresAt = otpData.expiresAt instanceof admin.firestore.Timestamp
                ? otpData.expiresAt.toDate()
                : new Date(otpData.expiresAt);
            if (new Date() > expiresAt) {
                await otpDoc.ref.delete();
                return {
                    success: false,
                    message: 'Código OTP expirado. Solicite um novo código.',
                };
            }
            if (otpData.attempts >= this.maxAttempts) {
                await otpDoc.ref.delete();
                return {
                    success: false,
                    message: 'Número máximo de tentativas excedido. Solicite um novo código.',
                };
            }
            if (otpData.code !== code) {
                await otpDoc.ref.update({
                    attempts: admin.firestore.FieldValue.increment(1),
                });
                const remainingAttempts = this.maxAttempts - otpData.attempts - 1;
                return {
                    success: false,
                    message: `Código incorreto. Tentativas restantes: ${remainingAttempts}`,
                };
            }
            await otpDoc.ref.update({
                verified: true,
            });
            return {
                success: true,
                message: 'Código OTP verificado com sucesso',
            };
        }
        catch (error) {
            console.error('Erro ao verificar OTP:', error);
            return {
                success: false,
                message: 'Erro ao verificar código OTP',
            };
        }
    }
    async cleanupExpiredOtps() {
        try {
            const now = admin.firestore.Timestamp.now();
            const expiredOtps = await this.db
                .collection(this.otpCollection)
                .where('expiresAt', '<', now)
                .get();
            const batch = this.db.batch();
            expiredOtps.docs.forEach((doc) => {
                batch.delete(doc.ref);
            });
            await batch.commit();
            console.log(`Limpeza: ${expiredOtps.size} OTPs expirados removidos`);
        }
        catch (error) {
            console.error('Erro ao limpar OTPs expirados:', error);
        }
    }
};
exports.SimpleOtpService = SimpleOtpService;
exports.SimpleOtpService = SimpleOtpService = __decorate([
    (0, common_1.Injectable)()
], SimpleOtpService);


/***/ }),
/* 29 */
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
var WhatsAppService_1;
var _a;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.WhatsAppService = void 0;
const common_1 = __webpack_require__(2);
const config_1 = __webpack_require__(6);
const Twilio = __webpack_require__(30);
let WhatsAppService = WhatsAppService_1 = class WhatsAppService {
    constructor(configService) {
        this.configService = configService;
        this.logger = new common_1.Logger(WhatsAppService_1.name);
        const accountSid = this.configService.get('TWILIO_ACCOUNT_SID', '');
        const authToken = this.configService.get('TWILIO_AUTH_TOKEN', '');
        this.fromNumber = this.configService.get('TWILIO_WHATSAPP_FROM', '');
        this.client = Twilio(accountSid, authToken);
        this.logger.log(`WhatsApp service initialized (Twilio, from: ${this.fromNumber})`);
    }
    formatPhone(phone) {
        const clean = phone.replace(/\D/g, '');
        return `whatsapp:+${clean}`;
    }
    async sendTextMessage(phone, text) {
        try {
            const cleanPhone = phone.replace(/\D/g, '');
            if (cleanPhone.length < 12) {
                this.logger.error(`Telefone inválido para WhatsApp: ${cleanPhone.substring(0, 4)}***`);
                return false;
            }
            const message = await this.client.messages.create({
                body: text,
                from: `whatsapp:${this.fromNumber}`,
                to: this.formatPhone(cleanPhone),
            });
            this.logger.log(`WhatsApp mensagem enviada para ${cleanPhone.substring(0, 4)}*** (SID: ${message.sid})`);
            return true;
        }
        catch (error) {
            this.logger.error(`Erro ao enviar mensagem WhatsApp: ${error.message}`, error.stack);
            return false;
        }
    }
    async sendOtpMessage(phone, code) {
        try {
            const cleanPhone = phone.replace(/\D/g, '');
            if (cleanPhone.length < 12) {
                this.logger.error(`Telefone inválido para WhatsApp: ${cleanPhone.substring(0, 4)}***`);
                return false;
            }
            this.logger.log(`Enviando OTP via WhatsApp para: ${cleanPhone.substring(0, 4)}***`);
            const message = await this.client.messages.create({
                body: `${code} é o seu código de verificação PagPag.`,
                from: `whatsapp:${this.fromNumber}`,
                to: this.formatPhone(cleanPhone),
            });
            this.logger.log(`WhatsApp OTP enviado com sucesso (SID: ${message.sid})`);
            return true;
        }
        catch (error) {
            this.logger.error(`Erro ao enviar OTP via WhatsApp: ${error.message}`, error.stack);
            return false;
        }
    }
    async checkConnection() {
        try {
            const sid = this.configService.get('TWILIO_ACCOUNT_SID', '');
            const account = await this.client.api.accounts(sid).fetch();
            this.logger.log(`Twilio connection OK: ${account.friendlyName} (status: ${account.status})`);
            return account.status === 'active';
        }
        catch (error) {
            this.logger.error(`Twilio connection check failed: ${error.message}`);
            return false;
        }
    }
};
exports.WhatsAppService = WhatsAppService;
WhatsAppService.AUTO_REPLY_MESSAGE = 'Esse canal é destinado apenas ao envio de codigo OTP e nao está preparado para receber qualquer mensagem.';
exports.WhatsAppService = WhatsAppService = WhatsAppService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof config_1.ConfigService !== "undefined" && config_1.ConfigService) === "function" ? _a : Object])
], WhatsAppService);


/***/ }),
/* 30 */
/***/ ((module) => {

module.exports = require("twilio");

/***/ }),
/* 31 */
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
var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.AuthController = void 0;
const common_1 = __webpack_require__(2);
const swagger_1 = __webpack_require__(3);
const throttler_1 = __webpack_require__(7);
const api_key_guard_1 = __webpack_require__(19);
const admin = __webpack_require__(10);
const email_sender_service_1 = __webpack_require__(24);
const simple_otp_service_1 = __webpack_require__(28);
const whatsapp_service_1 = __webpack_require__(29);
const users_service_1 = __webpack_require__(9);
const reset_password_dto_1 = __webpack_require__(32);
const send_phone_otp_dto_1 = __webpack_require__(33);
let AuthController = class AuthController {
    constructor(emailSenderService, simpleOtpService, whatsAppService, usersService) {
        this.emailSenderService = emailSenderService;
        this.simpleOtpService = simpleOtpService;
        this.whatsAppService = whatsAppService;
        this.usersService = usersService;
    }
    async resetPassword(resetPasswordDto) {
        try {
            await this.emailSenderService.sendPasswordResetEmail(resetPasswordDto.email);
            return {
                success: true,
                message: 'Email de redefinição de senha enviado com sucesso',
            };
        }
        catch (error) {
            throw error;
        }
    }
    async sendOtp(body) {
        const result = await this.simpleOtpService.sendOtp(body.phone);
        if (!result.success) {
            throw new common_1.BadRequestException(result.message);
        }
        return {
            success: true,
            message: result.message,
            code: result.code,
        };
    }
    async verifyOtp(body) {
        const result = await this.simpleOtpService.verifyOtp(body.phone, body.code);
        if (!result.success) {
            throw new common_1.BadRequestException(result.message);
        }
        return {
            success: true,
            message: result.message,
        };
    }
    async sendOtpWhatsApp(body) {
        const t0 = Date.now();
        const t1 = Date.now();
        const result = await this.simpleOtpService.sendOtp(body.phone);
        const t2 = Date.now();
        console.log(`⏱️ [OTP-TIMING] Firestore (gerar+salvar OTP): ${t2 - t1}ms`);
        if (!result.success) {
            throw new common_1.BadRequestException(result.message);
        }
        if (result.code) {
            const t3 = Date.now();
            this.whatsAppService.sendOtpMessage(body.phone, result.code)
                .then((sent) => {
                console.log(`⏱️ [OTP-TIMING] Twilio WhatsApp: ${Date.now() - t3}ms`);
                if (!sent) {
                    console.warn(`⚠️ [AuthController] Falha ao enviar OTP via WhatsApp para ${body.phone.substring(0, 4)}***`);
                }
            })
                .catch((err) => {
                console.error(`❌ [AuthController] Erro ao enviar OTP via WhatsApp: ${err.message}`);
            });
        }
        console.log(`⏱️ [OTP-TIMING] TOTAL (até response): ${Date.now() - t0}ms`);
        return {
            success: true,
            message: 'Código de verificação enviado via WhatsApp',
        };
    }
    async verifyOtpLogin(body) {
        const otpResult = await this.simpleOtpService.verifyOtp(body.phone, body.code);
        if (!otpResult.success) {
            throw new common_1.BadRequestException(otpResult.message);
        }
        const normalizedPhone = body.phone.replace(/\D/g, '');
        console.log(`✅ [AuthController] OTP verificado para ${normalizedPhone.substring(0, 4)}***`);
        const user = await this.usersService.findByPhone(normalizedPhone);
        if (user) {
            const isComplete = this.isRegistrationComplete(user);
            if (!isComplete) {
                console.log(`⚠️ [AuthController] Usuário encontrado mas cadastro incompleto. ID: ${user.id}`);
                return {
                    success: true,
                    status: 'REGISTER',
                    message: 'Cadastro incompleto. Redirecionando para finalizar cadastro.',
                    phone: normalizedPhone,
                };
            }
            console.log(`✅ [AuthController] Usuário completo encontrado. ID: ${user.id}`);
            try {
                let firebaseUid;
                try {
                    const firebaseUser = await admin.auth().getUserByPhoneNumber('+' + normalizedPhone);
                    firebaseUid = firebaseUser.uid;
                }
                catch (e) {
                    if (e.code === 'auth/user-not-found') {
                        const newUser = await admin.auth().createUser({
                            phoneNumber: '+' + normalizedPhone,
                        });
                        firebaseUid = newUser.uid;
                        console.log(`📝 [AuthController] Firebase Auth user criado: ${firebaseUid}`);
                    }
                    else {
                        throw e;
                    }
                }
                const customToken = await admin.auth().createCustomToken(firebaseUid);
                console.log(`🔑 [AuthController] Custom token gerado para UID: ${firebaseUid}`);
                try {
                    await this.usersService.updateLastLogin(user.id);
                }
                catch (error) {
                    console.warn(`⚠️ [AuthController] Erro ao registrar login (não crítico): ${error.message}`);
                }
                return {
                    success: true,
                    status: 'LOGGED_IN',
                    message: 'Login realizado com sucesso.',
                    customToken,
                    userId: user.id,
                    phone: normalizedPhone,
                    user: {
                        id: user.id,
                        full_name: user.full_name,
                        email: user.email,
                        phone: user.phone,
                    },
                };
            }
            catch (error) {
                console.error(`❌ [AuthController] Erro ao gerar custom token: ${error.message}`);
                throw new common_1.BadRequestException('Erro ao processar login. Tente novamente.');
            }
        }
        else {
            console.log(`📝 [AuthController] Usuário não encontrado para ${normalizedPhone.substring(0, 4)}***`);
            return {
                success: true,
                status: 'REGISTER',
                message: 'Usuário não encontrado. Redirecionando para cadastro.',
                phone: normalizedPhone,
            };
        }
    }
    async checkUserStatus(body) {
        try {
            console.log('🔐 [AuthController] Verificando status do usuário...');
            const decodedToken = await admin.auth().verifyIdToken(body.token);
            const firebaseUid = decodedToken.uid;
            const phoneNumber = decodedToken.phone_number;
            console.log(`📱 [AuthController] Token verificado. UID: ${firebaseUid}, Phone: ${phoneNumber?.substring(0, 4)}****`);
            if (!phoneNumber) {
                throw new common_1.BadRequestException('Token não contém número de telefone');
            }
            const normalizedPhone = phoneNumber.replace(/\D/g, '');
            console.log(`🔍 [AuthController] Buscando usuário no Firestore...`);
            const user = await this.usersService.findByPhone(normalizedPhone);
            if (user) {
                const isRegistrationComplete = this.isRegistrationComplete(user);
                if (!isRegistrationComplete) {
                    console.log(`⚠️ [AuthController] Usuário encontrado mas cadastro incompleto. ID: ${user.id}`);
                    return {
                        success: true,
                        status: 'REGISTER',
                        message: 'Cadastro incompleto. Redirecionando para finalizar cadastro.',
                        phone: normalizedPhone,
                    };
                }
                console.log(`✅ [AuthController] Usuário encontrado com cadastro completo. ID: ${user.id}`);
                try {
                    await this.usersService.updateLastLogin(user.id);
                    console.log(`📝 [AuthController] Login registrado para usuário ${user.id}`);
                }
                catch (error) {
                    console.warn(`⚠️ [AuthController] Erro ao registrar login (não crítico): ${error.message}`);
                }
                return {
                    success: true,
                    status: 'LOGGED_IN',
                    message: 'Usuário autenticado com sucesso. Redirecionando para o dashboard.',
                    phone: normalizedPhone,
                    userId: user.id,
                    user: {
                        id: user.id,
                        full_name: user.full_name,
                        email: user.email,
                        phone: user.phone,
                    },
                };
            }
            else {
                console.log(`📝 [AuthController] Usuário não encontrado. Redirecionando para cadastro.`);
                return {
                    success: true,
                    status: 'REGISTER',
                    message: 'Usuário não encontrado. Redirecionando para cadastro.',
                    phone: normalizedPhone,
                };
            }
        }
        catch (error) {
            console.error(`❌ [AuthController] Erro ao verificar status:`, {
                message: error.message,
                code: error.code,
                stack: error.stack,
            });
            if (error instanceof common_1.BadRequestException) {
                throw error;
            }
            if (error.code === 'auth/argument-error' || error.code === 'auth/id-token-expired') {
                throw new common_1.UnauthorizedException('Token inválido ou expirado');
            }
            throw new common_1.BadRequestException(`Erro ao verificar status: ${error.message}`);
        }
    }
    isRegistrationComplete(user) {
        const hasCpf = !!(user.cpfEncrypted || user.cpfHash || user.cpf);
        if (!hasCpf) {
            console.log(`⚠️ [AuthController] Campo obrigatório ausente: CPF (cpfEncrypted/cpfHash/cpf)`);
            return false;
        }
        const hasEmail = !!(user.emailEncrypted || user.emailHash || user.email);
        if (!hasEmail) {
            console.log(`⚠️ [AuthController] Campo obrigatório ausente: Email (emailEncrypted/emailHash/email)`);
            return false;
        }
        const hasFullName = !!(user.displayName || user.full_name);
        if (!hasFullName) {
            console.log(`⚠️ [AuthController] Campo obrigatório ausente: Nome Completo (displayName/full_name)`);
            return false;
        }
        const hasPhone = !!(user.phone || user.phoneHash);
        if (!hasPhone) {
            console.log(`⚠️ [AuthController] Campo obrigatório ausente: Telefone (phone/phoneHash)`);
            return false;
        }
        if (!user.birthDate) {
            console.log(`⚠️ [AuthController] Campo obrigatório ausente: birthDate`);
            return false;
        }
        if (!user.motherName || user.motherName === '') {
            console.log(`⚠️ [AuthController] Campo obrigatório ausente: motherName`);
            return false;
        }
        if (!user.occupation || user.occupation === '') {
            console.log(`⚠️ [AuthController] Campo obrigatório ausente: occupation`);
            return false;
        }
        if (!user.incomeRange || user.incomeRange === '') {
            console.log(`⚠️ [AuthController] Campo obrigatório ausente: incomeRange`);
            return false;
        }
        const hasDocumentType = !!(user.kycDocuments?.documentType || user.documentType);
        if (!hasDocumentType) {
            console.log(`⚠️ [AuthController] Campo obrigatório ausente: documentType (kycDocuments.documentType/documentType)`);
            return false;
        }
        console.log(`✅ [AuthController] Todos os campos obrigatórios estão presentes`);
        return true;
    }
};
exports.AuthController = AuthController;
__decorate([
    (0, common_1.Post)('reset-password'),
    (0, throttler_1.Throttle)({ default: { limit: 5, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Enviar email de redefinição de senha (customizado)',
        description: 'Envia email customizado com template personalizado usando Firebase Admin SDK para gerar o link'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Email enviado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Email inválido' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Usuário não encontrado no Firebase' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_e = typeof reset_password_dto_1.ResetPasswordDto !== "undefined" && reset_password_dto_1.ResetPasswordDto) === "function" ? _e : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "resetPassword", null);
__decorate([
    (0, common_1.Post)('send-otp'),
    (0, throttler_1.Throttle)({ default: { limit: 3, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Enviar código OTP para telefone (alternativa ao Firebase Phone Auth)',
        description: 'Gera e retorna código OTP de 6 dígitos. Para testes, o código é retornado no response.'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'OTP gerado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Telefone inválido' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_f = typeof send_phone_otp_dto_1.SendPhoneOtpDto !== "undefined" && send_phone_otp_dto_1.SendPhoneOtpDto) === "function" ? _f : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "sendOtp", null);
__decorate([
    (0, common_1.Post)('verify-otp'),
    (0, throttler_1.Throttle)({ default: { limit: 10, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Verificar código OTP',
        description: 'Valida o código OTP enviado pelo usuário'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'OTP verificado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Código inválido ou expirado' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_g = typeof send_phone_otp_dto_1.VerifyPhoneOtpDto !== "undefined" && send_phone_otp_dto_1.VerifyPhoneOtpDto) === "function" ? _g : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "verifyOtp", null);
__decorate([
    (0, common_1.Post)('send-otp-whatsapp'),
    (0, throttler_1.Throttle)({ default: { limit: 3, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Enviar código OTP via WhatsApp',
        description: 'Gera código OTP de 4 dígitos e envia via WhatsApp para o telefone informado'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'OTP enviado via WhatsApp com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Telefone inválido ou falha no envio' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_h = typeof send_phone_otp_dto_1.SendPhoneOtpDto !== "undefined" && send_phone_otp_dto_1.SendPhoneOtpDto) === "function" ? _h : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "sendOtpWhatsApp", null);
__decorate([
    (0, common_1.Post)('verify-otp-login'),
    (0, throttler_1.Throttle)({ default: { limit: 10, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Verificar OTP e fazer login',
        description: 'Valida o código OTP, busca usuário pelo telefone e retorna status + custom token para login'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'OTP verificado e status do usuário retornado' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Código inválido, expirado ou telefone inválido' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_j = typeof send_phone_otp_dto_1.VerifyPhoneOtpDto !== "undefined" && send_phone_otp_dto_1.VerifyPhoneOtpDto) === "function" ? _j : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "verifyOtpLogin", null);
__decorate([
    (0, common_1.Post)('check-user-status'),
    (0, throttler_1.Throttle)({ default: { limit: 10, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Verificar status do usuário após autenticação Firebase',
        description: 'Verifica se o usuário existe no sistema e retorna o status (LOGGED_IN, REQUIRE_CPF_CHECK ou REGISTER)'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Status do usuário retornado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Token inválido' }),
    (0, swagger_1.ApiResponse)({ status: 401, description: 'Token não autorizado' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_k = typeof send_phone_otp_dto_1.CheckUserStatusDto !== "undefined" && send_phone_otp_dto_1.CheckUserStatusDto) === "function" ? _k : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "checkUserStatus", null);
exports.AuthController = AuthController = __decorate([
    (0, swagger_1.ApiTags)('Auth'),
    (0, common_1.Controller)('api/auth'),
    (0, common_1.UseGuards)(api_key_guard_1.ApiKeyGuard),
    (0, swagger_1.ApiSecurity)('api-key'),
    __metadata("design:paramtypes", [typeof (_a = typeof email_sender_service_1.EmailSenderService !== "undefined" && email_sender_service_1.EmailSenderService) === "function" ? _a : Object, typeof (_b = typeof simple_otp_service_1.SimpleOtpService !== "undefined" && simple_otp_service_1.SimpleOtpService) === "function" ? _b : Object, typeof (_c = typeof whatsapp_service_1.WhatsAppService !== "undefined" && whatsapp_service_1.WhatsAppService) === "function" ? _c : Object, typeof (_d = typeof users_service_1.UsersService !== "undefined" && users_service_1.UsersService) === "function" ? _d : Object])
], AuthController);


/***/ }),
/* 32 */
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
exports.ResetPasswordByCpfDto = exports.ResetPasswordDto = void 0;
const swagger_1 = __webpack_require__(3);
const class_validator_1 = __webpack_require__(14);
class ResetPasswordDto {
}
exports.ResetPasswordDto = ResetPasswordDto;
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Email do usuário',
        example: 'usuario@exemplo.com',
    }),
    (0, class_validator_1.IsEmail)({}, { message: 'Email inválido' }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Email é obrigatório' }),
    __metadata("design:type", String)
], ResetPasswordDto.prototype, "email", void 0);
class ResetPasswordByCpfDto {
}
exports.ResetPasswordByCpfDto = ResetPasswordByCpfDto;
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'CPF do usuário (apenas números)',
        example: '12345678900',
    }),
    (0, class_validator_1.IsNotEmpty)({ message: 'CPF é obrigatório' }),
    __metadata("design:type", String)
], ResetPasswordByCpfDto.prototype, "cpf", void 0);


/***/ }),
/* 33 */
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
exports.CheckUserStatusDto = exports.VerifyPhoneOtpDto = exports.SendPhoneOtpDto = void 0;
const swagger_1 = __webpack_require__(3);
const class_validator_1 = __webpack_require__(14);
class SendPhoneOtpDto {
}
exports.SendPhoneOtpDto = SendPhoneOtpDto;
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Telefone apenas dígitos (código do país + DDD + número)',
        example: '5511999999999',
    }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)({ message: 'Telefone é obrigatório' }),
    (0, class_validator_1.Matches)(/^\d{10,15}$/, { message: 'Número de telefone inválido' }),
    __metadata("design:type", String)
], SendPhoneOtpDto.prototype, "phone", void 0);
class VerifyPhoneOtpDto {
}
exports.VerifyPhoneOtpDto = VerifyPhoneOtpDto;
__decorate([
    (0, swagger_1.ApiProperty)({ example: '5511999999999' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.Matches)(/^\d{10,15}$/, { message: 'Número de telefone inválido' }),
    __metadata("design:type", String)
], VerifyPhoneOtpDto.prototype, "phone", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({ description: 'Código OTP (4 dígitos no fluxo WhatsApp)', example: '1234' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.Matches)(/^\d{4,6}$/, { message: 'Código OTP inválido' }),
    __metadata("design:type", String)
], VerifyPhoneOtpDto.prototype, "code", void 0);
class CheckUserStatusDto {
}
exports.CheckUserStatusDto = CheckUserStatusDto;
__decorate([
    (0, swagger_1.ApiProperty)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)({ message: 'Token é obrigatório' }),
    __metadata("design:type", String)
], CheckUserStatusDto.prototype, "token", void 0);


/***/ }),
/* 34 */
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
var WhatsAppWebhookController_1;
var _a, _b;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.WhatsAppWebhookController = void 0;
const common_1 = __webpack_require__(2);
const whatsapp_service_1 = __webpack_require__(29);
let WhatsAppWebhookController = WhatsAppWebhookController_1 = class WhatsAppWebhookController {
    constructor(whatsAppService) {
        this.whatsAppService = whatsAppService;
        this.logger = new common_1.Logger(WhatsAppWebhookController_1.name);
    }
    async handleIncomingMessage(body) {
        try {
            const phone = this.extractPhone(body);
            const hasMessage = body.Body != null && String(body.Body).trim().length > 0;
            if (!phone || !hasMessage) {
                this.logger.debug(`Webhook ignorado (sem telefone ou sem mensagem): ${JSON.stringify(body).substring(0, 200)}`);
                return { received: true };
            }
            if (phone.length < 12) {
                this.logger.warn(`Webhook: telefone inválido ${phone.substring(0, 4)}***`);
                return { received: true };
            }
            this.logger.log(`Mensagem recebida de ${phone.substring(0, 4)}*** - enviando resposta automática`);
            const sent = await this.whatsAppService.sendTextMessage(phone, whatsapp_service_1.WhatsAppService.AUTO_REPLY_MESSAGE);
            if (!sent) {
                this.logger.warn(`Falha ao enviar resposta automática para ${phone.substring(0, 4)}***`);
            }
            return { received: true };
        }
        catch (error) {
            this.logger.error(`Erro no webhook WhatsApp: ${error.message}`, error.stack);
            return { received: true };
        }
    }
    extractPhone(body) {
        if (body.From) {
            return String(body.From).replace('whatsapp:', '').replace(/\D/g, '');
        }
        const raw = body.from ?? body.contact_id ?? body.sender ?? body.from_number ?? body.phone;
        if (raw == null)
            return null;
        return String(raw).replace(/\D/g, '');
    }
};
exports.WhatsAppWebhookController = WhatsAppWebhookController;
__decorate([
    (0, common_1.Post)('whatsapp'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_b = typeof Record !== "undefined" && Record) === "function" ? _b : Object]),
    __metadata("design:returntype", Promise)
], WhatsAppWebhookController.prototype, "handleIncomingMessage", null);
exports.WhatsAppWebhookController = WhatsAppWebhookController = WhatsAppWebhookController_1 = __decorate([
    (0, common_1.Controller)('api/webhooks'),
    __metadata("design:paramtypes", [typeof (_a = typeof whatsapp_service_1.WhatsAppService !== "undefined" && whatsapp_service_1.WhatsAppService) === "function" ? _a : Object])
], WhatsAppWebhookController);


/***/ }),
/* 35 */
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
var HealthController_1;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.HealthController = void 0;
const common_1 = __webpack_require__(2);
const swagger_1 = __webpack_require__(3);
const admin = __webpack_require__(10);
let HealthController = HealthController_1 = class HealthController {
    constructor() {
        this.logger = new common_1.Logger(HealthController_1.name);
        this.KEEP_ALIVE_INTERVAL = 30 * 60 * 1000;
    }
    onModuleInit() {
        this.warmUpFirestore();
        setInterval(() => this.warmUpFirestore(), this.KEEP_ALIVE_INTERVAL);
    }
    async warmUpFirestore() {
        try {
            const start = Date.now();
            await admin.firestore().collection('_health').doc('ping').set({ timestamp: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
            this.logger.log(`🔥 Firestore keep-alive OK (${Date.now() - start}ms)`);
        }
        catch (error) {
            this.logger.warn(`⚠️ Firestore keep-alive falhou: ${error.message}`);
        }
    }
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
exports.HealthController = HealthController = HealthController_1 = __decorate([
    (0, swagger_1.ApiTags)('Health'),
    (0, common_1.Controller)('health')
], HealthController);


/***/ }),
/* 36 */
/***/ ((module) => {

module.exports = require("os");

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
const admin = __webpack_require__(10);
const fs = __webpack_require__(22);
const os = __webpack_require__(36);
const path = __webpack_require__(23);
if (!admin.apps.length) {
    try {
        const projectId = process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT || 'pagpagapp';
        const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
        const googleCredentialsJson = process.env.GOOGLE_CREDENTIALS_JSON;
        const isCloudRun = !!process.env.K_SERVICE;
        console.log('🔧 Inicializando Firebase Admin...');
        console.log(`📋 Project ID: ${projectId}`);
        if (serviceAccountJson) {
            console.log('📋 Modo: SERVICE_ACCOUNT');
            admin.initializeApp({
                credential: admin.credential.cert(JSON.parse(serviceAccountJson)),
                projectId,
            });
        }
        else if (googleCredentialsJson) {
            console.log('📋 Modo: GOOGLE_CREDENTIALS_JSON (Railway/externo)');
            const credPath = path.join(os.tmpdir(), 'gcloud-credentials.json');
            fs.writeFileSync(credPath, googleCredentialsJson, { mode: 0o600 });
            process.env.GOOGLE_APPLICATION_CREDENTIALS = credPath;
            admin.initializeApp({ projectId });
            admin.firestore().settings({ preferRest: true });
        }
        else if (isCloudRun) {
            console.log('📋 Modo: ADC (Cloud Run)');
            admin.initializeApp({ projectId });
        }
        else {
            console.log('📋 Modo: ADC (desenvolvimento local)');
            admin.initializeApp({ projectId });
        }
        admin.firestore();
        console.log('✅ Firebase Admin inicializado com sucesso');
    }
    catch (error) {
        console.error('❌ Erro ao inicializar Firebase Admin:', error.message);
        try {
            admin.initializeApp();
            console.log('✅ Firebase Admin inicializado com credenciais padrão (fallback)');
        }
        catch (fallbackError) {
            console.error('❌ Falha total ao inicializar Firebase Admin:', fallbackError.message);
            console.error('💡 Opções de autenticação:');
            console.error('   1. FIREBASE_SERVICE_ACCOUNT=<json> (Service Account Key)');
            console.error('   2. GOOGLE_CREDENTIALS_JSON=<json> (ADC JSON para Railway)');
            console.error('   3. gcloud auth application-default login (dev local)');
            throw fallbackError;
        }
    }
}
async function bootstrap() {
    try {
        console.log('🚀 Iniciando aplicação NestJS...');
        console.log(`📋 Ambiente: ${process.env.NODE_ENV || 'development'}`);
        console.log(`🔌 Porta: ${process.env.PORT || 8080}`);
        const app = await core_1.NestFactory.create(app_module_1.AppModule);
        app.use((0, helmet_1.default)());
        app.enableCors({
            origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
            credentials: true,
        });
        app.useGlobalFilters({
            catch(exception, host) {
                const ctx = host.switchToHttp();
                const response = ctx.getResponse();
                const request = ctx.getRequest();
                console.error('❌ ERRO CAPTURADO:', {
                    path: request.url,
                    method: request.method,
                    error: exception.message,
                    stack: exception.stack,
                    status: exception.status || 500,
                });
                const status = exception.status || 500;
                response.status(status).json({
                    statusCode: status,
                    message: exception.message || 'Internal server error',
                    ...(process.env.NODE_ENV === 'development' && { stack: exception.stack }),
                });
            },
        });
        app.useGlobalPipes(new common_1.ValidationPipe({
            whitelist: true,
            forbidNonWhitelisted: true,
            transform: true,
        }));
        const config = new swagger_1.DocumentBuilder()
            .setTitle('Neves Capital API')
            .setDescription('API Backend for Neves Capital - Firebase')
            .setVersion('1.0')
            .addApiKey({ type: 'apiKey', name: 'x-api-key', in: 'header' }, 'api-key')
            .build();
        const document = swagger_1.SwaggerModule.createDocument(app, config);
        swagger_1.SwaggerModule.setup('api/docs', app, document);
        const port = process.env.PORT || 8080;
        await app.listen(port, '0.0.0.0');
        console.log(`✅ API rodando na porta ${port}`);
        console.log(`📚 Documentação: http://localhost:${port}/api/docs`);
        console.log(`💚 Health check: http://localhost:${port}/health`);
    }
    catch (error) {
        console.error('❌ Erro ao iniciar aplicação:', error);
        process.exit(1);
    }
}
bootstrap();

})();

/******/ })()
;