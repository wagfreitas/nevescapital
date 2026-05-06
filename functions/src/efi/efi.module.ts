import { Module } from '@nestjs/common';
import { EfiConfigService } from './efi-config.service';
import { EfiAuthService } from './efi-auth.service';
import { EfiPixService } from './efi-pix.service';
import { EfiTestController } from './efi-test.controller';
import { EfiPixController } from './efi-pix.controller';
import { EfiWebhookController } from './efi-webhook.controller';

@Module({
  controllers: [EfiTestController, EfiPixController, EfiWebhookController],
  providers: [EfiConfigService, EfiAuthService, EfiPixService],
  exports: [EfiPixService, EfiAuthService, EfiConfigService],
})
export class EfiModule {}
