import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { EmailTemplateService } from './email-template.service';
import { EmailSenderService } from './email-sender.service';
import { AuthController } from './auth.controller';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [ConfigModule, UsersModule],
  controllers: [AuthController],
  providers: [EmailTemplateService, EmailSenderService],
  exports: [EmailTemplateService, EmailSenderService],
})
export class AuthModule {}
