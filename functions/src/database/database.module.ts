import { Module, Global } from '@nestjs/common';
import { Pool } from 'pg';

@Global()
@Module({
  providers: [
    {
      provide: 'DATABASE_POOL',
      useFactory: () => {
        // Configuração para Cloud Run (Unix socket) ou desenvolvimento (host/port)
        const isCloudRun = !!process.env.INSTANCE_UNIX_SOCKET;
        
        const config: any = {
          database: process.env.DB_NAME,
          user: process.env.DB_USER,
          password: process.env.DB_PASSWORD,
          max: 10,
          idleTimeoutMillis: 30000,
          connectionTimeoutMillis: 10000, // Aumentar timeout
        };

        if (isCloudRun) {
          // Cloud Run: usar Unix socket (Cloud SQL Proxy)
          config.host = process.env.INSTANCE_UNIX_SOCKET;
          console.log(`🔌 Conectando via Unix socket: ${config.host}`);
        } else {
          // Desenvolvimento: usar host e porta
          config.host = process.env.DB_HOST;
          config.port = parseInt(process.env.DB_PORT || '5432');
          config.ssl = false;
          console.log(`🔌 Conectando via TCP: ${config.host}:${config.port}`);
        }

        const pool = new Pool(config);

        pool.on('connect', () => {
          console.log('✅ Conectado ao PostgreSQL Cloud SQL');
        });

        pool.on('error', (err) => {
          console.error('❌ Erro no pool PostgreSQL:', err);
        });

        return pool;
      },
    },
  ],
  exports: ['DATABASE_POOL'],
})
export class DatabaseModule {}

