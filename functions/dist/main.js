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
const health_controller_1 = __webpack_require__(/*! ./health.controller */ "./src/health.controller.ts");
const firebase_rest_module_1 = __webpack_require__(/*! ./firebase-rest/firebase-rest.module */ "./src/firebase-rest/firebase-rest.module.ts");
const efi_module_1 = __webpack_require__(/*! ./efi/efi.module */ "./src/efi/efi.module.ts");
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
            firebase_rest_module_1.FirebaseRestModule,
            users_module_1.UsersModule,
            auth_module_1.AuthModule,
            efi_module_1.EfiModule,
        ],
        controllers: [health_controller_1.HealthController],
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
var _a, _b, _c, _d, _e, _f, _g, _h, _j, _k, _l;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.AuthController = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const swagger_1 = __webpack_require__(/*! @nestjs/swagger */ "@nestjs/swagger");
const throttler_1 = __webpack_require__(/*! @nestjs/throttler */ "@nestjs/throttler");
const api_key_guard_1 = __webpack_require__(/*! ../common/guards/api-key.guard */ "./src/common/guards/api-key.guard.ts");
const auth_jwt_service_1 = __webpack_require__(/*! ../firebase-rest/auth-jwt.service */ "./src/firebase-rest/auth-jwt.service.ts");
const email_sender_service_1 = __webpack_require__(/*! ./email-sender.service */ "./src/auth/email-sender.service.ts");
const simple_otp_service_1 = __webpack_require__(/*! ./services/simple-otp.service */ "./src/auth/services/simple-otp.service.ts");
const whatsapp_service_1 = __webpack_require__(/*! ./services/whatsapp.service */ "./src/auth/services/whatsapp.service.ts");
const users_service_1 = __webpack_require__(/*! ../users/users.service */ "./src/users/users.service.ts");
const reset_password_dto_1 = __webpack_require__(/*! ./dto/reset-password.dto */ "./src/auth/dto/reset-password.dto.ts");
const send_phone_otp_dto_1 = __webpack_require__(/*! ./dto/send-phone-otp.dto */ "./src/auth/dto/send-phone-otp.dto.ts");
let AuthController = class AuthController {
    constructor(emailSenderService, simpleOtpService, whatsAppService, usersService, authJwt) {
        this.emailSenderService = emailSenderService;
        this.simpleOtpService = simpleOtpService;
        this.whatsAppService = whatsAppService;
        this.usersService = usersService;
        this.authJwt = authJwt;
    }
    async resetPassword(resetPasswordDto) {
        try {
            await this.emailSenderService.sendPasswordResetEmail(resetPasswordDto.email);
            return {
                success: true,
                message: 'Email de redefinicao de senha enviado com sucesso',
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
        console.log(`[OTP-TIMING] Firestore (gerar+salvar OTP): ${t2 - t1}ms`);
        if (!result.success) {
            throw new common_1.BadRequestException(result.message);
        }
        if (result.code) {
            const t3 = Date.now();
            this.whatsAppService.sendOtpMessage(body.phone, result.code)
                .then((sent) => {
                console.log(`[OTP-TIMING] Twilio WhatsApp: ${Date.now() - t3}ms`);
                if (!sent) {
                    console.warn(`[AuthController] Falha ao enviar OTP via WhatsApp para ${body.phone.substring(0, 4)}***`);
                }
            })
                .catch((err) => {
                console.error(`[AuthController] Erro ao enviar OTP via WhatsApp: ${err.message}`);
            });
        }
        console.log(`[OTP-TIMING] TOTAL (ate response): ${Date.now() - t0}ms`);
        return {
            success: true,
            message: 'Codigo de verificacao enviado via WhatsApp',
        };
    }
    async verifyOtpLogin(body) {
        const otpResult = await this.simpleOtpService.verifyOtp(body.phone, body.code);
        if (!otpResult.success) {
            throw new common_1.BadRequestException(otpResult.message);
        }
        const normalizedPhone = body.phone.replace(/\D/g, '');
        console.log(`[AuthController] OTP verificado para ${normalizedPhone.substring(0, 4)}***`);
        const user = await this.usersService.findByPhone(normalizedPhone);
        if (user) {
            const isComplete = this.isRegistrationComplete(user);
            if (!isComplete) {
                console.log(`[AuthController] Usuario encontrado mas cadastro incompleto. ID: ${user.id}`);
                return {
                    success: true,
                    status: 'REGISTER',
                    message: 'Cadastro incompleto. Redirecionando para finalizar cadastro.',
                    phone: normalizedPhone,
                };
            }
            console.log(`[AuthController] Usuario completo encontrado. ID: ${user.id}`);
            try {
                const token = this.authJwt.signToken({
                    sub: user.id,
                    phone: normalizedPhone,
                });
                console.log(`[AuthController] JWT token gerado para userId: ${user.id}`);
                try {
                    await this.usersService.updateLastLogin(user.id);
                }
                catch (error) {
                    console.warn(`[AuthController] Erro ao registrar login (nao critico): ${error.message}`);
                }
                return {
                    success: true,
                    status: 'LOGGED_IN',
                    message: 'Login realizado com sucesso.',
                    token,
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
                console.error(`[AuthController] Erro ao gerar JWT token: ${error.message}`);
                throw new common_1.BadRequestException('Erro ao processar login. Tente novamente.');
            }
        }
        else {
            console.log(`[AuthController] Usuario nao encontrado para ${normalizedPhone.substring(0, 4)}***`);
            return {
                success: true,
                status: 'REGISTER',
                message: 'Usuario nao encontrado. Redirecionando para cadastro.',
                phone: normalizedPhone,
            };
        }
    }
    async checkUserStatus(body) {
        try {
            console.log('[AuthController] Verificando status do usuario...');
            let decoded;
            try {
                decoded = this.authJwt.verifyToken(body.token);
            }
            catch (error) {
                throw new common_1.UnauthorizedException('Token invalido ou expirado');
            }
            const userId = decoded.sub;
            const phoneNumber = decoded.phone;
            console.log(`[AuthController] Token verificado. userId: ${userId}, Phone: ${phoneNumber?.substring(0, 4)}****`);
            if (!phoneNumber) {
                throw new common_1.BadRequestException('Token nao contem numero de telefone');
            }
            const normalizedPhone = phoneNumber.replace(/\D/g, '');
            console.log(`[AuthController] Buscando usuario no Firestore...`);
            const user = await this.usersService.findByPhone(normalizedPhone);
            if (user) {
                const isRegistrationComplete = this.isRegistrationComplete(user);
                if (!isRegistrationComplete) {
                    console.log(`[AuthController] Usuario encontrado mas cadastro incompleto. ID: ${user.id}`);
                    return {
                        success: true,
                        status: 'REGISTER',
                        message: 'Cadastro incompleto. Redirecionando para finalizar cadastro.',
                        phone: normalizedPhone,
                    };
                }
                console.log(`[AuthController] Usuario encontrado com cadastro completo. ID: ${user.id}`);
                try {
                    await this.usersService.updateLastLogin(user.id);
                    console.log(`[AuthController] Login registrado para usuario ${user.id}`);
                }
                catch (error) {
                    console.warn(`[AuthController] Erro ao registrar login (nao critico): ${error.message}`);
                }
                return {
                    success: true,
                    status: 'LOGGED_IN',
                    message: 'Usuario autenticado com sucesso. Redirecionando para o dashboard.',
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
                console.log(`[AuthController] Usuario nao encontrado. Redirecionando para cadastro.`);
                return {
                    success: true,
                    status: 'REGISTER',
                    message: 'Usuario nao encontrado. Redirecionando para cadastro.',
                    phone: normalizedPhone,
                };
            }
        }
        catch (error) {
            console.error(`[AuthController] Erro ao verificar status:`, {
                message: error.message,
                code: error.code,
                stack: error.stack,
            });
            if (error instanceof common_1.BadRequestException || error instanceof common_1.UnauthorizedException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao verificar status: ${error.message}`);
        }
    }
    isRegistrationComplete(user) {
        const hasCpf = !!(user.cpfEncrypted || user.cpfHash || user.cpf);
        if (!hasCpf) {
            console.log(`[AuthController] Campo obrigatorio ausente: CPF (cpfEncrypted/cpfHash/cpf)`);
            return false;
        }
        const hasEmail = !!(user.emailEncrypted || user.emailHash || user.email);
        if (!hasEmail) {
            console.log(`[AuthController] Campo obrigatorio ausente: Email (emailEncrypted/emailHash/email)`);
            return false;
        }
        const hasFullName = !!(user.displayName || user.full_name);
        if (!hasFullName) {
            console.log(`[AuthController] Campo obrigatorio ausente: Nome Completo (displayName/full_name)`);
            return false;
        }
        const hasPhone = !!(user.phone || user.phoneHash);
        if (!hasPhone) {
            console.log(`[AuthController] Campo obrigatorio ausente: Telefone (phone/phoneHash)`);
            return false;
        }
        if (!user.birthDate) {
            console.log(`[AuthController] Campo obrigatorio ausente: birthDate`);
            return false;
        }
        if (!user.motherName || user.motherName === '') {
            console.log(`[AuthController] Campo obrigatorio ausente: motherName`);
            return false;
        }
        if (!user.occupation || user.occupation === '') {
            console.log(`[AuthController] Campo obrigatorio ausente: occupation`);
            return false;
        }
        if (!user.incomeRange || user.incomeRange === '') {
            console.log(`[AuthController] Campo obrigatorio ausente: incomeRange`);
            return false;
        }
        const hasDocumentType = !!(user.kycDocuments?.documentType || user.documentType);
        if (!hasDocumentType) {
            console.log(`[AuthController] Campo obrigatorio ausente: documentType (kycDocuments.documentType/documentType)`);
            return false;
        }
        console.log(`[AuthController] Todos os campos obrigatorios estao presentes`);
        return true;
    }
};
exports.AuthController = AuthController;
__decorate([
    (0, common_1.Post)('reset-password'),
    (0, throttler_1.Throttle)({ default: { limit: 5, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Enviar email de redefinicao de senha (customizado)',
        description: 'Envia email customizado com template personalizado'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Email enviado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Email invalido' }),
    (0, swagger_1.ApiResponse)({ status: 404, description: 'Usuario nao encontrado' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_f = typeof reset_password_dto_1.ResetPasswordDto !== "undefined" && reset_password_dto_1.ResetPasswordDto) === "function" ? _f : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "resetPassword", null);
__decorate([
    (0, common_1.Post)('send-otp'),
    (0, throttler_1.Throttle)({ default: { limit: 3, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Enviar codigo OTP para telefone (alternativa ao Firebase Phone Auth)',
        description: 'Gera e retorna codigo OTP de 6 digitos. Para testes, o codigo e retornado no response.'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'OTP gerado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Telefone invalido' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_g = typeof send_phone_otp_dto_1.SendPhoneOtpDto !== "undefined" && send_phone_otp_dto_1.SendPhoneOtpDto) === "function" ? _g : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "sendOtp", null);
__decorate([
    (0, common_1.Post)('verify-otp'),
    (0, throttler_1.Throttle)({ default: { limit: 10, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Verificar codigo OTP',
        description: 'Valida o codigo OTP enviado pelo usuario'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'OTP verificado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Codigo invalido ou expirado' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_h = typeof send_phone_otp_dto_1.VerifyPhoneOtpDto !== "undefined" && send_phone_otp_dto_1.VerifyPhoneOtpDto) === "function" ? _h : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "verifyOtp", null);
__decorate([
    (0, common_1.Post)('send-otp-whatsapp'),
    (0, throttler_1.Throttle)({ default: { limit: 3, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Enviar codigo OTP via WhatsApp',
        description: 'Gera codigo OTP de 4 digitos e envia via WhatsApp para o telefone informado'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'OTP enviado via WhatsApp com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Telefone invalido ou falha no envio' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_j = typeof send_phone_otp_dto_1.SendPhoneOtpDto !== "undefined" && send_phone_otp_dto_1.SendPhoneOtpDto) === "function" ? _j : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "sendOtpWhatsApp", null);
__decorate([
    (0, common_1.Post)('verify-otp-login'),
    (0, throttler_1.Throttle)({ default: { limit: 10, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Verificar OTP e fazer login',
        description: 'Valida o codigo OTP, busca usuario pelo telefone no Firestore e retorna status + JWT token para login'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'OTP verificado e status do usuario retornado' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Codigo invalido, expirado ou telefone invalido' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_k = typeof send_phone_otp_dto_1.VerifyPhoneOtpDto !== "undefined" && send_phone_otp_dto_1.VerifyPhoneOtpDto) === "function" ? _k : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "verifyOtpLogin", null);
__decorate([
    (0, common_1.Post)('check-user-status'),
    (0, throttler_1.Throttle)({ default: { limit: 10, ttl: 60000 } }),
    (0, swagger_1.ApiOperation)({
        summary: 'Verificar status do usuario apos autenticacao',
        description: 'Verifica o JWT token, busca o usuario no Firestore e retorna o status (LOGGED_IN ou REGISTER)'
    }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'Status do usuario retornado com sucesso' }),
    (0, swagger_1.ApiResponse)({ status: 400, description: 'Token invalido' }),
    (0, swagger_1.ApiResponse)({ status: 401, description: 'Token nao autorizado' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_l = typeof send_phone_otp_dto_1.CheckUserStatusDto !== "undefined" && send_phone_otp_dto_1.CheckUserStatusDto) === "function" ? _l : Object]),
    __metadata("design:returntype", Promise)
], AuthController.prototype, "checkUserStatus", null);
exports.AuthController = AuthController = __decorate([
    (0, swagger_1.ApiTags)('Auth'),
    (0, common_1.Controller)('api/auth'),
    (0, common_1.UseGuards)(api_key_guard_1.ApiKeyGuard),
    (0, swagger_1.ApiSecurity)('api-key'),
    __metadata("design:paramtypes", [typeof (_a = typeof email_sender_service_1.EmailSenderService !== "undefined" && email_sender_service_1.EmailSenderService) === "function" ? _a : Object, typeof (_b = typeof simple_otp_service_1.SimpleOtpService !== "undefined" && simple_otp_service_1.SimpleOtpService) === "function" ? _b : Object, typeof (_c = typeof whatsapp_service_1.WhatsAppService !== "undefined" && whatsapp_service_1.WhatsAppService) === "function" ? _c : Object, typeof (_d = typeof users_service_1.UsersService !== "undefined" && users_service_1.UsersService) === "function" ? _d : Object, typeof (_e = typeof auth_jwt_service_1.AuthJwtService !== "undefined" && auth_jwt_service_1.AuthJwtService) === "function" ? _e : Object])
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
const simple_otp_service_1 = __webpack_require__(/*! ./services/simple-otp.service */ "./src/auth/services/simple-otp.service.ts");
const whatsapp_service_1 = __webpack_require__(/*! ./services/whatsapp.service */ "./src/auth/services/whatsapp.service.ts");
const auth_controller_1 = __webpack_require__(/*! ./auth.controller */ "./src/auth/auth.controller.ts");
const whatsapp_webhook_controller_1 = __webpack_require__(/*! ./whatsapp-webhook.controller */ "./src/auth/whatsapp-webhook.controller.ts");
const users_module_1 = __webpack_require__(/*! ../users/users.module */ "./src/users/users.module.ts");
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

/***/ "./src/auth/dto/send-phone-otp.dto.ts":
/*!********************************************!*\
  !*** ./src/auth/dto/send-phone-otp.dto.ts ***!
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
exports.CheckUserStatusDto = exports.VerifyPhoneOtpDto = exports.SendPhoneOtpDto = void 0;
const swagger_1 = __webpack_require__(/*! @nestjs/swagger */ "@nestjs/swagger");
const class_validator_1 = __webpack_require__(/*! class-validator */ "class-validator");
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
var _a, _b;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.EmailTemplateService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
const auth_jwt_service_1 = __webpack_require__(/*! ../firebase-rest/auth-jwt.service */ "./src/firebase-rest/auth-jwt.service.ts");
const fs = __webpack_require__(/*! fs */ "fs");
const path = __webpack_require__(/*! path */ "path");
let EmailTemplateService = class EmailTemplateService {
    constructor(configService, authJwt) {
        this.configService = configService;
        this.authJwt = authJwt;
    }
    async generatePasswordResetLink(email, actionCodeSettings) {
        await this.authJwt.sendPasswordResetEmail(email);
        return `https://pagpagbrasil.com.br/reset?email=${encodeURIComponent(email)}`;
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
    __metadata("design:paramtypes", [typeof (_a = typeof config_1.ConfigService !== "undefined" && config_1.ConfigService) === "function" ? _a : Object, typeof (_b = typeof auth_jwt_service_1.AuthJwtService !== "undefined" && auth_jwt_service_1.AuthJwtService) === "function" ? _b : Object])
], EmailTemplateService);


/***/ }),

/***/ "./src/auth/services/simple-otp.service.ts":
/*!*************************************************!*\
  !*** ./src/auth/services/simple-otp.service.ts ***!
  \*************************************************/
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
exports.SimpleOtpService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const firestore_rest_service_1 = __webpack_require__(/*! ../../firebase-rest/firestore-rest.service */ "./src/firebase-rest/firestore-rest.service.ts");
const firestore_rest_utils_1 = __webpack_require__(/*! ../../firebase-rest/firestore-rest.utils */ "./src/firebase-rest/firestore-rest.utils.ts");
let SimpleOtpService = class SimpleOtpService {
    constructor(firestore) {
        this.firestore = firestore;
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
                    message: 'Numero de telefone invalido',
                };
            }
            const code = this.generateOtpCode();
            const expiresAt = new Date();
            expiresAt.setMinutes(expiresAt.getMinutes() + this.otpExpirationMinutes);
            const otpDoc = {
                phone: normalizedPhone,
                code,
                expiresAt,
                attempts: 0,
                verified: false,
                createdAt: (0, firestore_rest_utils_1.serverTimestamp)(),
            };
            const tQuery = Date.now();
            const oldOtps = await this.firestore.query(this.otpCollection, {
                where: [{ field: 'phone', op: 'EQUAL', value: normalizedPhone }],
            });
            console.log(`[OTP-TIMING]   query OTPs antigos: ${Date.now() - tQuery}ms (found: ${oldOtps.length})`);
            const tWrite = Date.now();
            if (oldOtps.length > 0) {
                const paths = oldOtps.map((doc) => `${this.otpCollection}/${doc.id}`);
                await this.firestore.batchDelete(paths);
            }
            await this.firestore.addDocument(this.otpCollection, otpDoc);
            console.log(`[OTP-TIMING]   delete+add: ${Date.now() - tWrite}ms`);
            return {
                success: true,
                code,
                message: `Codigo OTP gerado. Para testes, use: ${code}`,
            };
        }
        catch (error) {
            const code = error?.code || error?.response?.status;
            const msg = error?.message ?? String(error);
            const responseData = error?.response?.data ? JSON.stringify(error.response.data) : '';
            console.error('Erro ao enviar OTP:', { code, msg, responseData });
            const fullError = `${msg} ${responseData}`;
            const permissionDenied = code === 403 ||
                code === 7 ||
                code === 'PERMISSION_DENIED' ||
                fullError.includes('PERMISSION_DENIED') ||
                fullError.includes('Missing or insufficient permissions');
            const unavailable = code === 14 ||
                code === 'UNAVAILABLE' ||
                fullError.includes('UNAVAILABLE');
            const userMessage = `Erro OTP [${code}]: ${msg} | ${responseData}`;
            return {
                success: false,
                message: userMessage,
            };
        }
    }
    async verifyOtp(phone, code) {
        try {
            const normalizedPhone = phone.replace(/\D/g, '');
            const otpResults = await this.firestore.query(this.otpCollection, {
                where: [
                    { field: 'phone', op: 'EQUAL', value: normalizedPhone },
                    { field: 'verified', op: 'EQUAL', value: false },
                ],
                orderBy: 'createdAt',
                orderDirection: 'DESCENDING',
                limit: 1,
            });
            if (otpResults.length === 0) {
                return {
                    success: false,
                    message: 'Codigo OTP nao encontrado ou ja utilizado',
                };
            }
            const otpDoc = otpResults[0];
            const otpData = otpDoc.data;
            const expiresAt = otpData.expiresAt instanceof Date
                ? otpData.expiresAt
                : new Date(otpData.expiresAt);
            if (new Date() > expiresAt) {
                await this.firestore.deleteDocument(this.otpCollection, otpDoc.id);
                return {
                    success: false,
                    message: 'Codigo OTP expirado. Solicite um novo codigo.',
                };
            }
            if (otpData.attempts >= this.maxAttempts) {
                await this.firestore.deleteDocument(this.otpCollection, otpDoc.id);
                return {
                    success: false,
                    message: 'Numero maximo de tentativas excedido. Solicite um novo codigo.',
                };
            }
            if (otpData.code !== code) {
                await this.firestore.updateDocument(this.otpCollection, otpDoc.id, {
                    attempts: (0, firestore_rest_utils_1.fieldIncrement)(1),
                });
                const remainingAttempts = this.maxAttempts - otpData.attempts - 1;
                return {
                    success: false,
                    message: `Codigo incorreto. Tentativas restantes: ${remainingAttempts}`,
                };
            }
            await this.firestore.updateDocument(this.otpCollection, otpDoc.id, {
                verified: true,
            });
            return {
                success: true,
                message: 'Codigo OTP verificado com sucesso',
            };
        }
        catch (error) {
            console.error('Erro ao verificar OTP:', error);
            return {
                success: false,
                message: 'Erro ao verificar codigo OTP',
            };
        }
    }
    async cleanupExpiredOtps() {
        try {
            const now = new Date();
            const expiredOtps = await this.firestore.query(this.otpCollection, {
                where: [{ field: 'expiresAt', op: 'LESS_THAN', value: now }],
            });
            if (expiredOtps.length > 0) {
                const paths = expiredOtps.map((doc) => `${this.otpCollection}/${doc.id}`);
                await this.firestore.batchDelete(paths);
            }
            console.log(`Limpeza: ${expiredOtps.length} OTPs expirados removidos`);
        }
        catch (error) {
            console.error('Erro ao limpar OTPs expirados:', error);
        }
    }
};
exports.SimpleOtpService = SimpleOtpService;
exports.SimpleOtpService = SimpleOtpService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof firestore_rest_service_1.FirestoreRestService !== "undefined" && firestore_rest_service_1.FirestoreRestService) === "function" ? _a : Object])
], SimpleOtpService);


