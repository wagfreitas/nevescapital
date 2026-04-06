import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuthJwtService } from '../firebase-rest/auth-jwt.service';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class EmailTemplateService {
  constructor(
    private readonly configService: ConfigService,
    private readonly authJwt: AuthJwtService,
  ) {}

  /**
   * Envia email de redefinição de senha via Firebase REST API
   * e retorna o email para o qual foi enviado
   */
  async generatePasswordResetLink(email: string, actionCodeSettings?: any): Promise<string> {
    // Usa Firebase REST API para enviar o reset email
    // A REST API envia o email default do Firebase — para template custom,
    // precisamos gerar um link custom com token JWT
    await this.authJwt.sendPasswordResetEmail(email);
    // Retorna uma URL genérica (o email já foi enviado pelo Firebase)
    return `https://pagpagbrasil.com.br/reset?email=${encodeURIComponent(email)}`;
  }

  /**
   * Converte logo para Base64 ou retorna URL hospedada
   */
  private getLogoSource(): string {
    // Opção 1: Usar URL do Firebase Hosting (se configurado)
    const hostedUrl = this.configService.get<string>('LOGO_HOSTED_URL', 'https://apppagpag.firebaseapp.com/assets/icons/PagPag.png');
    
    // Opção 2: Converter para Base64 inline (mais confiável)
    const logoBase64 = this.getLogoAsBase64();
    
    // Se Base64 disponível, usar (mais confiável)
    if (logoBase64) {
      return `data:image/png;base64,${logoBase64}`;
    }
    
    // Senão, usar URL hospedada
    return hostedUrl;
  }

  /**
   * Converte logo para Base64
   */
  private getLogoAsBase64(): string | null {
    const possiblePaths = [
      path.join(__dirname, '../../../assets/icons/PagPag.png'), // Desenvolvimento
      path.join(__dirname, '../../assets/icons/PagPag.png'), // Produção (compilado)
      path.join(process.cwd(), 'assets/icons/PagPag.png'), // Fallback
      path.join(process.cwd(), '../assets/icons/PagPag.png'), // Outro fallback
    ];

    for (const logoPath of possiblePaths) {
      try {
        if (fs.existsSync(logoPath)) {
          const logoBuffer = fs.readFileSync(logoPath);
          const base64 = logoBuffer.toString('base64');
          console.log(`✅ Logo carregada de: ${logoPath}`);
          return base64;
        }
      } catch (error) {
        console.warn(`⚠️ Não foi possível carregar logo de ${logoPath}:`, error);
        continue;
      }
    }

    console.warn('⚠️ Logo não encontrada localmente, usando URL hospedada');
    return null;
  }

  /**
   * Lê o template HTML de redefinição de senha
   */
  getPasswordResetTemplate(link: string, email: string): string {
    // Obter logo (Base64 ou URL)
    const logoSource = this.getLogoSource();
    
    // Tenta vários caminhos possíveis (desenvolvimento e produção)
    const possiblePaths = [
      path.join(__dirname, '../../../docs/firebase-email-templates/reset-password-template.html'), // Desenvolvimento
      path.join(__dirname, '../../docs/firebase-email-templates/reset-password-template.html'), // Produção (compilado)
      path.join(process.cwd(), 'docs/firebase-email-templates/reset-password-template.html'), // Fallback
    ];
    
    for (const templatePath of possiblePaths) {
      try {
        if (fs.existsSync(templatePath)) {
          let template = fs.readFileSync(templatePath, 'utf8');
          
          // Substituir variáveis
          template = template.replace(/%LINK%/g, link);
          template = template.replace(/%EMAIL%/g, email);
          
          // Substituir logo (substitui a URL ou base64 comentada)
          template = template.replace(
            /<img[^>]*src="[^"]*PagPag\.png[^"]*"[^>]*>/gi,
            `<img src="${logoSource}" alt="Pag Pag Logo" style="max-width: 200px; height: auto; display: block; margin: 0 auto;" width="200">`
          );
          
          console.log(`✅ Template carregado de: ${templatePath}`);
          console.log(`✅ Logo usando: ${logoSource.startsWith('data:') ? 'Base64 (inline)' : 'URL hospedada'}`);
          return template;
        }
      } catch (error) {
        console.warn(`⚠️ Não foi possível carregar template de ${templatePath}:`, error);
        continue;
      }
    }
    
    console.warn('⚠️ Template HTML não encontrado, usando fallback');
    return this.getFallbackTemplate(link, email, logoSource);
  }

  /**
   * Template HTML fallback caso o arquivo não seja encontrado
   */
  private getFallbackTemplate(link: string, email: string, logoSource?: string): string {
    const logo = logoSource || this.getLogoSource();
    
    return `
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Redefinir Senha - Pag Pag</title>
</head>
<body style="margin: 0; padding: 0; font-family: Arial, sans-serif; background-color: #f5f5f5;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 20px;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 8px; padding: 40px;">
          <tr>
            <td style="background-color: #122118; padding: 40px 30px; text-align: center; border-radius: 8px 8px 0 0;">
              <div style="text-align: center;">
                <img src="${logo}" alt="Pag Pag Logo" style="max-width: 200px; height: auto; display: block; margin: 0 auto;">
              </div>
            </td>
          </tr>
          <tr>
            <td style="padding: 40px 30px;">
              <h1 style="color: #122118; margin: 0 0 20px 0;">Redefinição de Senha</h1>
              <p style="color: #333; font-size: 16px; line-height: 1.6;">
                Olá,<br><br>
                Recebemos uma solicitação para redefinir a senha da sua conta <strong>${email}</strong> no Pag Pag.
              </p>
              <p style="margin: 30px 0; text-align: center;">
                <a href="${link}" style="background-color: #22C55E; color: #122118; text-decoration: none; padding: 14px 32px; border-radius: 25px; font-weight: 600; display: inline-block;">
                  Redefinir Senha
                </a>
              </p>
              <p style="color: #666; font-size: 14px;">
                Se você não solicitou esta redefinição, pode ignorar este email.
              </p>
            </td>
          </tr>
          <tr>
            <td style="background-color: #f9f9f9; padding: 20px; text-align: center; border-top: 1px solid #eee;">
              <p style="color: #999; font-size: 12px; margin: 0;">
                © 2024 Pag Pag. Todos os direitos reservados.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
    `;
  }
}

