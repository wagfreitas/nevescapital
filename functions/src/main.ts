import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';

// Sem Firebase Admin SDK — usa Firebase REST APIs via FirebaseRestModule

async function bootstrap() {
  try {
    console.log('🚀 Iniciando aplicação NestJS...');
    console.log(`📋 Ambiente: ${process.env.NODE_ENV || 'development'}`);
    console.log(`🔌 Porta: ${process.env.PORT || 8080}`);
    console.log(`🔥 Firebase: REST API (sem Admin SDK)`);

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

        // Se for HttpException com response estruturado (objeto), preserva os campos extras.
        // Ex: BadGateway com { message, efiStatus, efiBody } → retorna tudo.
        const exceptionResponse =
          typeof exception.getResponse === 'function'
            ? exception.getResponse()
            : null;

        const baseBody =
          exceptionResponse && typeof exceptionResponse === 'object'
            ? exceptionResponse
            : { message: exception.message || 'Internal server error' };

        response.status(status).json({
          statusCode: status,
          ...baseBody,
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
      .setDescription('API Backend for Neves Capital - Firebase REST')
      .setVersion('2.0')
      .addApiKey({ type: 'apiKey', name: 'x-api-key', in: 'header' }, 'api-key')
      .build();

    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('api/docs', app, document);

    // Port
    const port = process.env.PORT || 8080;
    await app.listen(port, '0.0.0.0');

    console.log(`✅ API rodando na porta ${port}`);
    console.log(`📚 Documentação: http://localhost:${port}/api/docs`);
    console.log(`💚 Health check: http://localhost:${port}/health`);
  } catch (error) {
    console.error('❌ Erro ao iniciar aplicação:', error);
    process.exit(1);
  }
}

bootstrap();
