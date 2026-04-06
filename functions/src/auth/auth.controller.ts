import { Controller, Post, Body, UseGuards, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiSecurity, ApiResponse } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { ApiKeyGuard } from '../common/guards/api-key.guard';
import { AuthJwtService } from '../firebase-rest/auth-jwt.service';
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
    private readonly authJwt: AuthJwtService,
  ) { }

  @Post('reset-password')
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 requests por minuto
  @ApiOperation({
    summary: 'Enviar email de redefinicao de senha (customizado)',
    description: 'Envia email customizado com template personalizado'
  })
  @ApiResponse({ status: 200, description: 'Email enviado com sucesso' })
  @ApiResponse({ status: 400, description: 'Email invalido' })
  @ApiResponse({ status: 404, description: 'Usuario nao encontrado' })
  async resetPassword(@Body() resetPasswordDto: ResetPasswordDto) {
    try {
      await this.emailSenderService.sendPasswordResetEmail(resetPasswordDto.email);

      return {
        success: true,
        message: 'Email de redefinicao de senha enviado com sucesso',
      };
    } catch (error) {
      throw error;
    }
  }

  @Post('send-otp')
  @Throttle({ default: { limit: 3, ttl: 60000 } }) // 3 requests por minuto
  @ApiOperation({
    summary: 'Enviar codigo OTP para telefone (alternativa ao Firebase Phone Auth)',
    description: 'Gera e retorna codigo OTP de 6 digitos. Para testes, o codigo e retornado no response.'
  })
  @ApiResponse({ status: 200, description: 'OTP gerado com sucesso' })
  @ApiResponse({ status: 400, description: 'Telefone invalido' })
  async sendOtp(@Body() body: SendPhoneOtpDto) {
    const result = await this.simpleOtpService.sendOtp(body.phone);

    if (!result.success) {
      throw new BadRequestException(result.message);
    }

    return {
      success: true,
      message: result.message,
      code: result.code, // WARNING: APENAS PARA TESTES - remover em producao
    };
  }

  @Post('verify-otp')
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // 10 requests por minuto
  @ApiOperation({
    summary: 'Verificar codigo OTP',
    description: 'Valida o codigo OTP enviado pelo usuario'
  })
  @ApiResponse({ status: 200, description: 'OTP verificado com sucesso' })
  @ApiResponse({ status: 400, description: 'Codigo invalido ou expirado' })
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
    summary: 'Enviar codigo OTP via WhatsApp',
    description: 'Gera codigo OTP de 4 digitos e envia via WhatsApp para o telefone informado'
  })
  @ApiResponse({ status: 200, description: 'OTP enviado via WhatsApp com sucesso' })
  @ApiResponse({ status: 400, description: 'Telefone invalido ou falha no envio' })
  async sendOtpWhatsApp(@Body() body: SendPhoneOtpDto) {
    const t0 = Date.now();

    // 1. Gerar e salvar OTP no Firestore
    const t1 = Date.now();
    const result = await this.simpleOtpService.sendOtp(body.phone);
    const t2 = Date.now();
    console.log(`[OTP-TIMING] Firestore (gerar+salvar OTP): ${t2 - t1}ms`);

    if (!result.success) {
      throw new BadRequestException(result.message);
    }

    // 2. Enviar OTP via WhatsApp (fire-and-forget -- nao bloqueia a resposta)
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

  @Post('verify-otp-login')
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // 10 requests por minuto
  @ApiOperation({
    summary: 'Verificar OTP e fazer login',
    description: 'Valida o codigo OTP, busca usuario pelo telefone no Firestore e retorna status + JWT token para login'
  })
  @ApiResponse({ status: 200, description: 'OTP verificado e status do usuario retornado' })
  @ApiResponse({ status: 400, description: 'Codigo invalido, expirado ou telefone invalido' })
  async verifyOtpLogin(@Body() body: VerifyPhoneOtpDto) {
    // 1. Verificar OTP
    const otpResult = await this.simpleOtpService.verifyOtp(body.phone, body.code);

    if (!otpResult.success) {
      throw new BadRequestException(otpResult.message);
    }

    // 2. Normalizar telefone
    const normalizedPhone = body.phone.replace(/\D/g, '');
    console.log(`[AuthController] OTP verificado para ${normalizedPhone.substring(0, 4)}***`);

    // 3. Buscar usuario no Firestore pelo telefone (via phoneHash)
    const user = await this.usersService.findByPhone(normalizedPhone);

    if (user) {
      // Verificar se o cadastro esta completo
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

      // Usuario com cadastro completo -- gerar JWT token
      console.log(`[AuthController] Usuario completo encontrado. ID: ${user.id}`);

      try {
        // Gerar JWT token (substitui admin.auth().createCustomToken)
        const token = this.authJwt.signToken({
          sub: user.id,
          phone: normalizedPhone,
        });
        console.log(`[AuthController] JWT token gerado para userId: ${user.id}`);

        // Registrar login
        try {
          await this.usersService.updateLastLogin(user.id);
        } catch (error) {
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
      } catch (error: any) {
        console.error(`[AuthController] Erro ao gerar JWT token: ${error.message}`);
        throw new BadRequestException('Erro ao processar login. Tente novamente.');
      }
    } else {
      // Usuario nao encontrado -- cadastro necessario
      console.log(`[AuthController] Usuario nao encontrado para ${normalizedPhone.substring(0, 4)}***`);
      return {
        success: true,
        status: 'REGISTER',
        message: 'Usuario nao encontrado. Redirecionando para cadastro.',
        phone: normalizedPhone,
      };
    }
  }

  @Post('check-user-status')
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // 10 requests por minuto
  @ApiOperation({
    summary: 'Verificar status do usuario apos autenticacao',
    description: 'Verifica o JWT token, busca o usuario no Firestore e retorna o status (LOGGED_IN ou REGISTER)'
  })
  @ApiResponse({ status: 200, description: 'Status do usuario retornado com sucesso' })
  @ApiResponse({ status: 400, description: 'Token invalido' })
  @ApiResponse({ status: 401, description: 'Token nao autorizado' })
  async checkUserStatus(@Body() body: CheckUserStatusDto) {
    try {
      console.log('[AuthController] Verificando status do usuario...');

      // 1. Verificar e decodificar o JWT token (substitui admin.auth().verifyIdToken)
      let decoded: { sub: string; phone?: string; email?: string };
      try {
        decoded = this.authJwt.verifyToken(body.token);
      } catch (error: any) {
        throw new UnauthorizedException('Token invalido ou expirado');
      }

      const userId = decoded.sub;
      const phoneNumber = decoded.phone;

      console.log(`[AuthController] Token verificado. userId: ${userId}, Phone: ${phoneNumber?.substring(0, 4)}****`);

      if (!phoneNumber) {
        throw new BadRequestException('Token nao contem numero de telefone');
      }

      // 2. Normalizar telefone (remover formatacao)
      const normalizedPhone = phoneNumber.replace(/\D/g, '');

      // 3. Buscar usuario no Firestore pelo telefone
      console.log(`[AuthController] Buscando usuario no Firestore...`);
      const user = await this.usersService.findByPhone(normalizedPhone);

      if (user) {
        // Verificar se o cadastro esta completo (todos os campos obrigatorios preenchidos)
        const isRegistrationComplete = this.isRegistrationComplete(user);

        if (!isRegistrationComplete) {
          // Usuario existe mas cadastro incompleto - redirecionar para cadastro
          console.log(`[AuthController] Usuario encontrado mas cadastro incompleto. ID: ${user.id}`);
          return {
            success: true,
            status: 'REGISTER',
            message: 'Cadastro incompleto. Redirecionando para finalizar cadastro.',
            phone: normalizedPhone,
          };
        }

        // Usuario existe na collection users = cadastro completo
        console.log(`[AuthController] Usuario encontrado com cadastro completo. ID: ${user.id}`);

        // Registrar login (atualizar ultimo login)
        try {
          await this.usersService.updateLastLogin(user.id);
          console.log(`[AuthController] Login registrado para usuario ${user.id}`);
        } catch (error) {
          console.warn(`[AuthController] Erro ao registrar login (nao critico): ${error.message}`);
        }

        // Retornar status LOGGED_IN para redirecionar ao Dashboard
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
      } else {
        // Usuario nao existe - precisa se cadastrar
        console.log(`[AuthController] Usuario nao encontrado. Redirecionando para cadastro.`);
        return {
          success: true,
          status: 'REGISTER',
          message: 'Usuario nao encontrado. Redirecionando para cadastro.',
          phone: normalizedPhone,
        };
      }
    } catch (error: any) {
      console.error(`[AuthController] Erro ao verificar status:`, {
        message: error.message,
        code: error.code,
        stack: error.stack,
      });

      if (error instanceof BadRequestException || error instanceof UnauthorizedException) {
        throw error;
      }

      throw new BadRequestException(`Erro ao verificar status: ${error.message}`);
    }
  }

  /**
   * Verifica se o cadastro do usuario esta completo
   * Campos obrigatorios conforme estrutura do Firestore:
   * - cpfEncrypted ou cpfHash (CPF criptografado ou hash)
   * - emailEncrypted ou emailHash (Email criptografado ou hash)
   * - displayName ou full_name (Nome completo)
   * - phone ou phoneHash (Telefone ou hash)
   * - birthDate (Data de nascimento)
   * - motherName (Nome da mae)
   * - occupation (Ocupacao)
   * - incomeRange (Faixa de renda)
   * - kycDocuments.documentType (Tipo de documento dentro de kycDocuments)
   */
  private isRegistrationComplete(user: any): boolean {
    // Verificar CPF (pode estar como cpfEncrypted, cpfHash ou cpf)
    const hasCpf = !!(user.cpfEncrypted || user.cpfHash || user.cpf);
    if (!hasCpf) {
      console.log(`[AuthController] Campo obrigatorio ausente: CPF (cpfEncrypted/cpfHash/cpf)`);
      return false;
    }

    // Verificar Email (pode estar como emailEncrypted, emailHash ou email)
    const hasEmail = !!(user.emailEncrypted || user.emailHash || user.email);
    if (!hasEmail) {
      console.log(`[AuthController] Campo obrigatorio ausente: Email (emailEncrypted/emailHash/email)`);
      return false;
    }

    // Verificar Nome Completo (pode estar como displayName ou full_name)
    const hasFullName = !!(user.displayName || user.full_name);
    if (!hasFullName) {
      console.log(`[AuthController] Campo obrigatorio ausente: Nome Completo (displayName/full_name)`);
      return false;
    }

    // Verificar Telefone (pode estar como phone ou phoneHash)
    const hasPhone = !!(user.phone || user.phoneHash);
    if (!hasPhone) {
      console.log(`[AuthController] Campo obrigatorio ausente: Telefone (phone/phoneHash)`);
      return false;
    }

    // Verificar Data de Nascimento
    if (!user.birthDate) {
      console.log(`[AuthController] Campo obrigatorio ausente: birthDate`);
      return false;
    }

    // Verificar Nome da Mae
    if (!user.motherName || user.motherName === '') {
      console.log(`[AuthController] Campo obrigatorio ausente: motherName`);
      return false;
    }

    // Verificar Ocupacao
    if (!user.occupation || user.occupation === '') {
      console.log(`[AuthController] Campo obrigatorio ausente: occupation`);
      return false;
    }

    // Verificar Faixa de Renda
    if (!user.incomeRange || user.incomeRange === '') {
      console.log(`[AuthController] Campo obrigatorio ausente: incomeRange`);
      return false;
    }

    // Verificar Tipo de Documento (pode estar dentro de kycDocuments ou como campo direto)
    const hasDocumentType = !!(user.kycDocuments?.documentType || user.documentType);
    if (!hasDocumentType) {
      console.log(`[AuthController] Campo obrigatorio ausente: documentType (kycDocuments.documentType/documentType)`);
      return false;
    }

    console.log(`[AuthController] Todos os campos obrigatorios estao presentes`);
    return true;
  }

}