/***/ }),

/***/ "./src/auth/services/whatsapp.service.ts":
/*!***********************************************!*\
  !*** ./src/auth/services/whatsapp.service.ts ***!
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
var WhatsAppService_1;
var _a;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.WhatsAppService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
const Twilio = __webpack_require__(/*! twilio */ "twilio");
let WhatsAppService = WhatsAppService_1 = class WhatsAppService {
    constructor(configService) {
        this.configService = configService;
        this.logger = new common_1.Logger(WhatsAppService_1.name);
        const accountSid = this.configService.get('TWILIO_ACCOUNT_SID', '');
        const authToken = this.configService.get('TWILIO_AUTH_TOKEN', '');
        this.fromNumber = this.configService.get('TWILIO_WHATSAPP_FROM', '');
        this.otpContentSid = this.configService.get('TWILIO_OTP_CONTENT_SID', 'HXc63e56630589f6a10de0d304c0ee09f1');
        this.client = Twilio(accountSid, authToken);
        this.logger.log(`WhatsApp service initialized (Twilio, from: ${this.fromNumber}, otpTemplate: ${this.otpContentSid})`);
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
                from: `whatsapp:${this.fromNumber}`,
                to: this.formatPhone(cleanPhone),
                contentSid: this.otpContentSid,
                contentVariables: JSON.stringify({ '1': code }),
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

/***/ "./src/auth/whatsapp-webhook.controller.ts":
/*!*************************************************!*\
  !*** ./src/auth/whatsapp-webhook.controller.ts ***!
  \*************************************************/
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
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const whatsapp_service_1 = __webpack_require__(/*! ./services/whatsapp.service */ "./src/auth/services/whatsapp.service.ts");
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

/***/ "./src/efi/dto/send-pix.dto.ts":
/*!*************************************!*\
  !*** ./src/efi/dto/send-pix.dto.ts ***!
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
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.SendPixDto = exports.DadosBancariosDto = void 0;
const class_validator_1 = __webpack_require__(/*! class-validator */ "class-validator");
const class_transformer_1 = __webpack_require__(/*! class-transformer */ "class-transformer");
class DadosBancariosDto {
}
exports.DadosBancariosDto = DadosBancariosDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], DadosBancariosDto.prototype, "banco", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], DadosBancariosDto.prototype, "agencia", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], DadosBancariosDto.prototype, "conta", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], DadosBancariosDto.prototype, "cpfCnpj", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], DadosBancariosDto.prototype, "nome", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], DadosBancariosDto.prototype, "tipoConta", void 0);
class SendPixDto {
}
exports.SendPixDto = SendPixDto;
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], SendPixDto.prototype, "valor", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], SendPixDto.prototype, "pagadorChave", void 0);
__decorate([
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.MaxLength)(140),
    __metadata("design:type", String)
], SendPixDto.prototype, "descricao", void 0);
__decorate([
    (0, class_validator_1.ValidateIf)((o) => !o.pixCopiaECola && !o.dadosBancarios),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], SendPixDto.prototype, "chave", void 0);
