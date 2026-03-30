import { Controller, Post, Body, UseGuards, BadRequestException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiSecurity, ApiResponse } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { ApiKeyGuard } from '../common/guards/api-key.guard';
import * as admin from 'firebase-admin';
import { EmailSenderService } from './email-sender.service';
import { SimpleOtpService } from './services/simple-otp.service';
import { WhatsAppService } from './services/whatsapp.service';
import { UsersService } from '../users/users.service';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { SendPhoneOtpDto, VerifyPhoneOtpDto, CheckUserStatusDto } from './dto/send-phone-otp.dto';

@ApiTags('Auth')
@Controller('api/auth')
@UseGuards(ApiKeyGuard)
@ApiSecurity('api-key')
export class AuthController {
  constructor(
    private readonly emailSenderService: EmailSenderService,
    private readonly simpleOtpService: SimpleOtpService,
    private readonly whatsAppService: WhatsAppService,
    private readonly usersService: UsersService,
  ) { }

  @Post('reset-password')
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 requests por minuto
  @ApiOperation({
    summary: 'Enviar email de redefinição de senha (customizado)',
    description: 'Envia email customizado com template personalizado usando Firebase Admin SDK para gerar o link'
  })
  @ApiResponse({ status: 200, description: 'Email enviado com sucesso' })
  @ApiResponse({ status: 400, description: 'Email inválido' })
  @ApiResponse({ status: 404, description: 'Usuário não encontrado no Firebase' })
  async resetPassword(@Body() resetPasswordDto: ResetPasswordDto) {
    try {
      await this.emailSenderService.sendPasswordResetEmail(resetPasswordDto.email);

      return {
        success: true,
        message: 'Email de redefinição de senha enviado com sucesso',
      };
    } catch (error) {
      throw error;
    }
  }

  @Post('send-otp')
  @Throttle({ default: { limit: 3, ttl: 60000 } }) // 3 requests por minuto
  @ApiOperation({
    summary: 'Enviar código OTP para telefone (alternativa ao Firebase Phone Auth)',
    description: 'Gera e retorna código OTP de 6 dígitos. Para testes, o código é retornado no response.'
  })
  @ApiResponse({ status: 200, description: 'OTP gerado com sucesso' })
  @ApiResponse({ status: 400, description: 'Telefone inválido' })
  async sendOtp(@Body() body: SendPhoneOtpDto) {
    const result = await this.simpleOtpService.sendOtp(body.phone);

    if (!result.success) {
      throw new BadRequestException(result.message);
    }

    return {
      success: true,
      message: result.message,
      code: result.code, // ⚠️ APENAS PARA TESTES - remover em produção
    };
  }

  @Post('verify-otp')
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // 10 requests por minuto
  @ApiOperation({
    summary: 'Verificar código OTP',
    description: 'Valida o código OTP enviado pelo usuário'
  })
  @ApiResponse({ status: 200, description: 'OTP verificado com sucesso' })
  @ApiResponse({ status: 400, description: 'Código inválido ou expirado' })
  async verifyOtp(@Body() body: VerifyPhoneOtpDto) {
    const result = await this.simpleOtpService.verifyOtp(body.phone, body.code);

    if (!result.success) {
      throw new BadRequestException(result.message);
    }

    return {
      success: true,
      message: result.message,
    };
  }

