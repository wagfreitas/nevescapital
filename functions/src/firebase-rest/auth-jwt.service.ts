import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';
import axios from 'axios';

export interface JwtPayload {
  sub: string; // User ID (Firestore document ID)
  phone?: string;
  email?: string;
  iat?: number;
  exp?: number;
}

@Injectable()
export class AuthJwtService {
  private readonly logger = new Logger(AuthJwtService.name);
  private readonly jwtSecret: string;
  private readonly jwtExpiresIn: string;
  private readonly apiKey: string;
  private readonly projectId: string;

  constructor(private readonly configService: ConfigService) {
    this.jwtSecret = this.configService.get<string>('JWT_SECRET', '');
    this.jwtExpiresIn = this.configService.get<string>('JWT_EXPIRES_IN', '7d');
    this.apiKey = this.configService.get<string>('FIREBASE_WEB_API_KEY', '');
    this.projectId = this.configService.get<string>('FIREBASE_PROJECT_ID', 'pagpagapp');

    if (!this.jwtSecret) {
      this.logger.warn('JWT_SECRET not set! Token signing will fail.');
    }

    this.logger.log('AuthJwtService initialized');
  }

  /**
   * Sign a JWT token (replaces admin.auth().createCustomToken)
   */
  signToken(payload: { sub: string; phone?: string; email?: string }): string {
    return jwt.sign(payload, this.jwtSecret, {
      expiresIn: this.jwtExpiresIn as any,
      issuer: 'neves-capital-api',
      audience: 'pagpag-app',
    } as jwt.SignOptions);
  }

  /**
   * Verify and decode a JWT token (replaces admin.auth().verifyIdToken)
   */
  verifyToken(token: string): JwtPayload {
    try {
      return jwt.verify(token, this.jwtSecret, {
        issuer: 'neves-capital-api',
        audience: 'pagpag-app',
      }) as JwtPayload;
    } catch (error: any) {
      this.logger.error(`JWT verification failed: ${error.message}`);
      throw new Error(`Token inválido: ${error.message}`);
    }
  }

  /**
   * Send password reset email via Firebase REST API.
   * This uses the Firebase Auth REST endpoint to send the default reset email.
   * (Replaces admin.auth().generatePasswordResetLink)
   */
  async sendPasswordResetEmail(email: string): Promise<string> {
    try {
      const res = await axios.post(
        `https://identitytoolkit.googleapis.com/v1/accounts:sendOobCode?key=${this.apiKey}`,
        {
          requestType: 'PASSWORD_RESET',
          email,
        },
      );
      this.logger.log(`Password reset email sent to ${email}`);
      return res.data.email;
    } catch (error: any) {
      const msg = error.response?.data?.error?.message || error.message;
      this.logger.error(`Failed to send password reset: ${msg}`);
      throw new Error(`Falha ao enviar reset de senha: ${msg}`);
    }
  }

  /**
   * Look up a Firebase Auth user by email via REST API.
   * Note: This requires the API key to have Identity Toolkit permissions.
   * Returns null if user not found.
   */
  async lookupUserByEmail(email: string): Promise<any | null> {
    try {
      const res = await axios.post(
        `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${this.apiKey}`,
        { email: [email] },
      );
      const users = res.data.users;
      return users && users.length > 0 ? users[0] : null;
    } catch (error: any) {
      if (error.response?.data?.error?.message === 'USER_NOT_FOUND') {
        return null;
      }
      throw error;
    }
  }
}
