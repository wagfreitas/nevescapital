-- Estrutura do banco para transações por usuário
-- Arquivo: functions/src/database/migrations/001_create_user_transactions.sql

-- Tabela de transações por usuário
CREATE TABLE IF NOT EXISTS user_transactions (
  id SERIAL PRIMARY KEY,
  user_id VARCHAR(255) NOT NULL,
  pagarme_order_id VARCHAR(255) UNIQUE NOT NULL,
  pagarme_charge_id VARCHAR(255),
  amount INTEGER NOT NULL, -- valor em centavos
  status VARCHAR(50) NOT NULL, -- paid, failed, pending
  establishment_name VARCHAR(255),
  customer_name VARCHAR(255),
  payment_method VARCHAR(50), -- credit_card, debit_card, etc
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Tabela de saldos por usuário (cache para performance)
CREATE TABLE IF NOT EXISTS user_balances (
  user_id VARCHAR(255) PRIMARY KEY,
  available_amount INTEGER DEFAULT 0, -- saldo disponível em centavos
  waiting_funds INTEGER DEFAULT 0, -- valores a receber em centavos
  total_transactions INTEGER DEFAULT 0, -- total de transações
  last_transaction_at TIMESTAMP,
  last_updated TIMESTAMP DEFAULT NOW()
);

-- Tabela de sincronização com Pagar.me
CREATE TABLE IF NOT EXISTS pagarme_sync_log (
  id SERIAL PRIMARY KEY,
  order_id VARCHAR(255) NOT NULL,
  charge_id VARCHAR(255),
  sync_status VARCHAR(50) NOT NULL, -- synced, failed, pending
  sync_attempts INTEGER DEFAULT 0,
  last_sync_attempt TIMESTAMP,
  error_message TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_user_transactions_user_id ON user_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_transactions_status ON user_transactions(status);
CREATE INDEX IF NOT EXISTS idx_user_transactions_created_at ON user_transactions(created_at);
CREATE INDEX IF NOT EXISTS idx_pagarme_sync_order_id ON pagarme_sync_log(order_id);
CREATE INDEX IF NOT EXISTS idx_pagarme_sync_status ON pagarme_sync_log(sync_status);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_transactions_updated_at 
    BEFORE UPDATE ON user_transactions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_balances_updated_at 
    BEFORE UPDATE ON user_balances 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pagarme_sync_log_updated_at 
    BEFORE UPDATE ON pagarme_sync_log 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

