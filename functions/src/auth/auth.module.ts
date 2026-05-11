import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EmailTemplateService } from './email-template.service';
import { EmailSenderService } from './email-sender.service';
import { SimpleOtpService } from './services/simple-otp.service';
import { WhatsAppService } from './services/whatsapp.service';
import { SmsService } from './services/sms.service';
import { AuthController } from './auth.controller';
import { WhatsAppWebhookController } from './whatsapp-webhook.controller';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [ConfigModule, UsersModule],
  controllers: [AuthController, WhatsAppWebhookController],
  providers: [
    EmailTemplateService,
    EmailSenderService,
    SimpleOtpService,
    WhatsAppService,
    SmsService,
  ],
  exports: [EmailTemplateService, EmailSenderService, SimpleOtpService, WhatsAppService, SmsService],
})
export class AuthModule {}