__decorate([
    (0, class_validator_1.ValidateIf)((o) => !o.chave && !o.dadosBancarios),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsNotEmpty)(),
    __metadata("design:type", String)
], SendPixDto.prototype, "pixCopiaECola", void 0);
__decorate([
    (0, class_validator_1.ValidateIf)((o) => !o.chave && !o.pixCopiaECola),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.ValidateNested)(),
    (0, class_transformer_1.Type)(() => DadosBancariosDto),
    __metadata("design:type", DadosBancariosDto)
], SendPixDto.prototype, "dadosBancarios", void 0);


/***/ }),

/***/ "./src/efi/efi-auth.service.ts":
/*!*************************************!*\
  !*** ./src/efi/efi-auth.service.ts ***!
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
var EfiAuthService_1;
var _a;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.EfiAuthService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const axios_1 = __webpack_require__(/*! axios */ "axios");
const https = __webpack_require__(/*! https */ "https");
const efi_config_service_1 = __webpack_require__(/*! ./efi-config.service */ "./src/efi/efi-config.service.ts");
let EfiAuthService = EfiAuthService_1 = class EfiAuthService {
    constructor(config) {
        this.config = config;
        this.logger = new common_1.Logger(EfiAuthService_1.name);
        this.cachedToken = null;
        this.cachedExpiresAt = 0;
    }
    async getAccessToken() {
        const now = Date.now();
        const buffer = 10_000;
        if (this.cachedToken && this.cachedExpiresAt - buffer > now) {
            return this.cachedToken;
        }
        return this.fetchNewToken();
    }
    buildHttpClient() {
        const httpsAgent = new https.Agent({
            pfx: this.config.certBuffer,
            passphrase: this.config.certPassphrase || '',
        });
        return axios_1.default.create({
            baseURL: this.config.baseUrl,
            httpsAgent,
            timeout: 15_000,
            validateStatus: () => true,
        });
    }
    async fetchNewToken() {
        const client = this.buildHttpClient();
        const basicAuth = Buffer.from(`${this.config.clientId}:${this.config.clientSecret}`).toString('base64');
        this.logger.debug(`Solicitando novo token Efí (ambiente=${this.config.ambiente})`);
        const response = await client.post('/oauth/token', { grant_type: 'client_credentials' }, {
            headers: {
                Authorization: `Basic ${basicAuth}`,
                'Content-Type': 'application/json',
            },
        });
        if (response.status !== 200) {
            this.logger.error(`Falha ao obter token Efí: status=${response.status} body=${JSON.stringify(response.data)}`);
            throw new common_1.InternalServerErrorException(`Efí auth falhou: ${response.status}`);
        }
        const { access_token, expires_in } = response.data;
        this.cachedToken = access_token;
        this.cachedExpiresAt = Date.now() + expires_in * 1000;
        this.logger.log(`Token Efí obtido. Expira em ${expires_in}s (${new Date(this.cachedExpiresAt).toISOString()}).`);
        return access_token;
    }
};
exports.EfiAuthService = EfiAuthService;
exports.EfiAuthService = EfiAuthService = EfiAuthService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof efi_config_service_1.EfiConfigService !== "undefined" && efi_config_service_1.EfiConfigService) === "function" ? _a : Object])
], EfiAuthService);


