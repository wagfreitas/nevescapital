/******/ (() => { // webpackBootstrap
/******/ 	"use strict";
/******/ 	var __webpack_modules__ = ({

/***/ "./src/app.module.ts":
/*!***************************!*\
  !*** ./src/app.module.ts ***!
  \***************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.AppModule = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
const throttler_1 = __webpack_require__(/*! @nestjs/throttler */ "@nestjs/throttler");
const users_module_1 = __webpack_require__(/*! ./users/users.module */ "./src/users/users.module.ts");
const auth_module_1 = __webpack_require__(/*! ./auth/auth.module */ "./src/auth/auth.module.ts");
const database_module_1 = __webpack_require__(/*! ./database/database.module */ "./src/database/database.module.ts");
const health_controller_1 = __webpack_require__(/*! ./health.controller */ "./src/health.controller.ts");
const migration_controller_1 = __webpack_require__(/*! ./migration.controller */ "./src/migration.controller.ts");
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

/***/ "./src/auth/auth.controller.ts":
/*!*************************************!*\
  !*** ./src/auth/auth.controller.ts ***!
  \*************************************/
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
var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l, _m, _o, _p;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.AuthController = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const swagger_1 = __webpack_require__(/*! @nestjs/swagger */ "@nestjs/swagger");
const throttler_1 = __webpack_require__(/*! @nestjs/throttler */ "@nestjs/throttler");
const api_key_guard_1 = __webpack_require__(/*! ../common/guards/api-key.guard */ "./src/common/guards/api-key.guard.ts");
const admin = __webpack_require__(/*! firebase-admin */ "firebase-admin");
const email_sender_service_1 = __webpack_require__(/*! ./email-sender.service */ "./src/auth/email-sender.service.ts");
const reset_password_dto_1 = __webpack_require__(/*! ./dto/reset-password.dto */ "./src/auth/dto/reset-password.dto.ts");
const otp_dto_1 = __webpack_require__(/*! ./dto/otp.dto */ "./src/auth/dto/otp.dto.ts");
const registration_otp_dto_1 = __webpack_require__(/*! ./dto/registration-otp.dto */ "./src/auth/dto/registration-otp.dto.ts");
const users_service_1 = __webpack_require__(/*! ../users/users.service */ "./src/users/users.service.ts");
const otp_service_1 = __webpack_require__(/*! ./services/otp.service */ "./src/auth/services/otp.service.ts");
const sms_service_1 = __webpack_require__(/*! ./services/sms.service */ "./src/auth/services/sms.service.ts");
const ycloud_service_1 = __webpack_require__(/*! ./services/ycloud.service */ "./src/auth/services/ycloud.service.ts");
const encryption_service_1 = __webpack_require__(/*! ../common/services/encryption.service */ "./src/common/services/encryption.service.ts");
let AuthController = class AuthController {
    constructor(emailSenderService, usersService, otpService, smsService, ycloudService, encryptionService) {
        this.emailSenderService = emailSenderService;
        this.usersService = usersService;
        this.otpService = otpService;
        this.smsService = smsService;
        this.ycloudService = ycloudService;
        this.encryptionService = encryptionService;
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
    async resetPasswordByCpf(resetPasswordByCpfDto) {
        try {
            const userData = await this.usersService.findByCpf(resetPasswordByCpfDto.cpf);
            if (!userData || !userData.email) {
                throw new Error('CPF não encontrado');
            }
            await this.emailSenderService.sendPasswordResetEmail(userData.email);
            return {
                success: true,
                message: 'Email de redefinição de senha enviado com sucesso',
            };
        }
        catch (error) {
            throw error;
        }
    }
    async requestPasswordResetOtp(dto) {
        try {
            const userData = await this.usersService.findByCpf(dto.cpf);
            if (!userData || !userData.id) {
                throw new common_1.NotFoundException('CPF não encontrado');
            }
            if (!userData.phone) {
                throw new common_1.BadRequestException('Telefone não cadastrado. Use a opção de recuperação por email.');
            }
            const { otpCode, expiresAt } = await this.otpService.createOtp(userData.id, userData.phone);
            if (!this.smsService.isConfigured()) {
                throw new common_1.BadRequestException('Serviço de SMS não configurado. Contate o suporte.');
            }
            const sendResult = await this.smsService.sendOtp(userData.phone, otpCode);
            if (!sendResult.success) {
                throw new common_1.BadRequestException(`Erro ao enviar código: ${sendResult.error}`);
            }
            return {
                success: true,
                message: `Código enviado com sucesso via ${sendResult.method === 'whatsapp' ? 'WhatsApp' : 'SMS'}`,
                expires_at: expiresAt.toISOString(),
            };
        }
        catch (error) {
            throw error;
        }
    }
    async verifyPasswordResetOtp(dto) {
        try {
            const userData = await this.usersService.findByCpf(dto.cpf);
            if (!userData || !userData.id) {
                throw new common_1.NotFoundException('CPF não encontrado');
            }
            const token = await this.otpService.verifyOtp(userData.id, dto.otp_code);
            return {
                success: true,
                message: 'Código OTP verificado com sucesso',
                token,
                expires_in: 900,
            };
        }
        catch (error) {
            throw error;
        }
    }
    async changePasswordWithOtp(dto) {
        try {
            const tokenValidation = await this.otpService.validateTempToken(dto.token);
            if (!tokenValidation.valid) {
                throw new common_1.UnauthorizedException('Token inválido ou expirado');
            }
            const userId = tokenValidation.userId;
            const userData = await this.usersService.findById(userId);
            if (!userData) {
                throw new common_1.NotFoundException('Usuário não encontrado');
            }
            const isOldPasswordValid = await this.usersService.verifyPasswordInternal(userId, dto.old_password);
            if (!isOldPasswordValid) {
                throw new common_1.UnauthorizedException('Senha atual incorreta');
            }
            await this.usersService.updatePassword(userId, dto.new_password);
            await this.otpService.invalidateToken(dto.token);
            return {
                success: true,
                message: 'Senha alterada com sucesso',
            };
        }
        catch (error) {
            throw error;
        }
    }
    async checkCpf(dto) {
        try {
            const userData = await this.usersService.findByCpf(dto.cpf);
            return {
                success: true,
                exists: !!userData,
                message: userData ? 'CPF já cadastrado' : 'CPF não cadastrado',
            };
        }
        catch (error) {
            if (error.status === 404) {
                return {
                    success: true,
                    exists: false,
                    message: 'CPF não cadastrado',
                };
            }
            throw error;
        }
    }
    async requestRegistrationOtp(dto) {
        try {
            try {
                const userData = await this.usersService.findByCpf(dto.cpf);
                if (userData) {
                    throw new common_1.BadRequestException('CPF já cadastrado. Use a opção de login.');
                }
            }
            catch (error) {
                if (error.status !== 404) {
                    throw error;
                }
            }
            const { expiresAt } = await this.otpService.createRegistrationOtp(dto.cpf, dto.phone);
            return {
                success: true,
                message: 'Código enviado com sucesso via WhatsApp',
                expires_at: expiresAt.toISOString(),
            };
        }
        catch (error) {
            throw error;
        }
    }
    async verifyRegistrationOtp(dto) {
        try {
            await this.otpService.verifyRegistrationOtp(dto.cpf, dto.phone, dto.otp_code);
            return {
                success: true,
                message: 'Código OTP verificado com sucesso',
            };
        }
        catch (error) {
            throw error;
        }
    }
    async checkUserStatus(body) {
        try {
            const decodedToken = await admin.auth().verifyIdToken(body.token);
            const phone = decodedToken.phone_number;
            if (!phone) {
                throw new common_1.BadRequestException('Token não contém número de telefone');
            }
            const user = await this.usersService.findByPhone(phone);
            if (user) {
                return {
                    success: true,
                    status: 'REQUIRE_CPF_CHECK',
                    message: 'Usuário encontrado. Confirme seu CPF.',
                    phone: phone,
                };
            }
            else {
                return {
                    success: true,
                    status: 'REGISTER',
                    message: 'Usuário não encontrado. Redirecionando para cadastro.',
                    phone: phone,
                };
            }
        }
        catch (error) {
            throw error;
        }
    }
    async loginComplete(body) {
        try {
            const decodedToken = await admin.auth().verifyIdToken(body.token);
            const phone = decodedToken.phone_number;
            if (!phone) {
                throw new common_1.BadRequestException('Token não contém número de telefone');
            }
            const user = await this.usersService.findByPhone(phone);
            if (!user) {
                throw new common_1.NotFoundException('Usuário não encontrado');
            }
            const userCpf = user.cpf.replace(/\D/g, '');
            const inputPrefix = body.cpfPrefix.replace(/\D/g, '');
            if (!userCpf.startsWith(inputPrefix)) {
                throw new common_1.UnauthorizedException('CPF incorreto');
            }
            const customToken = await admin.auth().createCustomToken(user.id);
            return {
                success: true,
                token: customToken,
                user: {
                    name: user.full_name,
                    email: user.email,
                }
            };
        }
        catch (error) {
            throw error;
        }
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
    __metadata("design:paramtypes", [typeof (_g = typeof reset_password_dto_1.ResetPasswordDto !== "undefined" && reset_password_dto_1.ResetPasswordDto) === "function" ? _g : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "resetPassword", null);
__decorate([
    (0, common_1.Post)('reset-password/cpf'),
    (0, throttler_1.Throttle)({ default: { limit: 5, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Enviar email de redefinição de senha por CPF (customizado)',
        description: 'Busca email por CPF no PostgreSQL e envia email customizado de reset'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Email enviado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'CPF não encontrado' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_h = typeof reset_password_dto_1.ResetPasswordByCpfDto !== "undefined" && reset_password_dto_1.ResetPasswordByCpfDto) === "function" ? _h : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "resetPasswordByCpf", null);
__decorate([
    (0, common_1.Post)('request-password-reset-otp'),
    (0, throttler_1.Throttle)({ default: { limit: 3, ttl: 120000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Solicitar código OTP para recuperação de senha via SMS/WhatsApp',
        description: 'Gera código OTP e envia para o telefone cadastrado do usuário'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Código OTP enviado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'CPF não encontrado' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Telefone não cadastrado ou erro na requisição' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_j = typeof otp_dto_1.RequestPasswordResetOtpDto !== "undefined" && otp_dto_1.RequestPasswordResetOtpDto) === "function" ? _j : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "requestPasswordResetOtp", null);
__decorate([
    (0, common_1.Post)('verify-password-reset-otp'),
    (0, throttler_1.Throttle)({ default: { limit: 5, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Verificar código OTP e obter token temporário',
        description: 'Valida código OTP e retorna token temporário para mudança de senha'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Código OTP verificado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 401, description: 'Código OTP inválido ou expirado' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'CPF não encontrado' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_k = typeof otp_dto_1.VerifyPasswordResetOtpDto !== "undefined" && otp_dto_1.VerifyPasswordResetOtpDto) === "function" ? _k : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "verifyPasswordResetOtp", null);
__decorate([
    (0, common_1.Post)('change-password-with-otp'),
    (0, throttler_1.Throttle)({ default: { limit: 5, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Alterar senha usando token OTP',
        description: 'Altera senha do usuário após verificação do OTP. Requer senha antiga e nova senha.'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Senha alterada com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 401, description: 'Token inválido ou senha antiga incorreta' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_l = typeof otp_dto_1.ChangePasswordWithOtpDto !== "undefined" && otp_dto_1.ChangePasswordWithOtpDto) === "function" ? _l : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "changePasswordWithOtp", null);
__decorate([
    (0, common_1.Post)('check-cpf'),
    (0, throttler_1.Throttle)({ default: { limit: 10, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Verificar se CPF já está cadastrado',
        description: 'Verifica se um CPF já existe no sistema. Retorna true se existe, false se não existe.'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'CPF verificado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'CPF inválido' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_m = typeof registration_otp_dto_1.CheckCpfDto !== "undefined" && registration_otp_dto_1.CheckCpfDto) === "function" ? _m : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "checkCpf", null);
__decorate([
    (0, common_1.Post)('request-registration-otp'),
    (0, throttler_1.Throttle)({ default: { limit: 3, ttl: 120000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Solicitar código OTP para cadastro via WhatsApp',
        description: 'Gera código OTP e envia via WhatsApp usando Ycloud para usuários em processo de cadastro'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Código OTP enviado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'CPF já cadastrado ou erro na requisição' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_o = typeof registration_otp_dto_1.RequestRegistrationOtpDto !== "undefined" && registration_otp_dto_1.RequestRegistrationOtpDto) === "function" ? _o : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "requestRegistrationOtp", null);
__decorate([
    (0, common_1.Post)('verify-registration-otp'),
    (0, throttler_1.Throttle)({ default: { limit: 5, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Verificar código OTP de cadastro',
        description: 'Valida código OTP enviado via WhatsApp durante o processo de cadastro'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Código OTP verificado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 401, description: 'Código OTP inválido ou expirado' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_p = typeof registration_otp_dto_1.VerifyRegistrationOtpDto !== "undefined" && registration_otp_dto_1.VerifyRegistrationOtpDto) === "function" ? _p : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "verifyRegistrationOtp", null);
__decorate([
    (0, common_1.Post)('check-user-status'),
    (0, throttler_1.Throttle)({ default: { limit: 10, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Verificar status do usuário após login Firebase',
        description: 'Recebe token do Firebase, verifica se usuário existe e retorna próximo passo.'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Status retornado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 401, description: 'Token inválido' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "checkUserStatus", null);
__decorate([
    (0, common_1.Post)('login-complete'),
    (0, throttler_1.Throttle)({ default: { limit: 5, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Completar login (Verificar CPF)',
        description: 'Verifica os primeiros 5 dígitos do CPF e gera o token de acesso customizado (se necessário) ou apenas confirma.'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Login realizado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 401, description: 'CPF incorreto ou token inválido' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "loginComplete", null);
exports.AuthController = AuthController = __decorate([
    (0, swagger_1.ApiTags)('Auth'),
    (0, common_1.Controller)('api/auth'),
    (0, common_1.UseGuards)(api_key_guard_1.ApiKeyGuard),
    (0, swagger_1.ApiSecurity)('api-key'),
    __metadata("design:paramtypes", [typeof (_a = typeof email_sender_service_1.EmailSenderService !== "undefined" && email_sender_service_1.EmailSenderService) === "function" ? _a : Object, typeof (_b = typeof users_service_1.UsersService !== "undefined" && users_service_1.UsersService) === "function" ? _b : Object, typeof (_c = typeof otp_service_1.OtpService !== "undefined" && otp_service_1.OtpService) === "function" ? _c : Object, typeof (_d = typeof sms_service_1.SmsService !== "undefined" && sms_service_1.SmsService) === "function" ? _d : Object, typeof (_e = typeof ycloud_service_1.YcloudService !== "undefined" && ycloud_service_1.YcloudService) === "function" ? _e : Object, typeof (_f = typeof encryption_service_1.EncryptionService !== "undefined" && encryption_service_1.EncryptionService) === "function" ? _f : Object])
], AuthController);


/***/ }),

/***/ "./src/auth/auth.module.ts":
/*!*********************************!*\
  !*** ./src/auth/auth.module.ts ***!
  \*********************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.AuthModule = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
const email_template_service_1 = __webpack_require__(/*! ./email-template.service */ "./src/auth/email-template.service.ts");
const email_sender_service_1 = __webpack_require__(/*! ./email-sender.service */ "./src/auth/email-sender.service.ts");
const otp_service_1 = __webpack_require__(/*! ./services/otp.service */ "./src/auth/services/otp.service.ts");
const sms_service_1 = __webpack_require__(/*! ./services/sms.service */ "./src/auth/services/sms.service.ts");
const ycloud_service_1 = __webpack_require__(/*! ./services/ycloud.service */ "./src/auth/services/ycloud.service.ts");
const auth_controller_1 = __webpack_require__(/*! ./auth.controller */ "./src/auth/auth.controller.ts");
const users_module_1 = __webpack_require__(/*! ../users/users.module */ "./src/users/users.module.ts");
const database_module_1 = __webpack_require__(/*! ../database/database.module */ "./src/database/database.module.ts");
const encryption_service_1 = __webpack_require__(/*! ../common/services/encryption.service */ "./src/common/services/encryption.service.ts");
let AuthModule = class AuthModule {
};
exports.AuthModule = AuthModule;
exports.AuthModule = AuthModule = __decorate([
    (0, common_1.Module)({
        imports: [config_1.ConfigModule, users_module_1.UsersModule, database_module_1.DatabaseModule],
        controllers: [auth_controller_1.AuthController],
        providers: [
            email_template_service_1.EmailTemplateService,
            email_sender_service_1.EmailSenderService,
            otp_service_1.OtpService,
            sms_service_1.SmsService,
            ycloud_service_1.YcloudService,
            encryption_service_1.EncryptionService,
        ],
        exports: [email_template_service_1.EmailTemplateService, email_sender_service_1.EmailSenderService, otp_service_1.OtpService, sms_service_1.SmsService, ycloud_service_1.YcloudService],
    })
], AuthModule);


/***/ }),

/***/ "./src/auth/dto/otp.dto.ts":
/*!*********************************!*\
  !*** ./src/auth/dto/otp.dto.ts ***!
  \*********************************/
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
exports.ChangePasswordWithOtpDto = exports.VerifyPasswordResetOtpDto = exports.RequestPasswordResetOtpDto = void 0;
const swagger_1 = __webpack_require__(/*! @nestjs/swagger */ "@nestjs/swagger");
const class_validator_1 = __webpack_require__(/*! class-validator */ "class-validator");
class RequestPasswordResetOtpDto {
}
exports.RequestPasswordResetOtpDto = RequestPasswordResetOtpDto;
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'CPF do usuário (apenas números)',
        example: '12345678900',
    }),
    (0, class_validator_1.IsNotEmpty)({ message: 'CPF é obrigatório' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.Matches)(/^\d{11}$/, { message: 'CPF deve ter 11 dígitos' }),
    __metadata("design:type", String)
], RequestPasswordResetOtpDto.prototype, "cpf", void 0);
class VerifyPasswordResetOtpDto {
}
exports.VerifyPasswordResetOtpDto = VerifyPasswordResetOtpDto;
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'CPF do usuário (apenas números)',
        example: '12345678900',
    }),
    (0, class_validator_1.IsNotEmpty)({ message: 'CPF é obrigatório' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.Matches)(/^\d{11}$/, { message: 'CPF deve ter 11 dígitos' }),
    __metadata("design:type", String)
], VerifyPasswordResetOtpDto.prototype, "cpf", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Código OTP de 6 dígitos',
        example: '123456',
    }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Código OTP é obrigatório' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.Matches)(/^\d{6}$/, { message: 'Código OTP deve ter 6 dígitos' }),
    __metadata("design:type", String)
], VerifyPasswordResetOtpDto.prototype, "otp_code", void 0);
class ChangePasswordWithOtpDto {
}
exports.ChangePasswordWithOtpDto = ChangePasswordWithOtpDto;
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Token temporário recebido após validar OTP',
        example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
    }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Token é obrigatório' }),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], ChangePasswordWithOtpDto.prototype, "token", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Senha atual do usuário',
        example: 'SenhaAtual123!',
    }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Senha atual é obrigatória' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(6, { message: 'Senha deve ter pelo menos 6 caracteres' }),
    __metadata("design:type", String)
], ChangePasswordWithOtpDto.prototype, "old_password", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Nova senha do usuário',
        example: 'NovaSenha123!',
    }),
    (0, class_validator_1.IsNotEmpty)({ message: 'Nova senha é obrigatória' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MinLength)(6, { message: 'Senha deve ter pelo menos 6 caracteres' }),
    __metadata("design:type", String)
], ChangePasswordWithOtpDto.prototype, "new_password", void 0);


/***/ }),

/***/ "./src/auth/dto/registration-otp.dto.ts":
/*!**********************************************!*\
  !*** ./src/auth/dto/registration-otp.dto.ts ***!
  \**********************************************/
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
exports.VerifyRegistrationOtpDto = exports.RequestRegistrationOtpDto = exports.CheckCpfDto = void 0;
const swagger_1 = __webpack_require__(/*! @nestjs/swagger */ "@nestjs/swagger");
const class_validator_1 = __webpack_require__(/*! class-validator */ "class-validator");
class CheckCpfDto {
}
exports.CheckCpfDto = CheckCpfDto;
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'CPF do usuário (apenas números)',
        example: '12345678901',
    }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.Matches)(/^\d{11}$/, { message: 'CPF deve conter exatamente 11 dígitos' }),
    __metadata("design:type", String)
], CheckCpfDto.prototype, "cpf", void 0);
class RequestRegistrationOtpDto {
}
exports.RequestRegistrationOtpDto = RequestRegistrationOtpDto;
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'CPF do usuário (apenas números)',
        example: '12345678901',
    }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.Matches)(/^\d{11}$/, { message: 'CPF deve conter exatamente 11 dígitos' }),
    __metadata("design:type", String)
], RequestRegistrationOtpDto.prototype, "cpf", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Número de telefone celular',
        example: '11999999999',
    }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.Matches)(/^\d{10,11}$/, { message: 'Telefone deve conter 10 ou 11 dígitos' }),
    __metadata("design:type", String)
], RequestRegistrationOtpDto.prototype, "phone", void 0);
class VerifyRegistrationOtpDto {
}
exports.VerifyRegistrationOtpDto = VerifyRegistrationOtpDto;
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'CPF do usuário (apenas números)',
        example: '12345678901',
    }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.Matches)(/^\d{11}$/, { message: 'CPF deve conter exatamente 11 dígitos' }),
    __metadata("design:type", String)
], VerifyRegistrationOtpDto.prototype, "cpf", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Número de telefone celular',
        example: '11999999999',
    }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.Matches)(/^\d{10,11}$/, { message: 'Telefone deve conter 10 ou 11 dígitos' }),
    __metadata("design:type", String)
], VerifyRegistrationOtpDto.prototype, "phone", void 0);
__decorate([
    (0, swagger_1.ApiProperty)({
        description: 'Código OTP de 6 dígitos',
        example: '123456',
    }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    (0, class_validator_1.Length)(6, 6, { message: 'Código OTP deve conter exatamente 6 dígitos' }),
    (0, class_validator_1.Matches)(/^\d{6}$/, { message: 'Código OTP deve conter apenas números' }),
    __metadata("design:type", String)
], VerifyRegistrationOtpDto.prototype, "otp_code", void 0);


/***/ }),

