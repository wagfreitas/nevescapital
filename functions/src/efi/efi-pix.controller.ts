import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiKeyGuard } from '../common/guards/api-key.guard';
import { EfiPixService } from './efi-pix.service';
import { SendPixDto } from './dto/send-pix.dto';

/**
 * Endpoints de produção para PIX via Efí.
 * Protegidos por ApiKeyGuard.
 */
@Controller('api/pix')
@UseGuards(ApiKeyGuard)
export class EfiPixController {
  constructor(private readonly pix: EfiPixService) {}

  @Post('send')
  @HttpCode(HttpStatus.OK)
  async sendPix(@Body() dto: SendPixDto) {
    return this.pix.sendPix(dto);
  }

  @Get('status/:idEnvio')
  async getPixStatus(@Param('idEnvio') idEnvio: string) {
    return this.pix.getPixStatus(idEnvio);
  }

  @Get('balance')
  async getBalance() {
    return this.pix.getBalance();
  }
}
