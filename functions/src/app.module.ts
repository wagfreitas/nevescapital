import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { UsersModule } from './users/users.module';
import { AuthModule } from './auth/auth.module';
import { HealthController } from './health.controller';
import { FirebaseRestModule } from './firebase-rest/firebase-rest.module';

@Module({
  imports: [
    // Configuration
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // Rate limiting
    ThrottlerModule.forRoot([{
      ttl: 60000, // 1 minuto
      limit: 100, // 100 requests
    }]),

    // Firebase REST Services (replaces firebase-admin)
    FirebaseRestModule,

    // Modules
    UsersModule,
    AuthModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}