/***/ "./src/auth/dto/reset-password.dto.ts":
/*!********************************************!*\
  !*** ./src/auth/dto/reset-password.dto.ts ***!
  \********************************************/
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
const swagger_1 = __webpack_require__(/*! @nestjs/swagger */ "@nestjs/swagger");
const class_validator_1 = __webpack_require__(/*! class-validator */ "class-validator");
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

/***/ "./src/auth/email-sender.service.ts":
/*!******************************************!*\
  !*** ./src/auth/email-sender.service.ts ***!
  \******************************************/
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
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
const email_template_service_1 = __webpack_require__(/*! ./email-template.service */ "./src/auth/email-template.service.ts");
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
            const sendgrid = __webpack_require__(/*! @sendgrid/mail */ "@sendgrid/mail");
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
            const { SESClient, SendEmailCommand } = __webpack_require__(/*! @aws-sdk/client-ses */ "@aws-sdk/client-ses");
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
            const { Resend } = __webpack_require__(/*! resend */ "resend");
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

/***/ "./src/auth/email-template.service.ts":
/*!********************************************!*\
  !*** ./src/auth/email-template.service.ts ***!
  \********************************************/
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
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
const admin = __webpack_require__(/*! firebase-admin */ "firebase-admin");
const fs = __webpack_require__(/*! fs */ "fs");
const path = __webpack_require__(/*! path */ "path");
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

