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
import { EfiAuthService } from './efi-auth.service';
import { EfiConfigService } from './efi-config.service';
import { SendPixDto } from './dto/send-pix.dto';

/**
 * Endpoints internos para validar a integração Efí no spike.
 * Protegidos por ApiKeyGuard — requer header `x-api-key: <API_KEY>`.
 *
 * Uso típico:
 *   curl -X POST http://localhost:8080/api/_internal/efi/test/auth \
 *     -H "x-api-key: $API_KEY"
 */
@Controller('api/_internal/efi/test')
@UseGuards(ApiKeyGuard)
export class EfiTestController {
  constructor(
    private readonly pix: EfiPixService,
    private readonly auth: EfiAuthService,
    private readonly config: EfiConfigService,
  ) {}

  /** Smoke test: confere config e tenta obter um access_token. */
  @Get('auth')
  async testAuth() {
    const token = await this.auth.getAccessToken();
    return {
      ok: true,
      ambiente: this.config.ambiente,
      baseUrl: this.config.baseUrl,
      tokenPrefix: token.substring(0, 12) + '...',
    };
  }

  /** Consulta saldo da conta Efí. */
  @Get('balance')
  async balance() {
    return this.pix.getBalance();
  }

  /** Dispara um PIX. */
  @Post('pix')
  @HttpCode(HttpStatus.OK)
  async sendPix(@Body() dto: SendPixDto) {
    return this.pix.sendPix(dto);
  }

  /** Consulta status de um PIX enviado. */
  @Get('pix/:idEnvio')
  async getPixStatus(@Param('idEnvio') idEnvio: string) {
    return this.pix.getPixStatus(idEnvio);
  }

  /**
   * Consulta webhook registrado em uma chave do pagador.
   * Use isso primeiro pra ver se a chave já tem webhook.
   */
  @Get('webhook/:chave')
  async getWebhook(@Param('chave') chave: string) {
    return this.pix.getWebhook(chave);
  }

  /**
   * Registra webhook na chave PIX do pagador.
   * Pré-requisito pra disparar PIX-out via API.
   *
   * Body: { "chave": "...", "webhookUrl": "https://..." }
   */
  @Post('webhook')
  @HttpCode(HttpStatus.OK)
  async registerWebhook(
    @Body() body: { chave: string; webhookUrl: string },
  ) {
    return this.pix.registerWebhook(body.chave, body.webhookUrl);
  }
}
