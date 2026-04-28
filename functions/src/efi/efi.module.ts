import { Module } from '@nestjs/common';
import { EfiConfigService } from './efi-config.service';
import { EfiAuthService } from './efi-auth.service';
import { EfiPixService } from './efi-pix.service';
import { EfiTestController } from './efi-test.controller';

@Module({
  controllers: [EfiTestController],
  providers: [EfiConfigService, EfiAuthService, EfiPixService],
  exports: [EfiPixService, EfiAuthService, EfiConfigService],
})
export class EfiModule {}