/***/ "./src/auth/services/otp.service.ts":
/*!******************************************!*\
  !*** ./src/auth/services/otp.service.ts ***!
  \******************************************/
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
exports.OtpService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const admin = __webpack_require__(/*! firebase-admin */ "firebase-admin");
const crypto = __webpack_require__(/*! crypto */ "crypto");
const ycloud_service_1 = __webpack_require__(/*! ./ycloud.service */ "./src/auth/services/ycloud.service.ts");
let OtpService = class OtpService {
    constructor(ycloudService) {
        this.ycloudService = ycloudService;
        this.OTP_EXPIRY_MINUTES = 5;
        this.MAX_ATTEMPTS = 3;
        this.OTP_LENGTH = 6;
    }
    generateOtpCode() {
        const min = 100000;
        const max = 999999;
        return Math.floor(Math.random() * (max - min + 1) + min).toString();
    }
    hashOtpCode(code) {
        return crypto.createHash('sha256').update(code).digest('hex');
    }
    async createLoginOtp(phone) {
        const verification = await this.ycloudService.startVerification(phone, 'whatsapp');
        if (!verification.success) {
            throw new common_1.BadRequestException(verification.error || 'Erro ao enviar OTP via WhatsApp');
        }
        const expiresAt = new Date(Date.now() + 5 * 60 * 1000);
        const docRef = await admin.firestore().collection('otps').add({
            phone,
            verificationId: verification.verificationId,
            expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
            attempts: 0,
            verified: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            type: 'LOGIN_PHONE',
            provider: 'YCLOUD'
        });
        console.log(`✅ OTP de Login iniciado via YCloud para telefone ${phone}, Doc ID: ${docRef.id}`);
        return { tempId: docRef.id, expiresAt };
    }
    async verifyLoginOtp(tempId, otpCode) {
        const docRef = admin.firestore().collection('otps').doc(tempId);
        const doc = await docRef.get();
        if (!doc.exists) {
            throw new common_1.NotFoundException('Sessão de login não encontrada');
        }
        const data = doc.data();
        if (!data) {
            throw new common_1.NotFoundException('Dados da sessão inválidos');
        }
        const expiresAt = data.expiresAt.toDate();
        if (new Date() > expiresAt) {
            throw new common_1.UnauthorizedException('Sessão expirada');
        }
        if (data.verified) {
            return { phone: data.phone };
        }
        if (data.attempts >= this.MAX_ATTEMPTS) {
            await docRef.update({ verified: true });
            throw new common_1.UnauthorizedException('Máximo de tentativas excedido');
        }
        const checkResult = await this.ycloudService.checkVerification(data.phone, otpCode, data.verificationId);
        if (!checkResult.success || !checkResult.valid) {
            await docRef.update({ attempts: admin.firestore.FieldValue.increment(1) });
            throw new common_1.UnauthorizedException('Código inválido');
        }
        await docRef.update({ verified: true, verifiedAt: admin.firestore.FieldValue.serverTimestamp() });
        console.log(`✅ Login verificado com sucesso para telefone ${data.phone}`);
        return { phone: data.phone };
    }
    async createOtp(userId, phone) {
        const otpCode = this.generateOtpCode();
        const otpHash = this.hashOtpCode(otpCode);
        const expiresAt = new Date();
        expiresAt.setMinutes(expiresAt.getMinutes() + this.OTP_EXPIRY_MINUTES);
        await admin.firestore().collection('otps').add({
            type: 'PASSWORD_RESET',
            userId,
            phone,
            otpHash,
            expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
            attempts: 0,
            verified: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        return { otpCode, expiresAt };
    }
    async verifyOtp(userId, otpCode) {
        const snapshot = await admin.firestore().collection('otps')
            .where('userId', '==', userId)
            .where('type', '==', 'PASSWORD_RESET')
            .where('verified', '==', false)
            .orderBy('createdAt', 'desc')
            .limit(1)
            .get();
        if (snapshot.empty) {
            throw new common_1.NotFoundException('Nenhum código ativo encontrado');
        }
        const doc = snapshot.docs[0];
        const data = doc.data();
        if (new Date() > data.expiresAt.toDate()) {
            throw new common_1.UnauthorizedException('Código expirado');
        }
        if (data.attempts >= this.MAX_ATTEMPTS) {
            await doc.ref.update({ verified: true });
            throw new common_1.UnauthorizedException('Máximo de tentativas excedido');
        }
        const otpHash = this.hashOtpCode(otpCode);
        if (otpHash !== data.otpHash) {
            await doc.ref.update({ attempts: admin.firestore.FieldValue.increment(1) });
            throw new common_1.UnauthorizedException('Código inválido');
        }
        await doc.ref.update({ verified: true, verifiedAt: admin.firestore.FieldValue.serverTimestamp() });
        return crypto.randomBytes(32).toString('hex');
    }
    async validateTempToken(token) {
        return { userId: '', valid: false };
    }
    async invalidateToken(token) { }
    async createRegistrationOtp(cpf, phone) {
        const verification = await this.ycloudService.startVerification(phone, 'whatsapp');
        if (!verification.success) {
            throw new common_1.BadRequestException(verification.error || 'Erro ao enviar OTP via WhatsApp');
        }
        const expiresAt = new Date();
        expiresAt.setMinutes(expiresAt.getMinutes() + this.OTP_EXPIRY_MINUTES);
        await admin.firestore().collection('otps').add({
            type: 'REGISTRATION',
            cpf,
            phone,
            verificationId: verification.verificationId,
            expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
            attempts: 0,
            verified: false,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            provider: 'YCLOUD'
        });
        return { expiresAt };
    }
    async verifyRegistrationOtp(cpf, phone, otpCode) {
        const snapshot = await admin.firestore().collection('otps')
            .where('cpf', '==', cpf)
            .where('type', '==', 'REGISTRATION')
            .where('verified', '==', false)
            .orderBy('createdAt', 'desc')
            .limit(1)
            .get();
        if (snapshot.empty) {
            throw new common_1.NotFoundException('Código não encontrado');
        }
        const doc = snapshot.docs[0];
        const data = doc.data();
        if (new Date() > data.expiresAt.toDate()) {
            throw new common_1.UnauthorizedException('Código expirado');
        }
        const checkResult = await this.ycloudService.checkVerification(phone, otpCode, data.verificationId);
        if (!checkResult.success || !checkResult.valid) {
            await doc.ref.update({ attempts: admin.firestore.FieldValue.increment(1) });
            throw new common_1.UnauthorizedException('Código inválido');
        }
        await doc.ref.update({ verified: true });
        return true;
    }
};
exports.OtpService = OtpService;
exports.OtpService = OtpService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof ycloud_service_1.YcloudService !== "undefined" && ycloud_service_1.YcloudService) === "function" ? _a : Object])
], OtpService);


