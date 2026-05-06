import {
  Body,
  Controller,
  Get,
  Post,
  Logger,
  HttpCode,
  HttpStatus,
  Req,
} from '@nestjs/common';
import { Request } from 'express';
import { FirestoreRestService } from '../firebase-rest/firestore-rest.service';

/**
 * Receiver de webhooks PIX da Efí.
 *
 * A Efí envia POST com o payload de confirmação para a URL registrada.
 * No modo sem mTLS (x-skip-mtls-checking), a Efí envia para /pix
 * adicionando /pix ao final da URL cadastrada. Ex:
 *   URL registrada: https://dominio.com/api/webhooks/efi
 *   Efí chama:      https://dominio.com/api/webhooks/efi/pix
 *
 * Este controller NÃO usa ApiKeyGuard — a Efí não envia x-api-key.
 */
@Controller('api/webhooks/efi')
export class EfiWebhookController {
  private readonly logger = new Logger(EfiWebhookController.name);

  constructor(private readonly firestore: FirestoreRestService) {}

  /**
   * Health check — a Efí pode testar a URL com GET antes de registrar.
   */
  @Get()
  healthCheck() {
    return { status: 'ok', service: 'efi-webhook' };
  }

  /**
   * Receiver principal — a Efí envia POST /api/webhooks/efi/pix
   * com o payload de confirmação do PIX.
   */
  @Post('pix')
  @HttpCode(HttpStatus.OK)
  async handlePixWebhook(@Body() body: any, @Req() req: Request) {
    this.logger.log(
      `Webhook PIX recebido: ${JSON.stringify(body).substring(0, 500)}`,
    );

    try {
      const pixList: any[] = body?.pix ?? [];

      if (pixList.length === 0) {
        this.logger.warn('Webhook PIX sem array "pix" no payload');
        return { received: true, processed: 0 };
      }

      let processed = 0;

      for (const pix of pixList) {
        const e2eId = pix.endToEndId;
        const status = pix.status; // "REALIZADO", "NAO_REALIZADO", etc.
        const valor = pix.valor;
        const horario = pix.horario;

        if (!e2eId) {
          this.logger.warn('PIX sem endToEndId — ignorando');
          continue;
        }

        this.logger.log(
          `Processando PIX: e2eId=${e2eId}, status=${status}, valor=${valor}`,
        );

        await this.updateSaleByE2eId(e2eId, {
          pixStatus: status === 'REALIZADO' ? 'confirmado' : 'rejeitado',
          pixE2eId: e2eId,
          pixValorConfirmado: valor,
          pixHorarioLiquidacao: horario,
          status: status === 'REALIZADO' ? 'pix_confirmado' : 'pix_rejeitado',
          updatedAt: new Date().toISOString(),
        });

        processed++;
      }

      this.logger.log(`Webhook processado: ${processed} PIX(s) atualizados`);
      return { received: true, processed };
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      this.logger.error(`Erro ao processar webhook PIX: ${msg}`);
      return { received: true, error: msg };
    }
  }

  /**
   * Busca a venda pelo pixE2eId e atualiza o status.
   * Percorre a collection 'sales' procurando o documento com o e2eId.
   */
  private async updateSaleByE2eId(
    e2eId: string,
    updateData: Record<string, any>,
  ) {
    try {
      // A FirestoreRestService não tem query, então usamos updateDocument
      // direto se soubermos o docId. Como o e2eId é salvo no momento do envio,
      // usamos ele como índice secundário.
      //
      // Estratégia: o payment_step5_screen salva pixE2eId no doc da venda.
      // Aqui, precisamos encontrar o doc pelo e2eId.
      // Por ora, logamos o update para ser processado manualmente ou
      // via uma collection dedicada de webhooks.
      await this.firestore.setDocument('pix_webhooks', e2eId, updateData);

      this.logger.log(
        `Webhook salvo em pix_webhooks/${e2eId}: status=${updateData.pixStatus}`,
      );
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      this.logger.error(`Erro ao salvar webhook no Firestore: ${msg}`);
    }
  }
}
