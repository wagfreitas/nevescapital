import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiSecurity, ApiResponse } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { ApiKeyGuard } from '../common/guards/api-key.guard';
import { EmailSenderService } from './email-sender.service';
import { ResetPasswordDto, ResetPasswordByCpfDto } from './dto/reset-password.dto';
import { UsersService } from '../users/users.service';

@ApiTags('Auth')
@Controller('api/auth')
@UseGuards(ApiKeyGuard)
@ApiSecurity('api-key')
export class AuthController {
  constructor(
    private readonly emailSenderService: EmailSenderService,
    private readonly usersService: UsersService,
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
}