/***/ }),

/***/ "./src/auth/services/sms.service.ts":
/*!******************************************!*\
  !*** ./src/auth/services/sms.service.ts ***!
  \******************************************/
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
exports.SmsService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
const twilio = __webpack_require__(/*! twilio */ "twilio");
let SmsService = class SmsService {
    constructor(configService) {
        this.configService = configService;
        this.twilioClient = null;
        const accountSid = this.configService.get('TWILIO_ACCOUNT_SID');
        const authToken = this.configService.get('TWILIO_AUTH_TOKEN');
        this.fromPhoneNumber = this.configService.get('TWILIO_PHONE_NUMBER', '');
        this.whatsappEnabled = this.configService.get('TWILIO_WHATSAPP_ENABLED', true);
        if (accountSid && authToken) {
            this.twilioClient = twilio(accountSid, authToken);
            console.log('✅ Twilio inicializado com sucesso');
        }
        else {
            console.warn('⚠️ Twilio não configurado. Variáveis TWILIO_ACCOUNT_SID e TWILIO_AUTH_TOKEN necessárias.');
        }
    }
    formatPhoneNumber(phone) {
        let cleaned = phone.replace(/\D/g, '');
        if (!cleaned.startsWith('55')) {
            cleaned = '55' + cleaned;
        }
        return '+' + cleaned;
    }
    async sendOtp(phone, otpCode) {
        if (!this.twilioClient) {
            return {
                success: false,
                method: null,
                error: 'Twilio não configurado',
            };
        }
        const formattedPhone = this.formatPhoneNumber(phone);
        const message = `Seu código de recuperação de senha é: ${otpCode}\n\nEste código expira em 10 minutos.\n\nNão compartilhe este código com ninguém.`;
        try {
            if (this.whatsappEnabled && this.fromPhoneNumber.startsWith('whatsapp:')) {
                try {
                    await this.twilioClient.messages.create({
                        body: message,
                        from: this.fromPhoneNumber,
                        to: `whatsapp:${formattedPhone}`,
                    });
                    console.log(`✅ OTP enviado via WhatsApp para ${formattedPhone}`);
                    return { success: true, method: 'whatsapp' };
                }
                catch (whatsappError) {
                    console.warn(`⚠️ Falha ao enviar via WhatsApp, tentando SMS: ${whatsappError.message}`);
                }
            }
            const smsFromNumber = this.fromPhoneNumber.replace('whatsapp:', '');
            await this.twilioClient.messages.create({
                body: message,
                from: smsFromNumber,
                to: formattedPhone,
            });
            console.log(`✅ OTP enviado via SMS para ${formattedPhone}`);
            return { success: true, method: 'sms' };
        }
        catch (error) {
            console.error(`❌ Erro ao enviar OTP para ${formattedPhone}:`, error.message);
            return {
                success: false,
                method: null,
                error: error.message || 'Erro ao enviar mensagem',
            };
        }
    }
    isConfigured() {
        return this.twilioClient !== null;
    }
};
exports.SmsService = SmsService;
exports.SmsService = SmsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof config_1.ConfigService !== "undefined" && config_1.ConfigService) === "function" ? _a : Object])
], SmsService);


/***/ }),

/***/ "./src/auth/services/ycloud.service.ts":
/*!*********************************************!*\
  !*** ./src/auth/services/ycloud.service.ts ***!
  \*********************************************/
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
exports.YcloudService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
const https = __webpack_require__(/*! https */ "https");
let YcloudService = class YcloudService {
    constructor(configService) {
        this.configService = configService;
        this.apiUrl = 'https://api.ycloud.com/v2';
        this.apiKey = this.configService.get('YCLOUD_API_KEY', '');
        if (!this.apiKey) {
            console.warn('⚠️ Ycloud não configurado. Variável YCLOUD_API_KEY necessária.');
        }
        else {
            console.log('✅ Ycloud inicializado com sucesso');
        }
    }
    formatPhoneNumber(phone) {
        let cleaned = phone.replace(/\D/g, '');
        if (!cleaned.startsWith('55')) {
            cleaned = '55' + cleaned;
        }
        return '+' + cleaned;
    }
    async startVerification(phone, channel = 'whatsapp') {
        if (!this.apiKey) {
            return {
                success: false,
                error: 'Ycloud não configurado',
            };
        }
        const formattedPhone = this.formatPhoneNumber(phone);
        try {
            const response = await this.makeRequest('POST', '/verify/verifications', {
                to: formattedPhone,
                channel: channel,
            });
            if (response.success) {
                console.log(`✅ Verificação iniciada via Ycloud (${channel}) para ${formattedPhone}, ID: ${response.data?.id}`);
                return {
                    success: true,
                    verificationId: response.data?.id,
                };
            }
            else {
                throw new Error(response.error || 'Erro ao iniciar verificação');
            }
        }
        catch (error) {
            console.error(`❌ Erro ao iniciar verificação Ycloud para ${formattedPhone}:`, error.message);
            return {
                success: false,
                error: error.message || 'Erro ao iniciar verificação',
            };
        }
    }
    async checkVerification(phone, code, verificationId) {
        if (!this.apiKey) {
            return {
                success: false,
                valid: false,
                error: 'Ycloud não configurado',
            };
        }
        const formattedPhone = this.formatPhoneNumber(phone);
        try {
            const response = await this.makeRequest('POST', '/verify/verifications/check', {
                to: formattedPhone,
                code: code,
            });
            if (response.success) {
                const isValid = response.data?.valid === true || response.data?.status === 'approved';
                if (isValid) {
                    console.log(`✅ Código verificado com sucesso para ${formattedPhone}`);
                }
                else {
                    console.warn(`⚠️ Código inválido para ${formattedPhone}`);
                }
                return {
                    success: true,
                    valid: isValid,
                };
            }
            else {
                throw new Error(response.error || 'Erro ao verificar código');
            }
        }
        catch (error) {
            console.error(`❌ Erro ao verificar código Ycloud para ${formattedPhone}:`, error.message);
            return {
                success: false,
                valid: false,
                error: error.message || 'Erro ao verificar código',
            };
        }
    }
    async makeRequest(method, endpoint, data) {
        return new Promise((resolve, reject) => {
            const url = `${this.apiUrl}${endpoint}`;
            const postData = JSON.stringify(data);
            const options = {
                method,
                headers: {
                    'Content-Type': 'application/json',
                    'X-API-Key': this.apiKey,
                    'Content-Length': Buffer.byteLength(postData),
                },
            };
            const req = https.request(url, options, (res) => {
                let responseData = '';
                res.on('data', (chunk) => {
                    responseData += chunk;
                });
                res.on('end', () => {
                    try {
                        const parsed = JSON.parse(responseData);
                        if (res.statusCode && res.statusCode >= 200 && res.statusCode < 300) {
                            resolve({ success: true, data: parsed });
                        }
                        else {
                            let errorMessage = 'Erro na requisição';
                            if (parsed.message)
                                errorMessage = typeof parsed.message === 'object' ? JSON.stringify(parsed.message) : parsed.message;
                            else if (parsed.error)
                                errorMessage = typeof parsed.error === 'object' ? JSON.stringify(parsed.error) : parsed.error;
                            console.error(`❌ Erro YCloud (Status ${res.statusCode}):`, JSON.stringify(parsed));
                            resolve({
                                success: false,
                                error: errorMessage,
                            });
                        }
                    }
                    catch (e) {
                        resolve({
                            success: false,
                            error: 'Erro ao processar resposta',
                        });
                    }
                });
            });
            req.on('error', (error) => {
                reject(error);
            });
            req.write(postData);
            req.end();
        });
    }
    isConfigured() {
        return !!this.apiKey;
    }
};
exports.YcloudService = YcloudService;
exports.YcloudService = YcloudService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof config_1.ConfigService !== "undefined" && config_1.ConfigService) === "function" ? _a : Object])
], YcloudService);