/***/ }),

/***/ "./src/efi/efi-config.service.ts":
/*!***************************************!*\
  !*** ./src/efi/efi-config.service.ts ***!
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
var EfiConfigService_1;
var _a;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.EfiConfigService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
const fs = __webpack_require__(/*! fs */ "fs");
const path = __webpack_require__(/*! path */ "path");
let EfiConfigService = EfiConfigService_1 = class EfiConfigService {
    constructor(configService) {
        this.configService = configService;
        this.logger = new common_1.Logger(EfiConfigService_1.name);
    }
    onModuleInit() {
        this._ambiente =
            this.configService.get('EFI_AMBIENTE') || 'homologacao';
        this._baseUrl =
            this._ambiente === 'producao'
                ? 'https://pix.api.efipay.com.br'
                : 'https://pix-h.api.efipay.com.br';
        this._clientId = this.configService.get('EFI_CLIENT_ID', '');
        this._clientSecret = this.configService.get('EFI_CLIENT_SECRET', '');
        this._certPassphrase = this.configService.get('EFI_CERT_PASSPHRASE', '');
        this._certBuffer = this.loadCertBuffer();
        if (!this._clientId || !this._clientSecret) {
            this.logger.warn('EFI_CLIENT_ID ou EFI_CLIENT_SECRET não configurados — chamadas falharão.');
        }
        this.logger.log(`Efí configurada: ambiente=${this._ambiente}, baseUrl=${this._baseUrl}, certBytes=${this._certBuffer?.length ?? 0}`);
    }
    loadCertBuffer() {
        const base64 = this.configService.get('EFI_CERT_BASE64');
        if (base64) {
            this.logger.debug('Certificado Efí carregado via EFI_CERT_BASE64');
            return Buffer.from(base64, 'base64');
        }
        const certPath = this.configService.get('EFI_CERT_PATH');
        if (certPath) {
            const resolved = path.isAbsolute(certPath)
                ? certPath
                : path.resolve(process.cwd(), certPath);
            if (!fs.existsSync(resolved)) {
                this.logger.error(`Certificado não encontrado em: ${resolved}`);
                return Buffer.alloc(0);
            }
            this.logger.debug(`Certificado Efí carregado de: ${resolved}`);
            return fs.readFileSync(resolved);
        }
        this.logger.warn('Nenhum certificado configurado (EFI_CERT_BASE64 ou EFI_CERT_PATH).');
        return Buffer.alloc(0);
    }
    get ambiente() {
        return this._ambiente;
    }
    get baseUrl() {
        return this._baseUrl;
    }
    get clientId() {
        return this._clientId;
    }
    get clientSecret() {
        return this._clientSecret;
    }
    get certBuffer() {
        return this._certBuffer;
    }
    get certPassphrase() {
        return this._certPassphrase;
    }
};
exports.EfiConfigService = EfiConfigService;
exports.EfiConfigService = EfiConfigService = EfiConfigService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof config_1.ConfigService !== "undefined" && config_1.ConfigService) === "function" ? _a : Object])
], EfiConfigService);


/***/ }),

/***/ "./src/efi/efi-pix.service.ts":
/*!************************************!*\
  !*** ./src/efi/efi-pix.service.ts ***!
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
var EfiPixService_1;
var _a;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.EfiPixService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const crypto_1 = __webpack_require__(/*! crypto */ "crypto");
const efi_auth_service_1 = __webpack_require__(/*! ./efi-auth.service */ "./src/efi/efi-auth.service.ts");
let EfiPixService = EfiPixService_1 = class EfiPixService {
    constructor(auth) {
        this.auth = auth;
        this.logger = new common_1.Logger(EfiPixService_1.name);
    }
    async sendPix(dto, idEnvio) {
        const token = await this.auth.getAccessToken();
        const client = this.auth.buildHttpClient();
        const id = idEnvio ?? this.generateIdEnvio();
        const modalidade = this.detectModalidade(dto);
        const body = this.buildSendPixBody(dto);
        const url = this.buildEndpointUrl(modalidade, id);
        this.logger.log(`Enviando PIX idEnvio=${id} valor=${dto.valor} modalidade=${modalidade} endpoint=${url}`);
        const response = await client.put(url, body, {
            headers: {
                Authorization: `Bearer ${token}`,
                'Content-Type': 'application/json',
            },
        });
        if (response.status >= 200 && response.status < 300) {
            this.logger.log(`PIX agendado: idEnvio=${id} e2eId=${response.data?.e2eId} status=${response.data?.status}`);
            return {
                idEnvio: id,
                e2eId: response.data?.e2eId,
                status: response.data?.status,
                valor: response.data?.valor,
                horario: response.data?.horario,
            };
        }
        this.logger.error(`Falha ao enviar PIX: status=${response.status} body=${JSON.stringify(response.data)}`);
        throw new common_1.HttpException({
            message: 'Falha no envio do PIX via Efí',
            efiStatus: response.status,
            efiBody: response.data,
        }, common_1.HttpStatus.BAD_GATEWAY);
    }
    async getPixStatus(idEnvio) {
        const token = await this.auth.getAccessToken();
        const client = this.auth.buildHttpClient();
        const response = await client.get(`/v3/gn/pix/enviados/${idEnvio}`, {
            headers: { Authorization: `Bearer ${token}` },
        });
        if (response.status >= 200 && response.status < 300) {
            return response.data;
        }
        throw new common_1.HttpException({
            message: 'Falha ao consultar PIX',
            efiStatus: response.status,
            efiBody: response.data,
        }, common_1.HttpStatus.BAD_GATEWAY);
    }
    async registerWebhook(chave, webhookUrl) {
        const token = await this.auth.getAccessToken();
        const client = this.auth.buildHttpClient();
        this.logger.log(`Registrando webhook na chave ${chave.substring(0, 8)}*** → ${webhookUrl}`);
        const response = await client.put(`/v2/webhook/${encodeURIComponent(chave)}`, { webhookUrl }, {
            headers: {
                Authorization: `Bearer ${token}`,
                'Content-Type': 'application/json',
                'x-skip-mtls-checking': 'true',
            },
        });
        if (response.status >= 200 && response.status < 300) {
            this.logger.log(`Webhook registrado com sucesso na chave ${chave.substring(0, 8)}***`);
            return response.data ?? { ok: true };
        }
        throw new common_1.HttpException({
            message: 'Falha ao registrar webhook',
            efiStatus: response.status,
            efiBody: response.data,
        }, common_1.HttpStatus.BAD_GATEWAY);
    }
    async getWebhook(chave) {
        const token = await this.auth.getAccessToken();
        const client = this.auth.buildHttpClient();
        const response = await client.get(`/v2/webhook/${encodeURIComponent(chave)}`, { headers: { Authorization: `Bearer ${token}` } });
        if (response.status >= 200 && response.status < 300) {
            return response.data;
        }
        if (response.status === 404) {
            return { configured: false };
        }
        throw new common_1.HttpException({
            message: 'Falha ao consultar webhook',
            efiStatus: response.status,
            efiBody: response.data,
        }, common_1.HttpStatus.BAD_GATEWAY);
    }
    async getBalance() {
        const token = await this.auth.getAccessToken();
        const client = this.auth.buildHttpClient();
        const response = await client.get('/v2/gn/saldo', {
            headers: { Authorization: `Bearer ${token}` },
        });
        if (response.status >= 200 && response.status < 300) {
            return response.data;
        }
        throw new common_1.HttpException({
            message: 'Falha ao consultar saldo',
            efiStatus: response.status,
            efiBody: response.data,
        }, common_1.HttpStatus.BAD_GATEWAY);
    }
    generateIdEnvio() {
        return (0, crypto_1.randomUUID)().replace(/-/g, '');
    }
    detectModalidade(dto) {
        if (dto.chave)
            return 'chave';
        if (dto.pixCopiaECola)
            return 'copiaECola';
        return 'dadosBancarios';
    }
    buildEndpointUrl(modalidade, idEnvio) {
        if (modalidade === 'copiaECola') {
            return `/v2/gn/pix/${idEnvio}/qrcode`;
        }
        return `/v3/gn/pix/${idEnvio}`;
    }
    buildSendPixBody(dto) {
        const pagadorChave = dto.pagadorChave || process.env.EFI_PAGADOR_CHAVE;
        const pagador = {};
        if (pagadorChave) {
            pagador.chave = pagadorChave;
        }
        if (dto.descricao) {
            pagador.infoPagador = dto.descricao;
        }
        if (dto.pixCopiaECola) {
            return {
                valor: dto.valor,
                pagador,
                pixCopiaECola: dto.pixCopiaECola,
            };
        }
        const base = {
            valor: dto.valor,
            pagador,
        };
        if (dto.chave) {
            base.favorecido = { chave: dto.chave };
        }
        else if (dto.dadosBancarios) {
            base.favorecido = {
                contaBanco: {
                    nome: dto.dadosBancarios.nome,
                    cpf: dto.dadosBancarios.cpfCnpj,
                    codigoBanco: dto.dadosBancarios.banco,
                    agencia: dto.dadosBancarios.agencia,
                    conta: dto.dadosBancarios.conta,
                    tipoConta: dto.dadosBancarios.tipoConta || 'cacc',
                },
            };
        }
        return base;
    }
};
exports.EfiPixService = EfiPixService;
exports.EfiPixService = EfiPixService = EfiPixService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof efi_auth_service_1.EfiAuthService !== "undefined" && efi_auth_service_1.EfiAuthService) === "function" ? _a : Object])
], EfiPixService);


