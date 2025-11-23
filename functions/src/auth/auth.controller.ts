import { Controller, Post, Body, UseGuards, BadRequestException, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiSecurity, ApiResponse } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { ApiKeyGuard } from '../common/guards/api-key.guard';
import { EmailSenderService } from './email-sender.service';
import { ResetPasswordDto, ResetPasswordByCpfDto } from './dto/reset-password.dto';
import { RequestPasswordResetOtpDto, VerifyPasswordResetOtpDto, ChangePasswordWithOtpDto } from './dto/otp.dto';
import { CheckCpfDto, RequestRegistrationOtpDto, VerifyRegistrationOtpDto } from './dto/registration-otp.dto';
import { UsersService } from '../users/users.service';
import { OtpService } from './services/otp.service';
import { SmsService } from './services/sms.service';
import { YcloudService } from './services/ycloud.service';
import { EncryptionService } from '../common/services/encryption.service';

@ApiTags('Auth')
@Controller('api/auth')
@UseGuards(ApiKeyGuard)
@ApiSecurity('api-key')
export class AuthController {
  constructor(
    private readonly emailSenderService: EmailSenderService,
    private readonly usersService: UsersService,
    private readonly otpService: OtpService,
    private readonly smsService: SmsService,
    private readonly ycloudService: YcloudService,
    private readonly encryptionService: EncryptionService,
  ) {}

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

  @Post('reset-password/cpf')
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 requests por minuto
  @ApiOperation({ 
    summary: 'Enviar email de redefinição de senha por CPF (customizado)',
    description: 'Busca email por CPF no PostgreSQL e envia email customizado de reset'
  })
  @ApiResponse({ status: 200, description: 'Email enviado com sucesso' })
  @ApiResponse({ status: 404, description: 'CPF não encontrado' })
  async resetPasswordByCpf(@Body() resetPasswordByCpfDto: ResetPasswordByCpfDto) {
    try {
      // 1. Buscar usuário por CPF
      const userData = await this.usersService.findByCpf(resetPasswordByCpfDto.cpf);
      
      if (!userData || !userData.email) {
        throw new Error('CPF não encontrado');
      }

      // 2. Enviar email customizado
      await this.emailSenderService.sendPasswordResetEmail(userData.email);
      
      return {
        success: true,
        message: 'Email de redefinição de senha enviado com sucesso',
      };
    } catch (error) {
      throw error;
    }
  }

  @Post('request-password-reset-otp')
  @Throttle({ default: { limit: 3, ttl: 120000 } }) // 3 requests por 2 minutos (rate limiting mais restritivo)
  @ApiOperation({ 
    summary: 'Solicitar código OTP para recuperação de senha via SMS/WhatsApp',
    description: 'Gera código OTP e envia para o telefone cadastrado do usuário'
  })
  @ApiResponse({ status: 200, description: 'Código OTP enviado com sucesso' })
  @ApiResponse({ status: 404, description: 'CPF não encontrado' })
  @ApiResponse({ status: 400, description: 'Telefone não cadastrado ou erro na requisição' })
  async requestPasswordResetOtp(@Body() dto: RequestPasswordResetOtpDto) {
    try {
      // 1. Buscar usuário por CPF
      const userData = await this.usersService.findByCpf(dto.cpf);
      
      if (!userData || !userData.id) {
        throw new NotFoundException('CPF não encontrado');
      }

      // 2. Verificar se tem telefone cadastrado
      if (!userData.phone) {
        throw new BadRequestException('Telefone não cadastrado. Use a opção de recuperação por email.');
      }

      // 3. Gerar código OTP
      const { otpCode, expiresAt } = await this.otpService.createOtp(userData.id, userData.phone);

      // 4. Enviar via SMS/WhatsApp
      if (!this.smsService.isConfigured()) {
        throw new BadRequestException('Serviço de SMS não configurado. Contate o suporte.');
      }

      const sendResult = await this.smsService.sendOtp(userData.phone, otpCode);

      if (!sendResult.success) {
        throw new BadRequestException(`Erro ao enviar código: ${sendResult.error}`);
      }

      return {
        success: true,
        message: `Código enviado com sucesso via ${sendResult.method === 'whatsapp' ? 'WhatsApp' : 'SMS'}`,
        expires_at: expiresAt.toISOString(),
        // Não retornar o código em produção (apenas para debug/teste)
        // otp_code: otpCode, // REMOVER EM PRODUÇÃO
      };
    } catch (error) {
      throw error;
    }
  }

  @Post('verify-password-reset-otp')
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 requests por minuto
  @ApiOperation({ 
    summary: 'Verificar código OTP e obter token temporário',
    description: 'Valida código OTP e retorna token temporário para mudança de senha'
  })
  @ApiResponse({ status: 200, description: 'Código OTP verificado com sucesso' })
  @ApiResponse({ status: 401, description: 'Código OTP inválido ou expirado' })
  @ApiResponse({ status: 404, description: 'CPF não encontrado' })
  async verifyPasswordResetOtp(@Body() dto: VerifyPasswordResetOtpDto) {
    try {
      // 1. Buscar usuário por CPF
      const userData = await this.usersService.findByCpf(dto.cpf);
      
      if (!userData || !userData.id) {
        throw new NotFoundException('CPF não encontrado');
      }

      // 2. Verificar código OTP
      const token = await this.otpService.verifyOtp(userData.id, dto.otp_code);

      return {
        success: true,
        message: 'Código OTP verificado com sucesso',
        token, // Token temporário para mudança de senha
        expires_in: 900, // 15 minutos em segundos
      };
    } catch (error) {
      throw error;
    }
  }