/***/ }),

/***/ "./src/common/guards/api-key.guard.ts":
/*!********************************************!*\
  !*** ./src/common/guards/api-key.guard.ts ***!
  \********************************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.ApiKeyGuard = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
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

/***/ "./src/common/services/encryption.service.ts":
/*!***************************************************!*\
  !*** ./src/common/services/encryption.service.ts ***!
  \***************************************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.EncryptionService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const CryptoJS = __webpack_require__(/*! crypto-js */ "crypto-js");
const bcrypt = __webpack_require__(/*! bcrypt */ "bcrypt");
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
            const decryptedStr = decrypted.toString(CryptoJS.enc.Utf8);
            if (!decryptedStr || decryptedStr.length === 0) {
                console.error(`❌ Descriptografia retornou vazio. Chave usada: ${this.encryptionKey.substring(0, 10)}...`);
                console.error(`❌ Texto criptografado (primeiros 50 chars): ${encryptedText.substring(0, 50)}`);
                return null;
            }
            return decryptedStr;
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

/***/ "./src/database/database.module.ts":
/*!*****************************************!*\
  !*** ./src/database/database.module.ts ***!
  \*****************************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.DatabaseModule = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const pg_1 = __webpack_require__(/*! pg */ "pg");
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
                        connectionTimeoutMillis: 30000,
                    };
                    if (isCloudRun) {
                        config.host = process.env.INSTANCE_UNIX_SOCKET;
                        console.log(`🔌 Conectando via Unix socket: ${config.host}`);
                    }
                    else {
                        config.host = process.env.DB_HOST;
                        config.port = parseInt(process.env.DB_PORT || '5432');
                        config.ssl = process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false;
                        console.log(`🔌 Conectando via TCP: ${config.host}:${config.port} (SSL: ${config.ssl ? 'sim' : 'não'})`);
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

/***/ "./src/health.controller.ts":
/*!**********************************!*\
  !*** ./src/health.controller.ts ***!
  \**********************************/
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
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const swagger_1 = __webpack_require__(/*! @nestjs/swagger */ "@nestjs/swagger");
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

/***/ "./src/migration.controller.ts":
/*!*************************************!*\
  !*** ./src/migration.controller.ts ***!
  \*************************************/
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
var _a;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.MigrationController = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const pg_1 = __webpack_require__(/*! pg */ "pg");
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
    __param(0, (0, common_1.Inject)('DATABASE_POOL')),
    __metadata("design:paramtypes", [typeof (_a = typeof pg_1.Pool !== "undefined" && pg_1.Pool) === "function" ? _a : Object])
], MigrationController);


/***/ }),

/***/ "./src/users/dto/create-user.dto.ts":
/*!******************************************!*\
  !*** ./src/users/dto/create-user.dto.ts ***!
  \******************************************/
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
const class_validator_1 = __webpack_require__(/*! class-validator */ "class-validator");
const swagger_1 = __webpack_require__(/*! @nestjs/swagger */ "@nestjs/swagger");
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

/***/ "./src/users/dto/pix-key.dto.ts":
/*!**************************************!*\
  !*** ./src/users/dto/pix-key.dto.ts ***!
  \**************************************/
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
const class_validator_1 = __webpack_require__(/*! class-validator */ "class-validator");
const swagger_1 = __webpack_require__(/*! @nestjs/swagger */ "@nestjs/swagger");
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

/***/ "./src/users/dto/store-data.dto.ts":
/*!*****************************************!*\
  !*** ./src/users/dto/store-data.dto.ts ***!
  \*****************************************/
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
const class_validator_1 = __webpack_require__(/*! class-validator */ "class-validator");
const swagger_1 = __webpack_require__(/*! @nestjs/swagger */ "@nestjs/swagger");
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

/***/ "./src/users/dto/update-user.dto.ts":
/*!******************************************!*\
  !*** ./src/users/dto/update-user.dto.ts ***!
  \******************************************/
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
const class_validator_1 = __webpack_require__(/*! class-validator */ "class-validator");
const swagger_1 = __webpack_require__(/*! @nestjs/swagger */ "@nestjs/swagger");
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

/***/ "./src/users/dto/verify-password.dto.ts":
/*!**********************************************!*\
  !*** ./src/users/dto/verify-password.dto.ts ***!
  \**********************************************/
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
const class_validator_1 = __webpack_require__(/*! class-validator */ "class-validator");
const swagger_1 = __webpack_require__(/*! @nestjs/swagger */ "@nestjs/swagger");
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

/***/ "./src/users/services/pix-validation.service.ts":
/*!******************************************************!*\
  !*** ./src/users/services/pix-validation.service.ts ***!
  \******************************************************/
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
exports.PixValidationService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
let PixValidationService = class PixValidationService {
    constructor(configService) {
        this.configService = configService;
        this.pagarmeApiKey = this.configService.get('PAGARME_API_KEY') || null;
    }
    async validatePixKeyReal(key) {
        const formatValidation = this.validatePixKey(key);
        if (!formatValidation.valid) {
            return { valid: false, error: formatValidation.error };
        }
        if (!this.pagarmeApiKey) {
            console.warn('⚠️ PAGARME_API_KEY não configurada. Apenas validação de formato será realizada.');
            return {
                valid: true,
                accountData: {
                    message: 'Chave PIX com formato válido (validação real não disponível)',
                    validated: 'format_only',
                },
            };
        }
        console.log('✅ Chave PIX com formato válido (validação real requer acesso ao DICT)');
        return {
            valid: true,
            accountData: {
                message: 'Chave PIX com formato válido',
                validated: 'format',
                note: 'Validação real no DICT requer integração adicional',
            },
        };
    }
    validatePixKey(key) {
        if (!key || key.trim().length === 0) {
            return { valid: false, type: null, error: 'Chave PIX não pode ser vazia' };
        }
        const cleanedKey = key.trim().replace(/\D/g, '');
        if (cleanedKey.length === 11 && /^\d{11}$/.test(cleanedKey)) {
            if (this.isValidCpf(cleanedKey)) {
                return { valid: true, type: 'CPF' };
            }
            return { valid: false, type: null, error: 'CPF inválido' };
        }
        if ((cleanedKey.length === 10 || cleanedKey.length === 11) && /^\d{10,11}$/.test(cleanedKey)) {
            const ddd = cleanedKey.substring(0, 2);
            if (parseInt(ddd) >= 11 && parseInt(ddd) <= 99) {
                return { valid: true, type: 'PHONE' };
            }
            return { valid: false, type: null, error: 'DDD inválido' };
        }
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (emailRegex.test(key)) {
            return { valid: true, type: 'EMAIL' };
        }
        const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
        if (uuidRegex.test(key)) {
            return { valid: true, type: 'RANDOM' };
        }
        return { valid: false, type: null, error: 'Formato de chave PIX inválido' };
    }
    isValidCpf(cpf) {
        if (cpf.length !== 11)
            return false;
        if (/^(\d)\1{10}$/.test(cpf))
            return false;
        let sum = 0;
        let remainder;
        for (let i = 1; i <= 9; i++) {
            sum += parseInt(cpf.substring(i - 1, i)) * (11 - i);
        }
        remainder = (sum * 10) % 11;
        if (remainder === 10 || remainder === 11)
            remainder = 0;
        if (remainder !== parseInt(cpf.substring(9, 10)))
            return false;
        sum = 0;
        for (let i = 1; i <= 10; i++) {
            sum += parseInt(cpf.substring(i - 1, i)) * (12 - i);
        }
        remainder = (sum * 10) % 11;
        if (remainder === 10 || remainder === 11)
            remainder = 0;
        if (remainder !== parseInt(cpf.substring(10, 11)))
            return false;
        return true;
    }
    formatPixKey(key, type) {
        switch (type) {
            case 'CPF':
                return key.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
            case 'PHONE':
                if (key.length === 11) {
                    return key.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3');
                }
                return key.replace(/(\d{2})(\d{4})(\d{4})/, '($1) $2-$3');
            case 'EMAIL':
            case 'RANDOM':
            default:
                return key;
        }
    }
};
exports.PixValidationService = PixValidationService;
exports.PixValidationService = PixValidationService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof config_1.ConfigService !== "undefined" && config_1.ConfigService) === "function" ? _a : Object])
], PixValidationService);


/***/ }),

/***/ "./src/users/user-transaction.controller.ts":
/*!**************************************************!*\
  !*** ./src/users/user-transaction.controller.ts ***!
  \**************************************************/
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
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const user_transaction_service_1 = __webpack_require__(/*! ./user-transaction.service */ "./src/users/user-transaction.service.ts");
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

