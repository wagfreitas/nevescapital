import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EmailTemplateService } from './email-template.service';
import { EmailSenderService } from './email-sender.service';
import { OtpService } from './services/otp.service';
import { SmsService } from './services/sms.service';
import { YcloudService } from './services/ycloud.service';
import { AuthController } from './auth.controller';
import { UsersModule } from '../users/users.module';
import { DatabaseModule } from '../database/database.module';
import { EncryptionService } from '../common/services/encryption.service';

@Module({
  imports: [ConfigModule, UsersModule, DatabaseModule],
  controllers: [AuthController],
  providers: [
    EmailTemplateService,
    EmailSenderService,
    OtpService,
    SmsService,
    YcloudService,
    EncryptionService,
  ],
  exports: [EmailTemplateService, EmailSenderService, OtpService, SmsService, YcloudService],
})
export class AuthModule {}
