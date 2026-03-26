import { Controller, Get, Logger, OnModuleInit } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import * as admin from 'firebase-admin';

@ApiTags('Health')
@Controller('health')
export class HealthController implements OnModuleInit {
  private readonly logger = new Logger(HealthController.name);
  private readonly KEEP_ALIVE_INTERVAL = 30 * 60 * 1000; // 30 minutos

  onModuleInit() {
    // Keep-alive: faz uma escrita no Firestore a cada 30 min para manter o token OAuth ativo
    this.warmUpFirestore();
    setInterval(() => this.warmUpFirestore(), this.KEEP_ALIVE_INTERVAL);
  }

  private async warmUpFirestore() {
    try {
      const start = Date.now();
      await admin.firestore().collection('_health').doc('ping').set(
        { timestamp: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true },
      );
      this.logger.log(`🔥 Firestore keep-alive OK (${Date.now() - start}ms)`);
    } catch (error: any) {
      this.logger.warn(`⚠️ Firestore keep-alive falhou: ${error.message}`);
    }
  }

  @Get()
  @ApiOperation({ summary: 'Health check endpoint' })
  check() {
    return {
      status: 'OK',
      timestamp: new Date().toISOString(),
      service: 'Neves Capital API',
      version: '1.0.0',
    };
  }
}