  @Post('send-otp-whatsapp')
  @Throttle({ default: { limit: 3, ttl: 60000 } }) // 3 requests por minuto
  @ApiOperation({
    summary: 'Enviar código OTP via WhatsApp',
    description: 'Gera código OTP de 4 dígitos e envia via WhatsApp para o telefone informado'
  })
  @ApiResponse({ status: 200, description: 'OTP enviado via WhatsApp com sucesso' })
  @ApiResponse({ status: 400, description: 'Telefone inválido ou falha no envio' })
  async sendOtpWhatsApp(@Body() body: SendPhoneOtpDto) {
    const t0 = Date.now();

    // 1. Gerar e salvar OTP no Firestore
    const t1 = Date.now();
    const result = await this.simpleOtpService.sendOtp(body.phone);
    const t2 = Date.now();
    console.log(`⏱️ [OTP-TIMING] Firestore (gerar+salvar OTP): ${t2 - t1}ms`);

    if (!result.success) {
      throw new BadRequestException(result.message);
    }

    // 2. Enviar OTP via WhatsApp (fire-and-forget — não bloqueia a resposta)
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

  @Post('verify-otp-login')
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // 10 requests por minuto
  @ApiOperation({
    summary: 'Verificar OTP e fazer login',
    description: 'Valida o código OTP, busca usuário pelo telefone e retorna status + custom token para login'
  })
  @ApiResponse({ status: 200, description: 'OTP verificado e status do usuário retornado' })
  @ApiResponse({ status: 400, description: 'Código inválido, expirado ou telefone inválido' })
  async verifyOtpLogin(@Body() body: VerifyPhoneOtpDto) {
    // 1. Verificar OTP
    const otpResult = await this.simpleOtpService.verifyOtp(body.phone, body.code);

    if (!otpResult.success) {
      throw new BadRequestException(otpResult.message);
    }

    // 2. Normalizar telefone
    const normalizedPhone = body.phone.replace(/\D/g, '');
    console.log(`✅ [AuthController] OTP verificado para ${normalizedPhone.substring(0, 4)}***`);

    // 3. Buscar usuário no Firestore pelo telefone
    const user = await this.usersService.findByPhone(normalizedPhone);

    if (user) {
      // Verificar se o cadastro está completo
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

      // Usuário com cadastro completo — gerar Custom Token
      console.log(`✅ [AuthController] Usuário completo encontrado. ID: ${user.id}`);

      try {
        // Obter ou criar Firebase Auth user para este telefone
        let firebaseUid: string;
        try {
          const firebaseUser = await admin.auth().getUserByPhoneNumber('+' + normalizedPhone);
          firebaseUid = firebaseUser.uid;
        } catch (e: any) {
          if (e.code === 'auth/user-not-found') {
            // Criar Firebase Auth user
            const newUser = await admin.auth().createUser({
              phoneNumber: '+' + normalizedPhone,
            });
            firebaseUid = newUser.uid;
            console.log(`📝 [AuthController] Firebase Auth user criado: ${firebaseUid}`);
          } else {
            throw e;
          }
        }

        // Gerar Custom Token
        const customToken = await admin.auth().createCustomToken(firebaseUid);
        console.log(`🔑 [AuthController] Custom token gerado para UID: ${firebaseUid}`);

        // Registrar login
        try {
          await this.usersService.updateLastLogin(user.id);
        } catch (error) {
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
      } catch (error: any) {
        console.error(`❌ [AuthController] Erro ao gerar custom token: ${error.message}`);
        throw new BadRequestException('Erro ao processar login. Tente novamente.');
      }
    } else {
      // Usuário não encontrado — cadastro necessário
      console.log(`📝 [AuthController] Usuário não encontrado para ${normalizedPhone.substring(0, 4)}***`);
      return {
        success: true,
        status: 'REGISTER',
        message: 'Usuário não encontrado. Redirecionando para cadastro.',
        phone: normalizedPhone,
      };
    }
  }

  @Post('check-user-status')
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // 10 requests por minuto
  @ApiOperation({
    summary: 'Verificar status do usuário após autenticação Firebase',
    description: 'Verifica se o usuário existe no sistema e retorna o status (LOGGED_IN, REQUIRE_CPF_CHECK ou REGISTER)'
  })
  @ApiResponse({ status: 200, description: 'Status do usuário retornado com sucesso' })
  @ApiResponse({ status: 400, description: 'Token inválido' })
  @ApiResponse({ status: 401, description: 'Token não autorizado' })
  async checkUserStatus(@Body() body: CheckUserStatusDto) {
    try {
      console.log('🔐 [AuthController] Verificando status do usuário...');

      // 1. Verificar e decodificar o token do Firebase
      const decodedToken = await admin.auth().verifyIdToken(body.token);
      const firebaseUid = decodedToken.uid;
      const phoneNumber = decodedToken.phone_number;

      console.log(`📱 [AuthController] Token verificado. UID: ${firebaseUid}, Phone: ${phoneNumber?.substring(0, 4)}****`);

      if (!phoneNumber) {
        throw new BadRequestException('Token não contém número de telefone');
      }

      // 2. Normalizar telefone (remover formatação)
      const normalizedPhone = phoneNumber.replace(/\D/g, '');

      // 3. Buscar usuário no Firestore pelo telefone
      console.log(`🔍 [AuthController] Buscando usuário no Firestore...`);
      const user = await this.usersService.findByPhone(normalizedPhone);

      if (user) {
        // Verificar se o cadastro está completo (todos os campos obrigatórios preenchidos)
        const isRegistrationComplete = this.isRegistrationComplete(user);
        
        if (!isRegistrationComplete) {
          // Usuário existe mas cadastro incompleto - redirecionar para cadastro
          console.log(`⚠️ [AuthController] Usuário encontrado mas cadastro incompleto. ID: ${user.id}`);
          return {
            success: true,
            status: 'REGISTER',
            message: 'Cadastro incompleto. Redirecionando para finalizar cadastro.',
            phone: normalizedPhone,
          };
        }

        // Usuário existe na collection users = cadastro completo
        console.log(`✅ [AuthController] Usuário encontrado com cadastro completo. ID: ${user.id}`);

        // Registrar login (atualizar último login)
        try {
          await this.usersService.updateLastLogin(user.id);
          console.log(`📝 [AuthController] Login registrado para usuário ${user.id}`);
        } catch (error) {
          console.warn(`⚠️ [AuthController] Erro ao registrar login (não crítico): ${error.message}`);
        }

        // Retornar status LOGGED_IN para redirecionar ao Dashboard
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
      } else {
        // Usuário não existe - precisa se cadastrar
        console.log(`📝 [AuthController] Usuário não encontrado. Redirecionando para cadastro.`);
        return {
          success: true,
          status: 'REGISTER',
          message: 'Usuário não encontrado. Redirecionando para cadastro.',
          phone: normalizedPhone,
        };
      }
    } catch (error: any) {
      console.error(`❌ [AuthController] Erro ao verificar status:`, {
        message: error.message,
        code: error.code,
        stack: error.stack,
      });

      if (error instanceof BadRequestException) {
        throw error;
      }

      // Se o erro for de verificação de token
      if (error.code === 'auth/argument-error' || error.code === 'auth/id-token-expired') {
        throw new UnauthorizedException('Token inválido ou expirado');
      }

      throw new BadRequestException(`Erro ao verificar status: ${error.message}`);
    }
  }

  /**
   * Verifica se o cadastro do usuário está completo
   * Campos obrigatórios conforme estrutura do Firestore:
   * - cpfEncrypted ou cpfHash (CPF criptografado ou hash)
   * - emailEncrypted ou emailHash (Email criptografado ou hash)
   * - displayName ou full_name (Nome completo)
   * - phone ou phoneHash (Telefone ou hash)
   * - birthDate (Data de nascimento)
   * - motherName (Nome da mãe)
   * - occupation (Ocupação)
   * - incomeRange (Faixa de renda)
   * - kycDocuments.documentType (Tipo de documento dentro de kycDocuments)
   */
  private isRegistrationComplete(user: any): boolean {
    // Verificar CPF (pode estar como cpfEncrypted, cpfHash ou cpf)
    const hasCpf = !!(user.cpfEncrypted || user.cpfHash || user.cpf);
    if (!hasCpf) {
      console.log(`⚠️ [AuthController] Campo obrigatório ausente: CPF (cpfEncrypted/cpfHash/cpf)`);
      return false;
    }

    // Verificar Email (pode estar como emailEncrypted, emailHash ou email)
    const hasEmail = !!(user.emailEncrypted || user.emailHash || user.email);
    if (!hasEmail) {
      console.log(`⚠️ [AuthController] Campo obrigatório ausente: Email (emailEncrypted/emailHash/email)`);
      return false;
    }

    // Verificar Nome Completo (pode estar como displayName ou full_name)
    const hasFullName = !!(user.displayName || user.full_name);
    if (!hasFullName) {
      console.log(`⚠️ [AuthController] Campo obrigatório ausente: Nome Completo (displayName/full_name)`);
      return false;
    }

    // Verificar Telefone (pode estar como phone ou phoneHash)
    const hasPhone = !!(user.phone || user.phoneHash);
    if (!hasPhone) {
      console.log(`⚠️ [AuthController] Campo obrigatório ausente: Telefone (phone/phoneHash)`);
      return false;
    }

    // Verificar Data de Nascimento
    if (!user.birthDate) {
      console.log(`⚠️ [AuthController] Campo obrigatório ausente: birthDate`);
      return false;
    }

    // Verificar Nome da Mãe
    if (!user.motherName || user.motherName === '') {
      console.log(`⚠️ [AuthController] Campo obrigatório ausente: motherName`);
      return false;
    }

    // Verificar Ocupação
    if (!user.occupation || user.occupation === '') {
      console.log(`⚠️ [AuthController] Campo obrigatório ausente: occupation`);
      return false;
    }

    // Verificar Faixa de Renda
    if (!user.incomeRange || user.incomeRange === '') {
      console.log(`⚠️ [AuthController] Campo obrigatório ausente: incomeRange`);
      return false;
    }

    // Verificar Tipo de Documento (pode estar dentro de kycDocuments ou como campo direto)
    const hasDocumentType = !!(user.kycDocuments?.documentType || user.documentType);
    if (!hasDocumentType) {
      console.log(`⚠️ [AuthController] Campo obrigatório ausente: documentType (kycDocuments.documentType/documentType)`);
      return false;
    }

    console.log(`✅ [AuthController] Todos os campos obrigatórios estão presentes`);
    return true;
  }

}