/***/ }),

/***/ "./src/efi/efi-test.controller.ts":
/*!****************************************!*\
  !*** ./src/efi/efi-test.controller.ts ***!
  \****************************************/
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
exports.EfiTestController = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const api_key_guard_1 = __webpack_require__(/*! ../common/guards/api-key.guard */ "./src/common/guards/api-key.guard.ts");
const efi_pix_service_1 = __webpack_require__(/*! ./efi-pix.service */ "./src/efi/efi-pix.service.ts");
const efi_auth_service_1 = __webpack_require__(/*! ./efi-auth.service */ "./src/efi/efi-auth.service.ts");
const efi_config_service_1 = __webpack_require__(/*! ./efi-config.service */ "./src/efi/efi-config.service.ts");
const send_pix_dto_1 = __webpack_require__(/*! ./dto/send-pix.dto */ "./src/efi/dto/send-pix.dto.ts");
let EfiTestController = class EfiTestController {
    constructor(pix, auth, config) {
        this.pix = pix;
        this.auth = auth;
        this.config = config;
    }
    async testAuth() {
        const token = await this.auth.getAccessToken();
        return {
            ok: true,
            ambiente: this.config.ambiente,
            baseUrl: this.config.baseUrl,
            tokenPrefix: token.substring(0, 12) + '...',
        };
    }
    async balance() {
        return this.pix.getBalance();
    }
    async sendPix(dto) {
        return this.pix.sendPix(dto);
    }
    async getPixStatus(idEnvio) {
        return this.pix.getPixStatus(idEnvio);
    }
    async getWebhook(chave) {
        return this.pix.getWebhook(chave);
    }
    async registerWebhook(body) {
        return this.pix.registerWebhook(body.chave, body.webhookUrl);
    }
};
exports.EfiTestController = EfiTestController;
__decorate([
    (0, common_1.Get)('auth'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], EfiTestController.prototype, "testAuth", null);
__decorate([
    (0, common_1.Get)('balance'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], EfiTestController.prototype, "balance", null);
__decorate([
    (0, common_1.Post)('pix'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [typeof (_d = typeof send_pix_dto_1.SendPixDto !== "undefined" && send_pix_dto_1.SendPixDto) === "function" ? _d : Object]),
    __metadata("design:returntype", Promise)
], EfiTestController.prototype, "sendPix", null);
__decorate([
    (0, common_1.Get)('pix/:idEnvio'),
    __param(0, (0, common_1.Param)('idEnvio')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], EfiTestController.prototype, "getPixStatus", null);
__decorate([
    (0, common_1.Get)('webhook/:chave'),
    __param(0, (0, common_1.Param)('chave')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], EfiTestController.prototype, "getWebhook", null);
__decorate([
    (0, common_1.Post)('webhook'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", Promise)
], EfiTestController.prototype, "registerWebhook", null);
exports.EfiTestController = EfiTestController = __decorate([
    (0, common_1.Controller)('api/_internal/efi/test'),
    (0, common_1.UseGuards)(api_key_guard_1.ApiKeyGuard),
    __metadata("design:paramtypes", [typeof (_a = typeof efi_pix_service_1.EfiPixService !== "undefined" && efi_pix_service_1.EfiPixService) === "function" ? _a : Object, typeof (_b = typeof efi_auth_service_1.EfiAuthService !== "undefined" && efi_auth_service_1.EfiAuthService) === "function" ? _b : Object, typeof (_c = typeof efi_config_service_1.EfiConfigService !== "undefined" && efi_config_service_1.EfiConfigService) === "function" ? _c : Object])
], EfiTestController);


/***/ }),

/***/ "./src/efi/efi.module.ts":
/*!*******************************!*\
  !*** ./src/efi/efi.module.ts ***!
  \*******************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.EfiModule = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const efi_config_service_1 = __webpack_require__(/*! ./efi-config.service */ "./src/efi/efi-config.service.ts");
const efi_auth_service_1 = __webpack_require__(/*! ./efi-auth.service */ "./src/efi/efi-auth.service.ts");
const efi_pix_service_1 = __webpack_require__(/*! ./efi-pix.service */ "./src/efi/efi-pix.service.ts");
const efi_test_controller_1 = __webpack_require__(/*! ./efi-test.controller */ "./src/efi/efi-test.controller.ts");
let EfiModule = class EfiModule {
};
exports.EfiModule = EfiModule;
exports.EfiModule = EfiModule = __decorate([
    (0, common_1.Module)({
        controllers: [efi_test_controller_1.EfiTestController],
        providers: [efi_config_service_1.EfiConfigService, efi_auth_service_1.EfiAuthService, efi_pix_service_1.EfiPixService],
        exports: [efi_pix_service_1.EfiPixService, efi_auth_service_1.EfiAuthService, efi_config_service_1.EfiConfigService],
    })
], EfiModule);


/***/ }),

/***/ "./src/firebase-rest/auth-jwt.service.ts":
/*!***********************************************!*\
  !*** ./src/firebase-rest/auth-jwt.service.ts ***!
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
var AuthJwtService_1;
var _a;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.AuthJwtService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
const jwt = __webpack_require__(/*! jsonwebtoken */ "jsonwebtoken");
const axios_1 = __webpack_require__(/*! axios */ "axios");
let AuthJwtService = AuthJwtService_1 = class AuthJwtService {
    constructor(configService) {
        this.configService = configService;
        this.logger = new common_1.Logger(AuthJwtService_1.name);
        this.jwtSecret = this.configService.get('JWT_SECRET', '');
        this.jwtExpiresIn = this.configService.get('JWT_EXPIRES_IN', '7d');
        this.apiKey = this.configService.get('FIREBASE_WEB_API_KEY', '');
        this.projectId = this.configService.get('FIREBASE_PROJECT_ID', 'pagpagapp');
        if (!this.jwtSecret) {
            this.logger.warn('JWT_SECRET not set! Token signing will fail.');
        }
        this.logger.log('AuthJwtService initialized');
    }
    signToken(payload) {
        return jwt.sign(payload, this.jwtSecret, {
            expiresIn: this.jwtExpiresIn,
            issuer: 'neves-capital-api',
            audience: 'pagpag-app',
        });
    }
    verifyToken(token) {
        try {
            return jwt.verify(token, this.jwtSecret, {
                issuer: 'neves-capital-api',
                audience: 'pagpag-app',
            });
        }
        catch (error) {
            this.logger.error(`JWT verification failed: ${error.message}`);
            throw new Error(`Token inválido: ${error.message}`);
        }
    }
    async sendPasswordResetEmail(email) {
        try {
            const res = await axios_1.default.post(`https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=${this.apiKey}`, {
                requestType: 'PASSWORD_RESET',
                email,
            });
            this.logger.log(`Password reset email sent to ${email}`);
            return res.data.email;
        }
        catch (error) {
            const msg = error.response?.data?.error?.message || error.message;
            this.logger.error(`Failed to send password reset: ${msg}`);
            throw new Error(`Falha ao enviar reset de senha: ${msg}`);
        }
    }
    async lookupUserByEmail(email) {
        try {
            const res = await axios_1.default.post(`https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${this.apiKey}`, { email: [email] });
            const users = res.data.users;
            return users && users.length > 0 ? users[0] : null;
        }
        catch (error) {
            if (error.response?.data?.error?.message === 'USER_NOT_FOUND') {
                return null;
            }
            throw error;
        }
    }
};
exports.AuthJwtService = AuthJwtService;
exports.AuthJwtService = AuthJwtService = AuthJwtService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof config_1.ConfigService !== "undefined" && config_1.ConfigService) === "function" ? _a : Object])
], AuthJwtService);


/***/ }),

/***/ "./src/firebase-rest/firebase-rest.module.ts":
/*!***************************************************!*\
  !*** ./src/firebase-rest/firebase-rest.module.ts ***!
  \***************************************************/
/***/ (function(__unused_webpack_module, exports, __webpack_require__) {


var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.FirebaseRestModule = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
const firestore_rest_service_1 = __webpack_require__(/*! ./firestore-rest.service */ "./src/firebase-rest/firestore-rest.service.ts");
const auth_jwt_service_1 = __webpack_require__(/*! ./auth-jwt.service */ "./src/firebase-rest/auth-jwt.service.ts");
const storage_rest_service_1 = __webpack_require__(/*! ./storage-rest.service */ "./src/firebase-rest/storage-rest.service.ts");
let FirebaseRestModule = class FirebaseRestModule {
};
exports.FirebaseRestModule = FirebaseRestModule;
exports.FirebaseRestModule = FirebaseRestModule = __decorate([
    (0, common_1.Global)(),
    (0, common_1.Module)({
        imports: [config_1.ConfigModule],
        providers: [firestore_rest_service_1.FirestoreRestService, auth_jwt_service_1.AuthJwtService, storage_rest_service_1.StorageRestService],
        exports: [firestore_rest_service_1.FirestoreRestService, auth_jwt_service_1.AuthJwtService, storage_rest_service_1.StorageRestService],
    })
], FirebaseRestModule);


/***/ }),