/***/ "./src/users/user-transaction.service.ts":
/*!***********************************************!*\
  !*** ./src/users/user-transaction.service.ts ***!
  \***********************************************/
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
var _a;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.UserTransactionService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const pg_1 = __webpack_require__(/*! pg */ "pg");
let UserTransactionService = class UserTransactionService {
    constructor(pool) {
        this.pool = pool;
    }
    async isTransactionSynced(orderId) {
        const client = await this.pool.connect();
        try {
            const result = await client.query('SELECT id FROM pagarme_sync_log WHERE order_id = $1 AND sync_status = $2', [orderId, 'synced']);
            return result.rows.length > 0;
        }
        finally {
            client.release();
        }
    }
    async saveTransaction(transaction) {
        const client = await this.pool.connect();
        try {
            await client.query('BEGIN');
            const transactionResult = await client.query(`INSERT INTO user_transactions (
          user_id, pagarme_order_id, pagarme_charge_id, amount, status,
          establishment_name, customer_name, payment_method
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING id, created_at`, [
                transaction.user_id,
                transaction.pagarme_order_id,
                transaction.pagarme_charge_id || null,
                transaction.amount,
                transaction.status,
                transaction.establishment_name || null,
                transaction.customer_name || null,
                transaction.payment_method || null,
            ]);
            await this.updateUserBalance(client, transaction.user_id, transaction.amount, transaction.status);
            await client.query(`INSERT INTO pagarme_sync_log (order_id, charge_id, sync_status, sync_attempts)
         VALUES ($1, $2, $3, 1)
         ON CONFLICT (order_id) DO UPDATE SET
           sync_status = $3,
           sync_attempts = pagarme_sync_log.sync_attempts + 1,
           last_sync_attempt = NOW()`, [transaction.pagarme_order_id, transaction.pagarme_charge_id || null, 'synced']);
            await client.query('COMMIT');
            return {
                id: transactionResult.rows[0].id,
                ...transaction,
                created_at: transactionResult.rows[0].created_at,
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
    async updateUserBalance(client, userId, amount, status) {
        if (status === 'paid') {
            await client.query(`INSERT INTO user_balances (user_id, available_amount, total_transactions, last_transaction_at, last_updated)
         VALUES ($1, $2, 1, NOW(), NOW())
         ON CONFLICT (user_id) DO UPDATE SET
           available_amount = user_balances.available_amount + $2,
           total_transactions = user_balances.total_transactions + 1,
           last_transaction_at = NOW(),
           last_updated = NOW()`, [userId, amount]);
        }
        else if (status === 'waiting_payment') {
            await client.query(`INSERT INTO user_balances (user_id, waiting_funds, total_transactions, last_transaction_at, last_updated)
         VALUES ($1, $2, 1, NOW(), NOW())
         ON CONFLICT (user_id) DO UPDATE SET
           waiting_funds = user_balances.waiting_funds + $2,
           total_transactions = user_balances.total_transactions + 1,
           last_transaction_at = NOW(),
           last_updated = NOW()`, [userId, amount]);
        }
    }
    async getUserBalance(userId) {
        const client = await this.pool.connect();
        try {
            const result = await client.query('SELECT * FROM user_balances WHERE user_id = $1', [userId]);
            if (result.rows.length === 0) {
                return null;
            }
            return result.rows[0];
        }
        finally {
            client.release();
        }
    }
    async getUserTransactions(userId, limit = 50, offset = 0) {
        const client = await this.pool.connect();
        try {
            const result = await client.query(`SELECT * FROM user_transactions 
         WHERE user_id = $1 
         ORDER BY created_at DESC 
         LIMIT $2 OFFSET $3`, [userId, limit, offset]);
            return result.rows;
        }
        finally {
            client.release();
        }
    }
    async getUserStats(userId) {
        const client = await this.pool.connect();
        try {
            const result = await client.query(`SELECT 
          COUNT(*) as total_transactions,
          SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) as total_received,
          SUM(CASE WHEN status = 'failed' THEN amount ELSE 0 END) as total_failed,
          AVG(CASE WHEN status = 'paid' THEN amount ELSE NULL END) as avg_transaction
         FROM user_transactions 
         WHERE user_id = $1`, [userId]);
            return result.rows[0] || {
                total_transactions: 0,
                total_received: 0,
                total_failed: 0,
                avg_transaction: 0,
            };
        }
        finally {
            client.release();
        }
    }
};
exports.UserTransactionService = UserTransactionService;
exports.UserTransactionService = UserTransactionService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, common_1.Inject)('DATABASE_POOL')),
    __metadata("design:paramtypes", [typeof (_a = typeof pg_1.Pool !== "undefined" && pg_1.Pool) === "function" ? _a : Object])
], UserTransactionService);


/***/ }),

/***/ "./src/users/users.controller.ts":
/*!***************************************!*\
  !*** ./src/users/users.controller.ts ***!
  \***************************************/
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
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const swagger_1 = __webpack_require__(/*! @nestjs/swagger */ "@nestjs/swagger");
const throttler_1 = __webpack_require__(/*! @nestjs/throttler */ "@nestjs/throttler");
const users_service_1 = __webpack_require__(/*! ./users.service */ "./src/users/users.service.ts");
const create_user_dto_1 = __webpack_require__(/*! ./dto/create-user.dto */ "./src/users/dto/create-user.dto.ts");
const update_user_dto_1 = __webpack_require__(/*! ./dto/update-user.dto */ "./src/users/dto/update-user.dto.ts");
const verify_password_dto_1 = __webpack_require__(/*! ./dto/verify-password.dto */ "./src/users/dto/verify-password.dto.ts");
const store_data_dto_1 = __webpack_require__(/*! ./dto/store-data.dto */ "./src/users/dto/store-data.dto.ts");
const pix_key_dto_1 = __webpack_require__(/*! ./dto/pix-key.dto */ "./src/users/dto/pix-key.dto.ts");
const api_key_guard_1 = __webpack_require__(/*! ../common/guards/api-key.guard */ "./src/common/guards/api-key.guard.ts");
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
    (0, common_1.Post)('sync-firebase-email'),
    (0, swagger_1.ApiOperation)({ summary: 'Sincronizar email do Firebase com PostgreSQL' }),
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

/***/ "./src/users/users.module.ts":
/*!***********************************!*\
  !*** ./src/users/users.module.ts ***!
  \***********************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.UsersModule = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
const users_service_1 = __webpack_require__(/*! ./users.service */ "./src/users/users.service.ts");
const users_controller_1 = __webpack_require__(/*! ./users.controller */ "./src/users/users.controller.ts");
const user_transaction_service_1 = __webpack_require__(/*! ./user-transaction.service */ "./src/users/user-transaction.service.ts");
const user_transaction_controller_1 = __webpack_require__(/*! ./user-transaction.controller */ "./src/users/user-transaction.controller.ts");
const encryption_service_1 = __webpack_require__(/*! ../common/services/encryption.service */ "./src/common/services/encryption.service.ts");
const pix_validation_service_1 = __webpack_require__(/*! ./services/pix-validation.service */ "./src/users/services/pix-validation.service.ts");
let UsersModule = class UsersModule {
};
exports.UsersModule = UsersModule;
exports.UsersModule = UsersModule = __decorate([
    (0, common_1.Module)({
        imports: [config_1.ConfigModule],
        controllers: [users_controller_1.UsersController, user_transaction_controller_1.UserTransactionController],
        providers: [users_service_1.UsersService, user_transaction_service_1.UserTransactionService, encryption_service_1.EncryptionService, pix_validation_service_1.PixValidationService],
        exports: [users_service_1.UsersService, user_transaction_service_1.UserTransactionService],
    })
], UsersModule);


/***/ }),

