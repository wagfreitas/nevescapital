import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiSecurity, ApiResponse } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { VerifyPasswordDto } from './dto/verify-password.dto';
import { ApiKeyGuard } from '../common/guards/api-key.guard';

@ApiTags('Users')
@Controller('api/users')
@UseGuards(ApiKeyGuard)
@ApiSecurity('api-key')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('register')
  @Throttle({ default: { limit: 10, ttl: 60000 } }) // 10 registros por minuto
  @ApiOperation({ summary: 'Registrar novo usuário' })
  @ApiResponse({ status: 201, description: 'Usuário criado com sucesso' })
  @ApiResponse({ status: 409, description: 'CPF ou email já cadastrado' })
  @ApiResponse({ status: 400, description: 'Dados inválidos' })
  create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @Get('cpf/:cpf')
  @ApiOperation({ summary: 'Buscar usuário por CPF' })
  @ApiResponse({ status: 200, description: 'Usuário encontrado' })
  @ApiResponse({ status: 404, description: 'Usuário não encontrado' })
  findByCpf(@Param('cpf') cpf: string) {
    return this.usersService.findByCpf(cpf);
  }

  @Get('email/:email')
  @ApiOperation({ summary: 'Buscar usuário por email' })
  @ApiResponse({ status: 200, description: 'Usuário encontrado' })
  @ApiResponse({ status: 404, description: 'Usuário não encontrado' })
  async findByEmail(@Param('email') email: string) {
    // Decodificar email da URL (pode vir codificado com %40 para @, etc)
    const decodedEmail = decodeURIComponent(email);
    console.log(`📧 Email recebido na URL: ${email}`);
    console.log(`📧 Email decodificado: ${decodedEmail}`);
    return this.usersService.findByEmail(decodedEmail);
  }

  @Post('verify-password')
  @ApiOperation({ summary: 'Verificar senha do usuário' })
  @ApiResponse({ status: 200, description: 'Senha verificada' })
  @ApiResponse({ status: 404, description: 'Usuário não encontrado' })
  verifyPassword(@Body() verifyPasswordDto: VerifyPasswordDto) {
    return this.usersService.verifyPassword(verifyPasswordDto);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Atualizar dados do usuário' })
  @ApiResponse({ status: 200, description: 'Usuário atualizado' })
  @ApiResponse({ status: 404, description: 'Usuário não encontrado' })
  update(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
    return this.usersService.update(id, updateUserDto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Deletar usuário (soft delete)' })
  @ApiResponse({ status: 200, description: 'Usuário deletado' })
  @ApiResponse({ status: 404, description: 'Usuário não encontrado' })
  remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }

  @Post('sync-firebase-email')
  @ApiOperation({ summary: 'Sincronizar email do Firebase com PostgreSQL' })
  @ApiResponse({ status: 200, description: 'Email sincronizado com sucesso' })
  @ApiResponse({ status: 404, description: 'Usuário não encontrado' })
  syncFirebaseEmail(@Body() body: { cpf: string; oldEmail: string }) {
    return this.usersService.syncFirebaseEmail(body.cpf, body.oldEmail);
  }
}

