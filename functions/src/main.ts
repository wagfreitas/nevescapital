import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';
import * as admin from 'firebase-admin';

// Inicializar Firebase Admin
if (!admin.apps.length) {
  try {
    // No Cloud Run, o Admin SDK usa automaticamente as credenciais do serviço via Application Default Credentials (ADC)
    // Em desenvolvimento local, precisa de: gcloud auth application-default login
    // O projectId deve corresponder ao projeto do Firebase/Google Cloud
    // Project ID deve ser 'pagpagapp' (conforme deploy script)
    const projectId = process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT || 'pagpagapp';
    
    console.log('🔧 Inicializando Firebase Admin...');
    console.log(`📋 Project ID: ${projectId}`);
    console.log(`📋 GOOGLE_CLOUD_PROJECT: ${process.env.GOOGLE_CLOUD_PROJECT || 'não definido'}`);
    console.log(`📋 GCLOUD_PROJECT: ${process.env.GCLOUD_PROJECT || 'não definido'}`);
    console.log(`📋 GOOGLE_APPLICATION_CREDENTIALS: ${process.env.GOOGLE_APPLICATION_CREDENTIALS || 'não definido (usando ADC)'}`);
    
    // Verificar se está em ambiente local ou Cloud Run
    const isLocal = !process.env.K_SERVICE && !process.env.GOOGLE_CLOUD_PROJECT;
    console.log(`📋 Ambiente: ${isLocal ? 'LOCAL (desenvolvimento)' : 'CLOUD RUN (produção)'}`);
    
    // Inicializar com projectId explícito
    // No Cloud Run, as credenciais são obtidas automaticamente via ADC
    // Em local, também usa ADC se configurado via: gcloud auth application-default login
    admin.initializeApp({
      projectId: projectId,
      // Não especificar credential - usa ADC automaticamente (Cloud Run ou local com ADC configurado)
    });
    
    // Verificar se o Firestore está acessível
    const db = admin.firestore();
    console.log('✅ Firebase Admin inicializado com sucesso');
    console.log('✅ Firestore instance criada');
    
    // Verificar credenciais sendo usadas
    const app = admin.app();
    console.log(`📋 App name: ${app.name}`);
    console.log(`📋 App options: ${JSON.stringify({ projectId: app.options.projectId, credential: app.options.credential ? 'definido' : 'não definido' })}`);
    
    // Testar acesso ao Firestore (apenas em desenvolvimento, não bloqueia inicialização)
    if (process.env.NODE_ENV !== 'production' && !process.env.K_SERVICE) {
      console.log('🧪 Testando acesso ao Firestore (assíncrono)...');
      // Tentar uma operação simples de leitura para verificar permissões (não bloqueia)
      const testRef = db.collection('_test').doc('_connection_test');
      testRef.get()
        .then(() => {
          console.log('✅ Teste de conexão ao Firestore: OK');
        })
        .catch((testError: any) => {
          console.error('❌ Erro ao testar conexão com Firestore:', testError.message);
          console.error('💡 Verifique se você tem permissões IAM no projeto pagpagapp');
          console.error('💡 Execute: gcloud projects get-iam-policy pagpagapp');
          // Não lançar erro aqui, apenas logar - pode ser que o teste falhe mas o app funcione
        });
    }
    
  } catch (error: any) {
    console.error('❌ Erro ao inicializar Firebase Admin:', error.message);
    console.error('❌ Stack:', error.stack);
    
    // Tentar inicializar sem opções (usa credenciais padrão do ambiente)
    try {
      console.log('🔄 Tentando inicializar com credenciais padrão...');
      admin.initializeApp();
      console.log('✅ Firebase Admin inicializado com credenciais padrão');
    } catch (fallbackError: any) {
      console.error('❌ Erro ao inicializar Firebase Admin (fallback):', fallbackError.message);
      console.error('❌ Stack:', fallbackError.stack);
      console.error('');
      console.error('💡 SOLUÇÃO: Para desenvolvimento local, execute:');
      console.error('   gcloud auth application-default login');
      console.error('   gcloud config set project pagpagapp');
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

