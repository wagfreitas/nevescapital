import { Controller, Get, Logger, OnModuleInit } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { FirestoreRestService } from './firebase-rest/firestore-rest.service';
import { serverTimestamp } from './firebase-rest/firestore-rest.utils';

@ApiTags('Health')
@Controller('health')
export class HealthController implements OnModuleInit {
  private readonly logger = new Logger(HealthController.name);
  private readonly KEEP_ALIVE_INTERVAL = 30 * 60 * 1000; // 30 minutos

  constructor(private readonly firestore: FirestoreRestService) {}

  onModuleInit() {
    // Keep-alive: faz uma escrita no Firestore a cada 30 min
    this.warmUpFirestore();
    setInterval(() => this.warmUpFirestore(), this.KEEP_ALIVE_INTERVAL);
  }

  private async warmUpFirestore() {
    try {
      const start = Date.now();
      await this.firestore.setDocument('_health', 'ping', {
        timestamp: serverTimestamp(),
      }, true);
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