/***/ "./src/firebase-rest/firestore-rest.service.ts":
/*!*****************************************************!*\
  !*** ./src/firebase-rest/firestore-rest.service.ts ***!
  \*****************************************************/
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
var FirestoreRestService_1;
var _a;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.FirestoreRestService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
const axios_1 = __webpack_require__(/*! axios */ "axios");
const firestore_rest_utils_1 = __webpack_require__(/*! ./firestore-rest.utils */ "./src/firebase-rest/firestore-rest.utils.ts");
let FirestoreRestService = FirestoreRestService_1 = class FirestoreRestService {
    constructor(configService) {
        this.configService = configService;
        this.logger = new common_1.Logger(FirestoreRestService_1.name);
        this.projectId = this.configService.get('FIREBASE_PROJECT_ID', 'pagpagapp');
        const apiKey = this.configService.get('FIREBASE_WEB_API_KEY', '');
        this.baseUrl = `https://firestore.googleapis.com/v1/projects/${this.projectId}/databases/(default)/documents`;
        this.http = axios_1.default.create({
            baseURL: this.baseUrl,
            params: apiKey ? { key: apiKey } : {},
            headers: { 'Content-Type': 'application/json' },
            timeout: 15000,
        });
        this.logger.log(`FirestoreRestService initialized (project: ${this.projectId})`);
    }
    async getDocument(collection, docId) {
        try {
            const res = await this.http.get(`/${collection}/${docId}`);
            if (!res.data.fields)
                return null;
            return {
                id: (0, firestore_rest_utils_1.extractDocId)(res.data.name),
                data: (0, firestore_rest_utils_1.decodeFields)(res.data.fields),
                ref: { path: `${collection}/${docId}` },
            };
        }
        catch (error) {
            if (error.response?.status === 404)
                return null;
            this.logger.error(`getDocument(${collection}/${docId}) failed: ${error.message}`);
            throw error;
        }
    }
    async addDocument(collection, data) {
        const { fields, transforms } = this.separateTransforms(collection, '', data);
        if (transforms.length > 0) {
            const res = await this.http.post(`/${collection}`, { fields });
            const docId = (0, firestore_rest_utils_1.extractDocId)(res.data.name);
            await this.commitWrites([
                {
                    transform: {
                        document: `projects/${this.projectId}/databases/(default)/documents/${collection}/${docId}`,
                        fieldTransforms: transforms,
                    },
                },
            ]);
            return {
                id: docId,
                data: { ...data, id: docId },
                ref: { path: `${collection}/${docId}` },
            };
        }
        const res = await this.http.post(`/${collection}`, { fields });
        const docId = (0, firestore_rest_utils_1.extractDocId)(res.data.name);
        return {
            id: docId,
            data: { ...data, id: docId },
            ref: { path: `${collection}/${docId}` },
        };
    }
    async setDocument(collection, docId, data, merge = false) {
        const { fields, transforms } = this.separateTransforms(collection, docId, data);
        if (transforms.length > 0) {
            await this.commitWrites([
                {
                    update: {
                        name: `projects/${this.projectId}/databases/(default)/documents/${collection}/${docId}`,
                        fields,
                    },
                    updateTransforms: transforms,
                },
            ]);
        }
        else {
            const params = {};
            if (merge) {
                Object.keys(data).forEach((key, i) => {
                    params[`updateMask.fieldPaths`] = params[`updateMask.fieldPaths`]
                        ? [...(Array.isArray(params[`updateMask.fieldPaths`]) ? params[`updateMask.fieldPaths`] : [params[`updateMask.fieldPaths`]]), key]
                        : key;
                });
            }
            await this.http.patch(`/${collection}/${docId}`, { fields }, { params });
        }
    }
    async updateDocument(collection, docId, data) {
        const { fields, transforms } = this.separateTransforms(collection, docId, data);
        const fieldPaths = Object.keys(fields);
        if (transforms.length > 0) {
            const write = {
                update: {
                    name: `projects/${this.projectId}/databases/(default)/documents/${collection}/${docId}`,
                    fields,
                },
                updateMask: { fieldPaths },
                updateTransforms: transforms,
            };
            await this.commitWrites([write]);
        }
        else {
            const updateMask = fieldPaths.map((f) => `updateMask.fieldPaths=${f}`).join('&');
            await this.http.patch(`/${collection}/${docId}?${updateMask}`, { fields });
        }
    }
    async deleteDocument(collection, docId) {
        try {
            await this.http.delete(`/${collection}/${docId}`);
        }
        catch (error) {
            if (error.response?.status === 404)
                return;
            throw error;
        }
    }
    async query(collection, options = {}) {
        const structuredQuery = {
            from: [{ collectionId: collection }],
        };
        if (options.where && options.where.length > 0) {
            const filters = options.where.map((w) => ({
                fieldFilter: {
                    field: { fieldPath: w.field },
                    op: this.mapOperator(w.op),
                    value: (0, firestore_rest_utils_1.encodeValue)(w.value),
                },
            }));
            if (filters.length === 1) {
                structuredQuery.where = filters[0];
            }
            else {
                structuredQuery.where = {
                    compositeFilter: { op: 'AND', filters },
                };
            }
        }
        if (options.orderBy) {
            structuredQuery.orderBy = [
                {
                    field: { fieldPath: options.orderBy },
                    direction: options.orderDirection || 'ASCENDING',
                },
            ];
        }
        if (options.limit) {
            structuredQuery.limit = options.limit;
        }
        try {
            const res = await this.http.post(':runQuery', { structuredQuery });
            if (!Array.isArray(res.data))
                return [];
            return res.data
                .filter((r) => r.document)
                .map((r) => ({
                id: (0, firestore_rest_utils_1.extractDocId)(r.document.name),
                data: (0, firestore_rest_utils_1.decodeFields)(r.document.fields || {}),
                ref: { path: r.document.name.split('/documents/')[1] },
            }));
        }
        catch (error) {
            this.logger.error(`query(${collection}) failed: ${error.message}`);
            throw error;
        }
    }
    async batchDelete(paths) {
        if (paths.length === 0)
            return;
        const writes = paths.map((p) => ({
            delete: `projects/${this.projectId}/databases/(default)/documents/${p}`,
        }));
        for (let i = 0; i < writes.length; i += 500) {
            const chunk = writes.slice(i, i + 500);
            await this.commitWrites(chunk);
        }
    }
    async commitWrites(writes) {
        const apiKey = this.configService.get('FIREBASE_WEB_API_KEY', '');
        const commitUrl = `https://firestore.googleapis.com/v1/projects/${this.projectId}/databases/(default)/documents:commit`;
        return axios_1.default.post(commitUrl, { writes }, { params: apiKey ? { key: apiKey } : {} });
    }
    separateTransforms(collection, docId, data) {
        const fields = {};
        const transforms = [];
        for (const [key, value] of Object.entries(data)) {
            if (value && typeof value === 'object' && value.__type === 'serverTimestamp') {
                transforms.push({
                    fieldPath: key,
                    setToServerValue: 'REQUEST_TIME',
                });
            }
            else if (value && typeof value === 'object' && value.__type === 'increment') {
                transforms.push({
                    fieldPath: key,
                    increment: { integerValue: String(value.amount) },
                });
            }
            else if (value !== undefined) {
                fields[key] = (0, firestore_rest_utils_1.encodeValue)(value);
            }
        }
        return { fields, transforms };
    }
    mapOperator(op) {
        const map = {
            '==': 'EQUAL',
            '!=': 'NOT_EQUAL',
            '<': 'LESS_THAN',
            '<=': 'LESS_THAN_OR_EQUAL',
            '>': 'GREATER_THAN',
            '>=': 'GREATER_THAN_OR_EQUAL',
            'array-contains': 'ARRAY_CONTAINS',
            in: 'IN',
            'array-contains-any': 'ARRAY_CONTAINS_ANY',
            'not-in': 'NOT_IN',
        };
        return map[op] || op;
    }
};
exports.FirestoreRestService = FirestoreRestService;
exports.FirestoreRestService = FirestoreRestService = FirestoreRestService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof config_1.ConfigService !== "undefined" && config_1.ConfigService) === "function" ? _a : Object])
], FirestoreRestService);


/***/ }),

/***/ "./src/firebase-rest/firestore-rest.utils.ts":
/*!***************************************************!*\
  !*** ./src/firebase-rest/firestore-rest.utils.ts ***!
  \***************************************************/