/***/ "./src/users/users.service.ts":
/*!************************************!*\
  !*** ./src/users/users.service.ts ***!
  \************************************/
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
var _a, _b, _c;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.UsersService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const pg_1 = __webpack_require__(/*! pg */ "pg");
const encryption_service_1 = __webpack_require__(/*! ../common/services/encryption.service */ "./src/common/services/encryption.service.ts");
const pix_validation_service_1 = __webpack_require__(/*! ./services/pix-validation.service */ "./src/users/services/pix-validation.service.ts");
const admin = __webpack_require__(/*! firebase-admin */ "firebase-admin");
let UsersService = class UsersService {
    constructor(pool, encryptionService, pixValidationService) {
        this.pool = pool;
        this.encryptionService = encryptionService;
        this.pixValidationService = pixValidationService;
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
            const allCpfs = [];
            for (const user of result.rows) {
                try {
                    const decryptedCpf = this.decryptFromBytea(user.cpf_encrypted);
                    allCpfs.push(decryptedCpf);
                    console.log(`🔐 CPF descriptografado: ${decryptedCpf} (buscando: ${cpf})`);
                    const normalizedDecrypted = decryptedCpf.replace(/\D/g, '');
                    const normalizedSearch = cpf.replace(/\D/g, '');
                    if (normalizedDecrypted === normalizedSearch) {
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
            if (allCpfs.length > 0) {
                console.log(`📋 Todos os CPFs encontrados no banco: ${allCpfs.join(', ')}`);
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
                }
                catch (addrError) {
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
        }
        catch (error) {
            console.error('Erro ao buscar usuário:', error);
            throw error;
        }
    }
    async findByPhone(phone) {
        try {
            console.log(`🔍 Buscando usuário por telefone: ${phone}`);
            const result = await this.pool.query(`SELECT 
          up.user_id,
          up.phone_encrypted
        FROM user_phones up
        JOIN users u ON u.id = up.user_id
        WHERE u.deleted_at IS NULL AND up.is_primary = true`);
            console.log(`📊 Encontrados ${result.rows.length} telefones para verificar`);
            let foundUserId = null;
            const normalizedSearch = phone.replace(/\D/g, '');
            for (const row of result.rows) {
                try {
                    const decryptedPhone = this.decryptFromBytea(row.phone_encrypted);
                    const normalizedDecrypted = decryptedPhone.replace(/\D/g, '');
                    if (normalizedDecrypted === normalizedSearch ||
                        normalizedDecrypted.endsWith(normalizedSearch) ||
                        normalizedSearch.endsWith(normalizedDecrypted)) {
                        console.log(`✅ Telefone encontrado! User ID: ${row.user_id}`);
                        foundUserId = row.user_id;
                        break;
                    }
                }
                catch (error) {
                    continue;
                }
            }
            if (!foundUserId) {
                return null;
            }
            return this.findById(foundUserId);
        }
        catch (error) {
            console.error('Erro ao buscar usuário por telefone:', error);
            throw error;
        }
    }
    async checkByCpf(cpf) {
        try {
            console.log(`🔍 Verificando existência de CPF: ${cpf}`);
            const result = await this.pool.query(`SELECT 
          u.id,
          u.cpf_encrypted,
          u.kyc_status
        FROM users u
        WHERE u.deleted_at IS NULL`);
            let foundUser = null;
            for (const user of result.rows) {
                try {
                    const decryptedCpf = this.decryptFromBytea(user.cpf_encrypted);
                    const normalizedDecrypted = decryptedCpf.replace(/\D/g, '');
                    const normalizedSearch = cpf.replace(/\D/g, '');
                    if (normalizedDecrypted === normalizedSearch) {
                        foundUser = user;
                        break;
                    }
                }
                catch (error) {
                    continue;
                }
            }
            if (!foundUser) {
                return { exists: false };
            }
            return {
                exists: true,
                kyc_status: foundUser.kyc_status,
            };
        }
        catch (error) {
            console.error('Erro ao verificar CPF:', error);
            throw error;
        }
    }
    async findByEmail(email) {
        try {
            const normalizedEmail = email.trim().toLowerCase();
            console.log(`🔍 Buscando usuário por email: ${normalizedEmail}`);
            console.log(`🔍 Email original recebido: ${email}`);
            const result = await this.pool.query(`SELECT 
          u.id,
          u.full_name,
          u.cpf_encrypted,
          u.email_encrypted,
          u.kyc_status,
          u.created_at
        FROM users u
        WHERE u.deleted_at IS NULL`);
            console.log(`📊 Encontrados ${result.rows.length} usuários ativos para verificar`);
            let foundUser = null;
            for (const user of result.rows) {
                try {
                    const decryptedEmail = this.decryptFromBytea(user.email_encrypted);
                    const normalizedDecryptedEmail = decryptedEmail.trim().toLowerCase();
                    console.log(`🔐 Email descriptografado: ${normalizedDecryptedEmail} (original: ${decryptedEmail})`);
                    if (normalizedDecryptedEmail === normalizedEmail) {
                        console.log(`✅ Usuário encontrado! ID: ${user.id}`);
                        foundUser = user;
                        break;
                    }
                }
                catch (error) {
                    console.error(`❌ Erro ao descriptografar email do usuário ${user.id}:`, error);
                    console.error(`   Erro detalhado:`, error);
                    continue;
                }
            }
            if (!foundUser) {
                console.log(`⚠️  Nenhum usuário encontrado com email: ${email}`);
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
                }
                catch (addrError) {
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
        }
        catch (error) {
            console.error('Erro ao buscar usuário por email:', error);
            throw error;
        }
    }
    async verifyPassword(verifyPasswordDto) {
        const userData = await this.findByCpf(verifyPasswordDto.cpf);
        if (!userData || !userData.email) {
            throw new common_1.NotFoundException('Usuário não encontrado');
        }
        try {
            const auth = admin.auth();
            const user = await auth.getUserByEmail(userData.email);
            return {
                valid: true,
                message: 'Validação de senha deve ser feita no cliente usando Firebase Auth',
            };
        }
        catch (error) {
            return {
                valid: false,
                message: 'Erro ao verificar senha',
            };
        }
    }
    async verifyPasswordInternal(userId, password) {
        try {
            const userData = await this.findById(userId);
            if (!userData || !userData.email) {
                return false;
            }
            return true;
        }
        catch (error) {
            return false;
        }
    }
    async findById(userId) {
        try {
            const result = await this.pool.query(`SELECT 
          u.id,
          u.full_name,
          u.cpf_encrypted,
          u.email_encrypted,
          u.kyc_status,
          u.created_at
        FROM users u
        WHERE u.id = $1 AND u.deleted_at IS NULL`, [userId]);
            if (result.rows.length === 0) {
                return null;
            }
            const user = result.rows[0];
            const phoneResult = await this.pool.query('SELECT phone_encrypted FROM user_phones WHERE user_id = $1 AND is_primary = true', [user.id]);
            return {
                id: user.id,
                email: this.decryptFromBytea(user.email_encrypted),
                full_name: this.decryptFromBytea(user.full_name),
                cpf: this.decryptFromBytea(user.cpf_encrypted),
                phone: phoneResult.rows[0]?.phone_encrypted ? this.decryptFromBytea(phoneResult.rows[0].phone_encrypted) : null,
                kyc_status: user.kyc_status,
                created_at: user.created_at,
            };
        }
        catch (error) {
            console.error('Erro ao buscar usuário por ID:', error);
            throw error;
        }
    }
    async updatePassword(userId, newPassword) {
        try {
            const userData = await this.findById(userId);
            if (!userData || !userData.email) {
                throw new common_1.NotFoundException('Usuário não encontrado');
            }
            const auth = admin.auth();
            const firebaseUser = await auth.getUserByEmail(userData.email);
            await auth.updateUser(firebaseUser.uid, {
                password: newPassword,
            });
            console.log(`✅ Senha atualizada no Firebase para usuário ${userId}`);
        }
        catch (error) {
            console.error(`❌ Erro ao atualizar senha:`, error);
            throw new Error(`Falha ao atualizar senha: ${error.message}`);
        }
    }
    async update(id, updateUserDto) {
        const client = await this.pool.connect();
        try {
            await client.query('BEGIN');
            const userExists = await client.query('SELECT id FROM users WHERE id = $1', [id]);
            if (userExists.rows.length === 0) {
                throw new common_1.NotFoundException(`Usuário com ID ${id} não encontrado`);
            }
            if (updateUserDto.fullName) {
                const fullNameEncrypted = this.encryptToBytea(updateUserDto.fullName);
                await client.query('UPDATE users SET full_name = $1, updated_at = NOW() WHERE id = $2', [fullNameEncrypted, id]);
            }
            if (updateUserDto.email) {
                const emailEncrypted = this.encryptToBytea(updateUserDto.email);
                await client.query('UPDATE users SET email_encrypted = $1, updated_at = NOW() WHERE id = $2', [emailEncrypted, id]);
            }
            if (updateUserDto.phone) {
                const phoneEncrypted = this.encryptToBytea(updateUserDto.phone);
                try {
                    const existingPhone = await client.query('SELECT id FROM user_phones WHERE user_id = $1 AND is_primary = true', [id]);
                    if (existingPhone.rows.length > 0) {
                        await client.query('UPDATE user_phones SET phone_encrypted = $1, updated_at = NOW() WHERE user_id = $2 AND is_primary = true', [phoneEncrypted, id]);
                    }
                    else {
                        await client.query('INSERT INTO user_phones (user_id, phone_encrypted, is_primary, phone_type) VALUES ($1, $2, true, $3)', [id, phoneEncrypted, 'mobile']);
                    }
                }
                catch (error) {
                    if (error.code === '42P01' || error.message?.includes('does not exist')) {
                        console.log('Tabela user_phones não encontrada, atualizando diretamente em users');
                        await client.query('UPDATE users SET phone_encrypted = $1, updated_at = NOW() WHERE id = $2', [phoneEncrypted, id]);
                    }
                    else {
                        throw error;
                    }
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
    async syncFirebaseEmail(cpf, oldEmail) {
        try {
            console.log(`🔄 Sincronizando email do Firebase para CPF: ${cpf}`);
            const userData = await this.findByCpf(cpf);
            if (!userData || !userData.email) {
                throw new common_1.NotFoundException('Usuário não encontrado no PostgreSQL ou email não encontrado');
            }
            const newEmail = userData.email;
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
            const auth = admin.auth();
            let firebaseUser;
            try {
                firebaseUser = await auth.getUserByEmail(oldEmail);
                console.log(`✅ Usuário encontrado no Firebase: ${firebaseUser.uid}`);
            }
            catch (error) {
                if (error.code === 'auth/user-not-found') {
                    throw new common_1.NotFoundException(`Usuário não encontrado no Firebase com email: ${oldEmail}`);
                }
                throw error;
            }
            try {
                await auth.updateUser(firebaseUser.uid, {
                    email: newEmail,
                    emailVerified: false,
                });
                console.log(`✅ Email atualizado no Firebase: ${oldEmail} → ${newEmail}`);
                await auth.generateEmailVerificationLink(newEmail);
                console.log(`📧 Link de verificação gerado para: ${newEmail}`);
                return {
                    success: true,
                    message: 'Email sincronizado com sucesso',
                    oldEmail,
                    newEmail,
                    firebaseUid: firebaseUser.uid,
                };
            }
            catch (error) {
                console.error(`❌ Erro ao atualizar email no Firebase:`, error);
                throw new Error(`Falha ao atualizar email no Firebase: ${error.message}`);
            }
        }
        catch (error) {
            console.error(`❌ Erro ao sincronizar email:`, error);
            throw error;
        }
    }
    async getStoreData(userId) {
        const result = await this.pool.query('SELECT id, store_name, business_type, created_at, updated_at FROM user_stores WHERE user_id = $1', [userId]);
        if (result.rows.length === 0) {
            return null;
        }
        return result.rows[0];
    }
    async upsertStoreData(userId, storeData) {
        const client = await this.pool.connect();
        try {
            await client.query('BEGIN');
            const existing = await client.query('SELECT id FROM user_stores WHERE user_id = $1', [userId]);
            if (existing.rows.length > 0) {
                await client.query('UPDATE user_stores SET store_name = $1, business_type = $2, updated_at = NOW() WHERE user_id = $3', [storeData.store_name, storeData.business_type, userId]);
            }
            else {
                await client.query('INSERT INTO user_stores (user_id, store_name, business_type) VALUES ($1, $2, $3)', [userId, storeData.store_name, storeData.business_type]);
            }
            await client.query('COMMIT');
            return {
                success: true,
                message: 'Dados da loja salvos com sucesso',
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
    async getPixKeys(userId) {
        const result = await this.pool.query('SELECT id, pix_key, key_type, is_verified, is_primary, display_order, created_at, updated_at FROM user_pix_keys WHERE user_id = $1 ORDER BY display_order ASC, created_at ASC', [userId]);
        return result.rows.map((row) => ({
            ...row,
            pix_key_formatted: this.pixValidationService.formatPixKey(row.pix_key, row.key_type),
        }));
    }
    async addPixKey(userId, createPixKeyDto) {
        const client = await this.pool.connect();
        try {
            const formatValidation = this.pixValidationService.validatePixKey(createPixKeyDto.pix_key);
            if (!formatValidation.valid) {
                throw new common_1.BadRequestException(formatValidation.error || 'Formato de chave PIX inválido');
            }
            const realValidation = await this.pixValidationService.validatePixKeyReal(createPixKeyDto.pix_key);
            if (!realValidation.valid) {
                throw new common_1.BadRequestException(realValidation.error || 'Chave PIX não encontrada ou inválida no sistema bancário');
            }
            const keyType = formatValidation.type;
            await client.query('BEGIN');
            const existing = await client.query('SELECT id, user_id FROM user_pix_keys WHERE pix_key = $1', [createPixKeyDto.pix_key]);
            if (existing.rows.length > 0) {
                throw new common_1.ConflictException('Esta chave PIX já está cadastrada');
            }
            const countResult = await client.query('SELECT COUNT(*) as count FROM user_pix_keys WHERE user_id = $1', [userId]);
            const count = parseInt(countResult.rows[0].count);
            if (count >= 5) {
                throw new common_1.BadRequestException('Limite máximo de 5 chaves PIX atingido');
            }
            const isFirstKey = count === 0;
            const maxOrderResult = await client.query('SELECT MAX(display_order) as max_order FROM user_pix_keys WHERE user_id = $1', [userId]);
            const nextOrder = (maxOrderResult.rows[0].max_order || 0) + 1;
            await client.query(`INSERT INTO user_pix_keys (user_id, pix_key, key_type, is_verified, is_primary, display_order)
         VALUES ($1, $2, $3, TRUE, $4, $5)`, [userId, createPixKeyDto.pix_key, keyType, isFirstKey, nextOrder]);
            await client.query('COMMIT');
            return {
                success: true,
                message: 'Chave PIX cadastrada com sucesso',
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
    async removePixKey(userId, keyId) {
        const client = await this.pool.connect();
        try {
            await client.query('BEGIN');
            const keyResult = await client.query('SELECT is_primary FROM user_pix_keys WHERE id = $1 AND user_id = $2', [keyId, userId]);
            if (keyResult.rows.length === 0) {
                throw new common_1.NotFoundException('Chave PIX não encontrada');
            }
            const countResult = await client.query('SELECT COUNT(*) as count FROM user_pix_keys WHERE user_id = $1', [userId]);
            const count = parseInt(countResult.rows[0].count);
            if (count === 1) {
                throw new common_1.BadRequestException('Não é possível remover a única chave PIX cadastrada');
            }
            const wasPrimary = keyResult.rows[0].is_primary;
            await client.query('DELETE FROM user_pix_keys WHERE id = $1 AND user_id = $2', [keyId, userId]);
            if (wasPrimary) {
                const firstKeyResult = await client.query('SELECT id FROM user_pix_keys WHERE user_id = $1 ORDER BY display_order ASC LIMIT 1', [userId]);
                if (firstKeyResult.rows.length > 0) {
                    await client.query('UPDATE user_pix_keys SET is_primary = TRUE WHERE id = $1', [firstKeyResult.rows[0].id]);
                }
            }
            await client.query('COMMIT');
            return {
                success: true,
                message: 'Chave PIX removida com sucesso',
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
exports.UsersService = UsersService;
exports.UsersService = UsersService = __decorate([
    (0, common_1.Injectable)(),
    __param(0, (0, common_1.Inject)('DATABASE_POOL')),
    __metadata("design:paramtypes", [typeof (_a = typeof pg_1.Pool !== "undefined" && pg_1.Pool) === "function" ? _a : Object, typeof (_b = typeof encryption_service_1.EncryptionService !== "undefined" && encryption_service_1.EncryptionService) === "function" ? _b : Object, typeof (_c = typeof pix_validation_service_1.PixValidationService !== "undefined" && pix_validation_service_1.PixValidationService) === "function" ? _c : Object])
], UsersService);


/***/ }),

/***/ "@aws-sdk/client-ses":
/*!**************************************!*\
  !*** external "@aws-sdk/client-ses" ***!
  \**************************************/
/***/ ((module) => {

module.exports = require("@aws-sdk/client-ses");

/***/ }),

/***/ "@nestjs/common":
/*!*********************************!*\
  !*** external "@nestjs/common" ***!
  \*********************************/
/***/ ((module) => {

module.exports = require("@nestjs/common");

/***/ }),

/***/ "@nestjs/config":
/*!*********************************!*\
  !*** external "@nestjs/config" ***!
  \*********************************/
/***/ ((module) => {

module.exports = require("@nestjs/config");

/***/ }),

/***/ "@nestjs/core":
/*!*******************************!*\
  !*** external "@nestjs/core" ***!
  \*******************************/
/***/ ((module) => {

module.exports = require("@nestjs/core");

/***/ }),

/***/ "@nestjs/swagger":
/*!**********************************!*\
  !*** external "@nestjs/swagger" ***!
  \**********************************/
/***/ ((module) => {

module.exports = require("@nestjs/swagger");

/***/ }),

/***/ "@nestjs/throttler":
/*!************************************!*\
  !*** external "@nestjs/throttler" ***!
  \************************************/
/***/ ((module) => {

module.exports = require("@nestjs/throttler");

/***/ }),

/***/ "@sendgrid/mail":
/*!*********************************!*\
  !*** external "@sendgrid/mail" ***!
  \*********************************/
/***/ ((module) => {

module.exports = require("@sendgrid/mail");

/***/ }),

/***/ "bcrypt":
/*!*************************!*\
  !*** external "bcrypt" ***!
  \*************************/
/***/ ((module) => {

module.exports = require("bcrypt");

/***/ }),

/***/ "class-validator":
/*!**********************************!*\
  !*** external "class-validator" ***!
  \**********************************/
/***/ ((module) => {

module.exports = require("class-validator");

/***/ }),

/***/ "crypto-js":
/*!****************************!*\
  !*** external "crypto-js" ***!
  \****************************/
/***/ ((module) => {

module.exports = require("crypto-js");

/***/ }),

/***/ "firebase-admin":
/*!*********************************!*\
  !*** external "firebase-admin" ***!
  \*********************************/
/***/ ((module) => {

module.exports = require("firebase-admin");

/***/ }),

/***/ "helmet":
/*!*************************!*\
  !*** external "helmet" ***!
  \*************************/
/***/ ((module) => {

module.exports = require("helmet");

/***/ }),

/***/ "pg":
/*!*********************!*\
  !*** external "pg" ***!
  \*********************/
/***/ ((module) => {

module.exports = require("pg");

/***/ }),

/***/ "resend":
/*!*************************!*\
  !*** external "resend" ***!
  \*************************/
/***/ ((module) => {

module.exports = require("resend");

/***/ }),

/***/ "twilio":
/*!*************************!*\
  !*** external "twilio" ***!
  \*************************/
/***/ ((module) => {

module.exports = require("twilio");

/***/ }),

/***/ "crypto":
/*!*************************!*\
  !*** external "crypto" ***!
  \*************************/
/***/ ((module) => {

module.exports = require("crypto");

/***/ }),

/***/ "fs":
/*!*********************!*\
  !*** external "fs" ***!
  \*********************/
/***/ ((module) => {

module.exports = require("fs");

/***/ }),

/***/ "https":
/*!************************!*\
  !*** external "https" ***!
  \************************/
/***/ ((module) => {

module.exports = require("https");

/***/ }),

/***/ "path":
/*!***********************!*\
  !*** external "path" ***!
  \***********************/
/***/ ((module) => {

module.exports = require("path");

/***/ })

/******/ 	});
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
/*!*********************!*\
  !*** ./src/main.ts ***!
  \*********************/

Object.defineProperty(exports, "__esModule", ({ value: true }));
const core_1 = __webpack_require__(/*! @nestjs/core */ "@nestjs/core");
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const swagger_1 = __webpack_require__(/*! @nestjs/swagger */ "@nestjs/swagger");
const helmet_1 = __webpack_require__(/*! helmet */ "helmet");
const app_module_1 = __webpack_require__(/*! ./app.module */ "./src/app.module.ts");
const admin = __webpack_require__(/*! firebase-admin */ "firebase-admin");
if (!admin.apps.length) {
    admin.initializeApp({
        projectId: process.env.GOOGLE_CLOUD_PROJECT || 'apppagpag',
    });
    console.log('🔥 Firebase Admin inicializado');
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
            .setDescription('API Backend for Neves Capital - PostgreSQL + Firebase')
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