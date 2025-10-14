import { Module, Global } from '@nestjs/common';
import { Pool } from 'pg';

@Global()
@Module({
  providers: [
    {
      provide: 'DATABASE_POOL',
      useFactory: () => {
        const pool = new Pool({
          host: process.env.DB_HOST,
          port: parseInt(process.env.DB_PORT || '5432'),
          database: process.env.DB_NAME,
          user: process.env.DB_USER,
          password: process.env.DB_PASSWORD,
          ssl: false, // SSL é gerenciado pelo Cloud SQL Proxy
          max: 10,
          idleTimeoutMillis: 30000,
          connectionTimeoutMillis: 2000,
        });

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