/***/ ((__unused_webpack_module, exports) => {


Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.encodeValue = encodeValue;
exports.decodeValue = decodeValue;
exports.decodeFields = decodeFields;
exports.encodeFields = encodeFields;
exports.extractDocId = extractDocId;
exports.buildFieldFilter = buildFieldFilter;
exports.serverTimestamp = serverTimestamp;
exports.fieldIncrement = fieldIncrement;
function encodeValue(value) {
    if (value === null || value === undefined) {
        return { nullValue: null };
    }
    if (typeof value === 'boolean') {
        return { booleanValue: value };
    }
    if (typeof value === 'number') {
        if (Number.isInteger(value)) {
            return { integerValue: String(value) };
        }
        return { doubleValue: value };
    }
    if (typeof value === 'string') {
        return { stringValue: value };
    }
    if (value instanceof Date) {
        return { timestampValue: value.toISOString() };
    }
    if (Array.isArray(value)) {
        return { arrayValue: { values: value.map(encodeValue) } };
    }
    if (typeof value === 'object') {
        if (value.__type === 'serverTimestamp') {
            return { stringValue: '__SERVER_TIMESTAMP__' };
        }
        const fields = {};
        for (const [k, v] of Object.entries(value)) {
            if (v !== undefined) {
                fields[k] = encodeValue(v);
            }
        }
        return { mapValue: { fields } };
    }
    return { stringValue: String(value) };
}
function decodeValue(val) {
    if ('nullValue' in val)
        return null;
    if ('booleanValue' in val)
        return val.booleanValue;
    if ('integerValue' in val)
        return parseInt(val.integerValue, 10);
    if ('doubleValue' in val)
        return val.doubleValue;
    if ('stringValue' in val)
        return val.stringValue;
    if ('timestampValue' in val)
        return new Date(val.timestampValue);
    if ('referenceValue' in val)
        return val.referenceValue;
    if ('geoPointValue' in val)
        return val.geoPointValue;
    if ('arrayValue' in val) {
        return (val.arrayValue.values || []).map(decodeValue);
    }
    if ('mapValue' in val) {
        return decodeFields(val.mapValue.fields || {});
    }
    return null;
}
function decodeFields(fields) {
    const result = {};
    for (const [key, val] of Object.entries(fields)) {
        result[key] = decodeValue(val);
    }
    return result;
}
function encodeFields(obj) {
    const fields = {};
    for (const [key, val] of Object.entries(obj)) {
        if (val !== undefined) {
            fields[key] = encodeValue(val);
        }
    }
    return fields;
}
function extractDocId(name) {
    const parts = name.split('/');
    return parts[parts.length - 1];
}
function buildFieldFilter(field, op, value) {
    return {
        fieldFilter: {
            field: { fieldPath: field },
            op,
            value: encodeValue(value),
        },
    };
}
function serverTimestamp() {
    return { __type: 'serverTimestamp' };
}
function fieldIncrement(amount) {
    return { __type: 'increment', amount };
}


/***/ }),

