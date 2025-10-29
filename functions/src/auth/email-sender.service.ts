import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EmailTemplateService } from './email-template.service';
import * as admin from 'firebase-admin';

/**
 * Serviço para enviar emails customizados
 * 
 * NOTA: Este serviço requer um provedor de email (SendGrid, AWS SES, etc.)
 * Configure as variáveis de ambiente no .env
 */
@Injectable()
export class EmailSenderService {
  constructor(
    private readonly emailTemplateService: EmailTemplateService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Envia email de redefinição de senha customizado
   * 
   * Alternativas de provedores:
   * 1. SendGrid (https://sendgrid.com) - Free tier: 100 emails/dia
   * 2. AWS SES (https://aws.amazon.com/ses/) - Free tier: 62k emails/mês
   * 3. Resend (https://resend.com) - Free tier: 3k emails/mês
   * 4. Nodemailer com SMTP próprio
   */
  async sendPasswordResetEmail(
    email: string,
    actionCodeSettings?: admin.auth.ActionCodeSettings,
  ): Promise<void> {
    try {
      // 1. Gerar link de reset usando Firebase Admin SDK
      const resetLink = await this.emailTemplateService.generatePasswordResetLink(
        email,
        actionCodeSettings,
      );

      // 2. Obter template HTML
      const htmlContent = this.emailTemplateService.getPasswordResetTemplate(resetLink, email);

      // 3. Enviar email via provedor configurado
      const emailProvider = this.configService.get<string>('EMAIL_PROVIDER', 'sendgrid');

      switch (emailProvider) {
        case 'sendgrid':
          await this.sendViaSendGrid(email, htmlContent);
          break;
        case 'aws-ses':
          await this.sendViaAwsSes(email, htmlContent);
          break;
        case 'resend':
          await this.sendViaResend(email, htmlContent);
          break;
        default:
          console.warn(`Provedor de email ${emailProvider} não configurado. Email não enviado.`);
          throw new Error(`Email provider ${emailProvider} não configurado`);
      }

      console.log(`✅ Email de reset enviado para: ${email}`);
    } catch (error) {
      console.error('❌ Erro ao enviar email de reset:', error);
      throw error;
    }
  }

  /**
   * Enviar via SendGrid
   * npm install @sendgrid/mail
   */
  private async sendViaSendGrid(email: string, htmlContent: string): Promise<void> {
    const sendgrid = require('@sendgrid/mail');
    const apiKey = this.configService.get<string>('SENDGRID_API_KEY');
    
    if (!apiKey) {
      throw new Error('SENDGRID_API_KEY não configurada');
    }

    sendgrid.setApiKey(apiKey);

    const msg = {
      to: email,
      from: this.configService.get<string>('EMAIL_FROM', 'noreply@pagpag.com.br'),
      subject: 'Redefinir Senha - Pag Pag',
      html: htmlContent,
    };

    await sendgrid.send(msg);
  }

  /**
   * Enviar via AWS SES
   * npm install @aws-sdk/client-ses
   */
  private async sendViaAwsSes(email: string, htmlContent: string): Promise<void> {
    const { SESClient, SendEmailCommand } = require('@aws-sdk/client-ses');

    const sesClient = new SESClient({
      region: this.configService.get<string>('AWS_REGION', 'us-east-1'),
      credentials: {
        accessKeyId: this.configService.get<string>('AWS_ACCESS_KEY_ID'),
        secretAccessKey: this.configService.get<string>('AWS_SECRET_ACCESS_KEY'),
      },
    });

    const command = new SendEmailCommand({
      Source: this.configService.get<string>('EMAIL_FROM', 'noreply@pagpag.com.br'),
      Destination: { ToAddresses: [email] },
      Message: {
        Subject: { Data: 'Redefinir Senha - Pag Pag' },
        Body: { Html: { Data: htmlContent } },
      },
    });

    await sesClient.send(command);
  }

  /**
   * Enviar via Resend
   * npm install resend
   */
  private async sendViaResend(email: string, htmlContent: string): Promise<void> {
    const { Resend } = require('resend');
    const apiKey = this.configService.get<string>('RESEND_API_KEY');

    if (!apiKey) {
      throw new Error('RESEND_API_KEY não configurada');
    }

    const resend = new Resend(apiKey);

    await resend.emails.send({
      from: this.configService.get<string>('EMAIL_FROM', 'noreply@pagpag.com.br'),
      to: email,
      subject: 'Redefinir Senha - Pag Pag',
      html: htmlContent,
    });
  }
}