  @Post('change-password-with-otp')
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 requests por minuto
  @ApiOperation({ 
    summary: 'Alterar senha usando token OTP',
    description: 'Altera senha do usuário após verificação do OTP. Requer senha antiga e nova senha.'
  })
  @ApiResponse({ status: 200, description: 'Senha alterada com sucesso' })
  @ApiResponse({ status: 401, description: 'Token inválido ou senha antiga incorreta' })
  async changePasswordWithOtp(@Body() dto: ChangePasswordWithOtpDto) {
    try {
      // 1. Validar token temporário
      const tokenValidation = await this.otpService.validateTempToken(dto.token);
      
      if (!tokenValidation.valid) {
        throw new UnauthorizedException('Token inválido ou expirado');
      }

      const userId = tokenValidation.userId;

      // 2. Buscar usuário
      const userData = await this.usersService.findById(userId);
      if (!userData) {
        throw new NotFoundException('Usuário não encontrado');
      }

      // 3. Verificar senha antiga
      // Nota: A validação da senha antiga será feita no frontend usando Firebase Auth
      // Por enquanto, apenas verificamos se o token OTP é válido (que já validou a identidade)
      const isOldPasswordValid = await this.usersService.verifyPasswordInternal(userId, dto.old_password);
      
      if (!isOldPasswordValid) {
        throw new UnauthorizedException('Senha atual incorreta');
      }

      // 4. Atualizar senha
      await this.usersService.updatePassword(userId, dto.new_password);

      // 5. Invalidar token
      await this.otpService.invalidateToken(dto.token);

      return {
        success: true,
        message: 'Senha alterada com sucesso',
      };
    } catch (error) {
      throw error;
    }
  }

  @Post('check-cpf')
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // 10 requests por minuto
  @ApiOperation({ 
    summary: 'Verificar se CPF já está cadastrado',
    description: 'Verifica se um CPF já existe no sistema. Retorna true se existe, false se não existe.'
  })
  @ApiResponse({ status: 200, description: 'CPF verificado com sucesso' })
  @ApiResponse({ status: 400, description: 'CPF inválido' })
  async checkCpf(@Body() dto: CheckCpfDto) {
    try {
      const userData = await this.usersService.findByCpf(dto.cpf);
      
      return {
        success: true,
        exists: !!userData,
        message: userData ? 'CPF já cadastrado' : 'CPF não cadastrado',
      };
    } catch (error: any) {
      // Se NotFoundException, significa que não existe
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

  @Post('request-registration-otp')
  @Throttle({ default: { limit: 3, ttl: 120000 } }) // 3 requests por 2 minutos
  @ApiOperation({ 
    summary: 'Solicitar código OTP para cadastro via WhatsApp',
    description: 'Gera código OTP e envia via WhatsApp usando Ycloud para usuários em processo de cadastro'
  })
  @ApiResponse({ status: 200, description: 'Código OTP enviado com sucesso' })
  @ApiResponse({ status: 400, description: 'CPF já cadastrado ou erro na requisição' })
  async requestRegistrationOtp(@Body() dto: RequestRegistrationOtpDto) {
    try {
      // 1. Verificar se CPF já está cadastrado
      try {
        const userData = await this.usersService.findByCpf(dto.cpf);
        if (userData) {
          throw new BadRequestException('CPF já cadastrado. Use a opção de login.');
        }
      } catch (error: any) {
        // Se NotFoundException, CPF não existe - OK para cadastro
        if (error.status !== 404) {
          throw error;
        }
      }

      // 2. Gerar código OTP
      const { otpCode, expiresAt } = await this.otpService.createRegistrationOtp(dto.cpf, dto.phone);

      // 3. Enviar via Ycloud WhatsApp
      if (!this.ycloudService.isConfigured()) {
        throw new BadRequestException('Serviço de WhatsApp não configurado. Contate o suporte.');
      }

      const sendResult = await this.ycloudService.sendOtp(dto.phone, otpCode);

      if (!sendResult.success) {
        throw new BadRequestException(`Erro ao enviar código: ${sendResult.error}`);
      }

      return {
        success: true,
        message: 'Código enviado com sucesso via WhatsApp',
        expires_at: expiresAt.toISOString(),
        // Não retornar o código em produção
        // otp_code: otpCode, // REMOVER EM PRODUÇÃO
      };
    } catch (error) {
      throw error;
    }
  }

  @Post('verify-registration-otp')
  @Throttle({ default: { limit: 5, ttl: 60000 } }) // 5 requests por minuto
  @ApiOperation({ 
    summary: 'Verificar código OTP de cadastro',
    description: 'Valida código OTP enviado via WhatsApp durante o processo de cadastro'
  })
  @ApiResponse({ status: 200, description: 'Código OTP verificado com sucesso' })
  @ApiResponse({ status: 401, description: 'Código OTP inválido ou expirado' })
  async verifyRegistrationOtp(@Body() dto: VerifyRegistrationOtpDto) {
    try {
      // Verificar código OTP
      await this.otpService.verifyRegistrationOtp(dto.cpf, dto.phone, dto.otp_code);

      return {
        success: true,
        message: 'Código OTP verificado com sucesso',
      };
    } catch (error) {
      throw error;
    }
  }
}