/***/ "./src/firebase-rest/storage-rest.service.ts":
/*!***************************************************!*\
  !*** ./src/firebase-rest/storage-rest.service.ts ***!
  \***************************************************/
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
var StorageRestService_1;
var _a;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.StorageRestService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
const axios_1 = __webpack_require__(/*! axios */ "axios");
let StorageRestService = StorageRestService_1 = class StorageRestService {
    constructor(configService) {
        this.configService = configService;
        this.logger = new common_1.Logger(StorageRestService_1.name);
        this.bucket = this.configService.get('FIREBASE_STORAGE_BUCKET', 'pagpagapp.appspot.com');
        this.apiKey = this.configService.get('FIREBASE_WEB_API_KEY', '');
        this.baseUrl = `https://storage.googleapis.com/storage/v1/b/${this.bucket}/o`;
        this.logger.log(`StorageRestService initialized (bucket: ${this.bucket})`);
    }
    async listFiles(prefix) {
        try {
            const res = await axios_1.default.get(this.baseUrl, {
                params: {
                    prefix,
                    key: this.apiKey,
                },
            });
            return res.data.items || [];
        }
        catch (error) {
            this.logger.error(`listFiles(${prefix}) failed: ${error.message}`);
            return [];
        }
    }
    async deleteFile(fileName) {
        try {
            const encodedName = encodeURIComponent(fileName);
            await axios_1.default.delete(`${this.baseUrl}/${encodedName}`, {
                params: { key: this.apiKey },
            });
            return true;
        }
        catch (error) {
            if (error.response?.status === 404)
                return true;
            this.logger.error(`deleteFile(${fileName}) failed: ${error.message}`);
            return false;
        }
    }
    async deleteFolder(prefix) {
        const files = await this.listFiles(prefix);
        let deleted = 0;
        for (const file of files) {
            if (await this.deleteFile(file.name)) {
                deleted++;
            }
        }
        this.logger.log(`Deleted ${deleted}/${files.length} files from ${prefix}`);
        return deleted;
    }
};
exports.StorageRestService = StorageRestService;
exports.StorageRestService = StorageRestService = StorageRestService_1 = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof config_1.ConfigService !== "undefined" && config_1.ConfigService) === "function" ? _a : Object])
], StorageRestService);


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
var HealthController_1;
var _a;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.HealthController = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const swagger_1 = __webpack_require__(/*! @nestjs/swagger */ "@nestjs/swagger");
const firestore_rest_service_1 = __webpack_require__(/*! ./firebase-rest/firestore-rest.service */ "./src/firebase-rest/firestore-rest.service.ts");
const firestore_rest_utils_1 = __webpack_require__(/*! ./firebase-rest/firestore-rest.utils */ "./src/firebase-rest/firestore-rest.utils.ts");
let HealthController = HealthController_1 = class HealthController {
    constructor(firestore) {
        this.firestore = firestore;
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
            await this.firestore.setDocument('_health', 'ping', {
                timestamp: (0, firestore_rest_utils_1.serverTimestamp)(),
            }, true);
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
    (0, common_1.Controller)('health'),
    __metadata("design:paramtypes", [typeof (_a = typeof firestore_rest_service_1.FirestoreRestService !== "undefined" && firestore_rest_service_1.FirestoreRestService) === "function" ? _a : Object])
], HealthController);


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
var _a, _b, _c, _d;
Object.defineProperty(exports, "__esModule", ({ value: true }));
exports.UsersService = void 0;
const common_1 = __webpack_require__(/*! @nestjs/common */ "@nestjs/common");
const crypto = __webpack_require__(/*! crypto */ "crypto");
const firestore_rest_service_1 = __webpack_require__(/*! ../firebase-rest/firestore-rest.service */ "./src/firebase-rest/firestore-rest.service.ts");
const auth_jwt_service_1 = __webpack_require__(/*! ../firebase-rest/auth-jwt.service */ "./src/firebase-rest/auth-jwt.service.ts");
const storage_rest_service_1 = __webpack_require__(/*! ../firebase-rest/storage-rest.service */ "./src/firebase-rest/storage-rest.service.ts");
const firestore_rest_utils_1 = __webpack_require__(/*! ../firebase-rest/firestore-rest.utils */ "./src/firebase-rest/firestore-rest.utils.ts");
const config_1 = __webpack_require__(/*! @nestjs/config */ "@nestjs/config");
let UsersService = class UsersService {
    constructor(firestore, authJwt, storage, configService) {
        this.firestore = firestore;
        this.authJwt = authJwt;
        this.storage = storage;
        this.configService = configService;
    }
    async findByCpf(cpf) {
        try {
            const normalizedCpf = cpf.replace(/\D/g, '');
            const results = await this.firestore.query('users', {
                where: [{ field: 'cpf', op: '==', value: normalizedCpf }],
                limit: 1,
            });
            if (results.length === 0) {
                throw new common_1.NotFoundException('Usuario nao encontrado');
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
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao buscar usuario: ${error.message}`);
        }
    }
    async findByEmail(email) {
        try {
            const results = await this.firestore.query('users', {
                where: [{ field: 'email', op: '==', value: email.toLowerCase() }],
                limit: 1,
            });
            if (results.length === 0) {
                throw new common_1.NotFoundException('Usuario nao encontrado');
            }
            const userDoc = results[0];
            const userData = userDoc.data;
            return {
                id: userDoc.id,
                ...userData,
            };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao buscar usuario: ${error.message}`);
        }
    }
    async findByPhone(phone) {
        try {
            const normalizedPhone = phone.replace(/\D/g, '');
            console.log(`[UsersService] Buscando usuario por telefone: ${normalizedPhone.substring(0, 4)}****`);
            const projectId = this.configService.get('FIREBASE_PROJECT_ID', 'pagpagapp');
            console.log(`[UsersService] Project ID: ${projectId}`);
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
        }
        catch (error) {
            console.error(`[UsersService] Erro ao buscar usuario por telefone:`, {
                message: error.message,
                code: error.code,
                details: error.details,
                stack: error.stack,
            });
            if (error.code === 7 || error.code === 'PERMISSION_DENIED' || error.message?.includes('Permission denied') || error.message?.includes('PERMISSION_DENIED')) {
                console.error(`[UsersService] ERRO DE PERMISSAO DETECTADO`);
                throw new common_1.BadRequestException('Erro de permissao ao acessar Firestore. Verifique as permissoes IAM do servico Cloud Run e a configuracao do Admin SDK.');
            }
            throw new common_1.BadRequestException(`Erro ao buscar usuario: ${error.message}`);
        }
    }
    async findById(userId) {
        try {
            const userDoc = await this.firestore.getDocument('users', userId);
            if (!userDoc) {
                throw new common_1.NotFoundException('Usuario nao encontrado');
            }
            return {
                id: userDoc.id,
                ...userDoc.data,
            };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao buscar usuario: ${error.message}`);
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
                throw new common_1.BadRequestException('CPF ja cadastrado');
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
                created_at: (0, firestore_rest_utils_1.serverTimestamp)(),
                updated_at: (0, firestore_rest_utils_1.serverTimestamp)(),
            };
            const userRef = await this.firestore.addDocument('users', userData);
            return {
                id: userRef.id,
                ...userData,
            };
        }
        catch (error) {
            if (error instanceof common_1.BadRequestException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao criar usuario: ${error.message}`);
        }
    }
    async update(userId, updateUserDto) {
        try {
            const userDoc = await this.firestore.getDocument('users', userId);
            if (!userDoc) {
                throw new common_1.NotFoundException('Usuario nao encontrado');
            }
            const updateData = {
                updated_at: (0, firestore_rest_utils_1.serverTimestamp)(),
            };
            if (updateUserDto.full_name)
                updateData.full_name = updateUserDto.full_name;
            if (updateUserDto.email)
                updateData.email = updateUserDto.email.toLowerCase();
            if (updateUserDto.phone)
                updateData.phone = updateUserDto.phone.replace(/\D/g, '');
            await this.firestore.updateDocument('users', userId, updateData);
            const updatedDoc = await this.firestore.getDocument('users', userId);
            return {
                id: updatedDoc.id,
                ...updatedDoc.data,
            };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao atualizar usuario: ${error.message}`);
        }
    }
    async remove(userId) {
        try {
            const userDoc = await this.firestore.getDocument('users', userId);
            if (!userDoc) {
                throw new common_1.NotFoundException('Usuario nao encontrado');
            }
            await this.firestore.updateDocument('users', userId, {
                deleted_at: (0, firestore_rest_utils_1.serverTimestamp)(),
                updated_at: (0, firestore_rest_utils_1.serverTimestamp)(),
            });
            return { success: true, message: 'Usuario removido com sucesso' };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            throw new common_1.BadRequestException(`Erro ao remover usuario: ${error.message}`);
        }
    }
    async deleteUserDataComplete(userId) {
        try {
            console.log(`[UsersService] Iniciando limpeza completa dos dados do usuario: ${userId}`);
            const userDoc = await this.firestore.getDocument('users', userId);
            if (!userDoc) {
                throw new common_1.NotFoundException('Usuario nao encontrado no Firestore');
            }
            const userData = userDoc.data;
            const ownerUid = userData['ownerUid'];
            console.log(`[UsersService] Documento encontrado. ownerUid: ${ownerUid || 'nao vinculado'}`);
            const results = {
                storageDeleted: false,
                authDeleted: false,
                firestoreDeleted: false,
            };
            try {
                console.log('[UsersService] Deletando arquivos do Storage...');
                const folderPath = `users/${userId}/kyc`;
                const deletedCount = await this.storage.deleteFolder(folderPath);
                console.log(`[UsersService] ${deletedCount} arquivo(s) do Storage deletado(s)`);
                results.storageDeleted = true;
            }
            catch (error) {
                console.warn(`[UsersService] Erro ao deletar arquivos do Storage (continuando): ${error.message}`);
            }
            if (ownerUid) {
                console.log(`[UsersService] ownerUid ${ownerUid} encontrado - auth deletion skipped (sem firebase-admin)`);
                results.authDeleted = false;
            }
            else {
                console.log('[UsersService] Usuario nao possui conta no Firebase Auth (ownerUid nao encontrado)');
            }
            try {
                console.log('[UsersService] Deletando documento do Firestore...');
                await this.firestore.deleteDocument('users', userId);
                console.log('[UsersService] Documento do Firestore deletado');
                results.firestoreDeleted = true;
            }
            catch (error) {
                console.error(`[UsersService] Erro ao deletar documento do Firestore: ${error.message}`);
                throw new common_1.BadRequestException(`Erro ao deletar documento do Firestore: ${error.message}`);
            }
            console.log('[UsersService] Limpeza completa dos dados do usuario concluida com sucesso');
            return {
                success: true,
                message: 'Dados do usuario deletados com sucesso',
                details: results,
            };
        }
        catch (error) {
            if (error instanceof common_1.NotFoundException) {
                throw error;
            }
            console.error(`[UsersService] Erro durante limpeza dos dados do usuario: ${error.message}`);
            throw new common_1.BadRequestException(`Erro ao deletar dados do usuario: ${error.message}`);
        }
    }
    async verifyPassword(verifyPasswordDto) {
        throw new common_1.BadRequestException('Verificacao de senha deve ser feita via Firebase Auth no frontend');
    }
    async syncFirebaseEmail(cpf, oldEmail) {
        try {
            const user = await this.findByCpf(cpf);
            const emailResults = await this.firestore.query('users', {
                where: [{ field: 'email', op: '==', value: oldEmail.toLowerCase() }],
                limit: 1,
            });
            if (emailResults.length === 0) {
                throw new common_1.NotFoundException('Usuario nao encontrado com o email informado');
            }
            const foundUser = emailResults[0];
            await this.firestore.updateDocument('users', user.id, {
                email: foundUser.data.email,
                updated_at: (0, firestore_rest_utils_1.serverTimestamp)(),
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
            const storeDoc = await this.firestore.getDocument('user_stores', userId);
            if (!storeDoc) {
                throw new common_1.NotFoundException('Dados da loja nao encontrados');
            }
            return {
                id: storeDoc.id,
                ...storeDoc.data,
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
            await this.firestore.setDocument('user_stores', userId, {
                ...storeDataDto,
                user_id: userId,
                updated_at: (0, firestore_rest_utils_1.serverTimestamp)(),
            }, true);
            const storeDoc = await this.firestore.getDocument('user_stores', userId);
            return {
                id: storeDoc.id,
                ...storeDoc.data,
            };
        }
        catch (error) {
            throw new common_1.BadRequestException(`Erro ao salvar dados da loja: ${error.message}`);
        }
    }
    async getPixKeys(userId) {
        try {
            const results = await this.firestore.query('user_pix_keys', {
                where: [{ field: 'user_id', op: '==', value: userId }],
            });
            return results.map(doc => ({
                id: doc.id,
                ...doc.data,
            }));
        }
        catch (error) {
            throw new common_1.BadRequestException(`Erro ao buscar chaves PIX: ${error.message}`);
        }
    }
    async addPixKey(userId, createPixKeyDto) {
        try {
            const pixKeyRef = await this.firestore.addDocument('user_pix_keys', {
                user_id: userId,
                ...createPixKeyDto,
                created_at: (0, firestore_rest_utils_1.serverTimestamp)(),
                updated_at: (0, firestore_rest_utils_1.serverTimestamp)(),
            });
            const pixKeyDoc = await this.firestore.getDocument('user_pix_keys', pixKeyRef.id);
            return {
                id: pixKeyDoc.id,
                ...pixKeyDoc.data,
            };
        }
        catch (error) {
            throw new common_1.BadRequestException(`Erro ao adicionar chave PIX: ${error.message}`);
        }
    }
    async removePixKey(userId, keyId) {
        try {
            const pixKeyDoc = await this.firestore.getDocument('user_pix_keys', keyId);
            if (!pixKeyDoc) {
                throw new common_1.NotFoundException('Chave PIX nao encontrada');
            }
            if (pixKeyDoc.data?.user_id !== userId) {
                throw new common_1.BadRequestException('Chave PIX nao pertence ao usuario');
            }
            await this.firestore.deleteDocument('user_pix_keys', keyId);
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
            await this.firestore.updateDocument('users', userId, {
                last_login: (0, firestore_rest_utils_1.serverTimestamp)(),
                updated_at: (0, firestore_rest_utils_1.serverTimestamp)(),
            });
            return { success: true };
        }
        catch (error) {
            console.error(`Erro ao atualizar ultimo login: ${error.message}`);
            return { success: false };
        }
    }
};
exports.UsersService = UsersService;
exports.UsersService = UsersService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [typeof (_a = typeof firestore_rest_service_1.FirestoreRestService !== "undefined" && firestore_rest_service_1.FirestoreRestService) === "function" ? _a : Object, typeof (_b = typeof auth_jwt_service_1.AuthJwtService !== "undefined" && auth_jwt_service_1.AuthJwtService) === "function" ? _b : Object, typeof (_c = typeof storage_rest_service_1.StorageRestService !== "undefined" && storage_rest_service_1.StorageRestService) === "function" ? _c : Object, typeof (_d = typeof config_1.ConfigService !== "undefined" && config_1.ConfigService) === "function" ? _d : Object])
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

/***/ "axios":
/*!************************!*\
  !*** external "axios" ***!
  \************************/
/***/ ((module) => {

module.exports = require("axios");

/***/ }),

/***/ "class-transformer":
/*!************************************!*\
  !*** external "class-transformer" ***!
  \************************************/
/***/ ((module) => {

module.exports = require("class-transformer");

/***/ }),

/***/ "class-validator":
/*!**********************************!*\
  !*** external "class-validator" ***!
  \**********************************/
/***/ ((module) => {

module.exports = require("class-validator");

/***/ }),

/***/ "helmet":
/*!*************************!*\
  !*** external "helmet" ***!
  \*************************/
/***/ ((module) => {

module.exports = require("helmet");

/***/ }),

/***/ "jsonwebtoken":
/*!*******************************!*\
  !*** external "jsonwebtoken" ***!
  \*******************************/
/***/ ((module) => {

module.exports = require("jsonwebtoken");

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
async function bootstrap() {
    try {
        console.log('🚀 Iniciando aplicação NestJS...');
        console.log(`📋 Ambiente: ${process.env.NODE_ENV || 'development'}`);
        console.log(`🔌 Porta: ${process.env.PORT || 8080}`);
        console.log(`🔥 Firebase: REST API (sem Admin SDK)`);
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
                const exceptionResponse = typeof exception.getResponse === 'function'
                    ? exception.getResponse()
                    : null;
                const baseBody = exceptionResponse && typeof exceptionResponse === 'object'
                    ? exceptionResponse
                    : { message: exception.message || 'Internal server error' };
                response.status(status).json({
                    statusCode: status,
                    ...baseBody,
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
            .setDescription('API Backend for Neves Capital - Firebase REST')
            .setVersion('2.0')
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