import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';
import * as admin from 'firebase-admin';
import * as fs from 'fs';
import * as os from 'os';
import * as path from 'path';
import { FirebaseCICredential } from './firebase-ci-credential';

// Inicializar Firebase Admin
if (!admin.apps.length) {
  try {
    const projectId = process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT || 'pagpagapp';
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT;
    const firebaseCiToken = process.env.FIREBASE_CI_TOKEN;
    const googleCredentialsJson = process.env.GOOGLE_CREDENTIALS_JSON;
    const isCloudRun = !!process.env.K_SERVICE;

    console.log('🔧 Inicializando Firebase Admin...');
    console.log(`📋 Project ID: ${projectId}`);

    if (serviceAccountJson) {
      // Opção 1: Service Account JSON (melhor para produção)
      console.log('📋 Modo: SERVICE_ACCOUNT');
      admin.initializeApp({
        credential: admin.credential.cert(JSON.parse(serviceAccountJson)),
        projectId,
      });
    } else if (firebaseCiToken) {
      // Opção 2: Firebase CI Token (gerado via `npx firebase login:ci`)
      // Não expira por RAPT e não requer Service Account key
      console.log('📋 Modo: FIREBASE_CI_TOKEN');
      const ciCredential = new FirebaseCICredential(firebaseCiToken);
      admin.initializeApp({
        credential: ciCredential as any,
        projectId,
      });
      // Modo REST necessário para credenciais OAuth-based
      admin.firestore().settings({ preferRest: true });
    } else if (googleCredentialsJson) {
      // Opção 3: ADC JSON via env var (Railway / hosting externo)
      console.log('📋 Modo: GOOGLE_CREDENTIALS_JSON (Railway/externo)');
      console.warn('⚠️ Credencial de usuário OAuth — pode expirar por RAPT. Prefira FIREBASE_CI_TOKEN.');
      const credPath = path.join(os.tmpdir(), 'gcloud-credentials.json');
      fs.writeFileSync(credPath, googleCredentialsJson, { mode: 0o600 });
      process.env.GOOGLE_APPLICATION_CREDENTIALS = credPath;
      admin.initializeApp({ projectId });
      admin.firestore().settings({ preferRest: true });
    } else if (isCloudRun) {
      // Opção 4: Cloud Run ADC
      console.log('📋 Modo: ADC (Cloud Run)');
      admin.initializeApp({ projectId });
    } else {
      // Opção 5: Dev local ADC
      console.log('📋 Modo: ADC (desenvolvimento local)');
      admin.initializeApp({ projectId });
    }

    admin.firestore();
    console.log('✅ Firebase Admin inicializado com sucesso');
  } catch (error: any) {
    console.error('❌ Erro ao inicializar Firebase Admin:', error.message);
    try {
      admin.initializeApp();
      console.log('✅ Firebase Admin inicializado com credenciais padrão (fallback)');
    } catch (fallbackError: any) {
      console.error('❌ Falha total ao inicializar Firebase Admin:', fallbackError.message);
      console.error('💡 Opções de autenticação:');
      console.error('   1. FIREBASE_SERVICE_ACCOUNT=<json> (Service Account Key)');
      console.error('   2. FIREBASE_CI_TOKEN=<token> (via npx firebase login:ci)');
      console.error('   3. GOOGLE_CREDENTIALS_JSON=<json> (ADC JSON - pode expirar)');
      console.error('   4. gcloud auth application-default login (dev local)');
      throw fallbackError;
    }
  }
}

async function bootstrap() {
  try {
    console.log('🚀 Iniciando aplicação NestJS...');
    console.log(`📋 Ambiente: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🔌 Porta: ${process.env.PORT || 8080}`);

    const app = await NestFactory.create(AppModule);

    // Security
    app.use(helmet());
    
    // CORS
    app.enableCors({
      origin: process.env.ALLOWED_ORIGINS?.split(',') || '*',
      credentials: true,
    });

    // Global exception filter para logar erros detalhados
    app.useGlobalFilters({
      catch(exception: any, host: any) {
        const ctx = host.switchToHttp();
        const response = ctx.getResponse();
        const request = ctx.getRequest();
        
        console.error('❌ ERRO CAPTURADO:', {
          path: request.url,
          method: request.method,
          error: exception.message,
          stack: exception.stack,
          status: exception.status || 500,
        });
        
        const status = exception.status || 500;
        response.status(status).json({
          statusCode: status,
          message: exception.message || 'Internal server error',
          ...(process.env.NODE_ENV === 'development' && { stack: exception.stack }),
        });
      },
    });

    // Global validation pipe
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        forbidNonWhitelisted: true,
        transform: true,
      }),
    );

    // Swagger documentation
    const config = new DocumentBuilder()
      .setTitle('Neves Capital API')
      .setDescription('API Backend for Neves Capital - Firebase')
      .setVersion('1.0')
      .addApiKey({ type: 'apiKey', name: 'x-api-key', in: 'header' }, 'api-key')
      .build();
    
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document);

    // Port
    const port = process.env.PORT || 8080;
    await app.listen(port, '0.0.0.0'); // Ouvi em todas as interfaces (necessário para Cloud Run)

    console.log(`✅ API rodando na porta ${port}`);
    console.log(`📚 Documentação: http://localhost:${port}/api/docs`);
    console.log(`💚 Health check: http://localhost:${port}/health`);
  } catch (error) {
    console.error('❌ Erro ao iniciar aplicação:', error);
    process.exit(1);
  }
}

bootstrap();

