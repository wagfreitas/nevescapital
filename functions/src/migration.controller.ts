import { Controller, Post, Inject } from '@nestjs/common';
import { Pool } from 'pg';

@Controller('migration')
export class MigrationController {
  constructor(@Inject('DATABASE_POOL') private readonly pool: Pool) {}

  @Post('setup-tables')
  async setupTables() {
    const client = await this.pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // Criar tabelas
      await client.query(`
        CREATE TABLE IF NOT EXISTS user_transactions (
          id SERIAL PRIMARY KEY,
          user_id VARCHAR(255) NOT NULL,
          pagarme_order_id VARCHAR(255) UNIQUE NOT NULL,
          pagarme_charge_id VARCHAR(255),
          amount INTEGER NOT NULL,
          status VARCHAR(50) NOT NULL,
          establishment_name VARCHAR(255),
          customer_name VARCHAR(255),
          payment_method VARCHAR(50),
          created_at TIMESTAMP DEFAULT NOW(),
          updated_at TIMESTAMP DEFAULT NOW()
        )
      `);

      await client.query(`
        CREATE TABLE IF NOT EXISTS user_balances (
          user_id VARCHAR(255) PRIMARY KEY,
          available_amount INTEGER DEFAULT 0,
          waiting_funds INTEGER DEFAULT 0,
          total_transactions INTEGER DEFAULT 0,
          last_transaction_at TIMESTAMP,
          last_updated TIMESTAMP DEFAULT NOW()
        )
      `);

      await client.query(`
        CREATE TABLE IF NOT EXISTS pagarme_sync_log (
          id SERIAL PRIMARY KEY,
          order_id VARCHAR(255) NOT NULL,
          charge_id VARCHAR(255),
          sync_status VARCHAR(50) NOT NULL,
          sync_attempts INTEGER DEFAULT 0,
          last_sync_attempt TIMESTAMP,
          error_message TEXT,
          created_at TIMESTAMP DEFAULT NOW(),
          updated_at TIMESTAMP DEFAULT NOW()
        )
      `);

      // Criar índices
      await client.query(`
        CREATE INDEX IF NOT EXISTS idx_user_transactions_user_id ON user_transactions(user_id)
      `);
      
      await client.query(`
        CREATE INDEX IF NOT EXISTS idx_user_transactions_status ON user_transactions(status)
      `);

      await client.query(`
        CREATE INDEX IF NOT EXISTS idx_pagarme_sync_order_id ON pagarme_sync_log(order_id)
      `);

      // Criar função de trigger
      await client.query(`
        CREATE OR REPLACE FUNCTION update_updated_at_column()
        RETURNS TRIGGER AS $$
        BEGIN
            NEW.updated_at = NOW();
            RETURN NEW;
        END;
        $$ language 'plpgsql'
      `);

      // Criar triggers
      await client.query(`
        DROP TRIGGER IF EXISTS update_user_transactions_updated_at ON user_transactions;
        CREATE TRIGGER update_user_transactions_updated_at 
            BEFORE UPDATE ON user_transactions 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
      `);

      await client.query(`
        DROP TRIGGER IF EXISTS update_user_balances_updated_at ON user_balances;
        CREATE TRIGGER update_user_balances_updated_at 
            BEFORE UPDATE ON user_balances 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
      `);

      await client.query(`
        DROP TRIGGER IF EXISTS update_pagarme_sync_log_updated_at ON pagarme_sync_log;
        CREATE TRIGGER update_pagarme_sync_log_updated_at 
            BEFORE UPDATE ON pagarme_sync_log 
            FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
      `);

      await client.query('COMMIT');
      
      return {
        success: true,
        message: 'Tabelas criadas com sucesso!',
        tables: ['user_transactions', 'user_balances', 'pagarme_sync_log'],
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }
}


