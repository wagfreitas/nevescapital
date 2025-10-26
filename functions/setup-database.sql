-- Script SQL para executar no Cloud SQL
-- Execute este script no Cloud SQL para criar as tabelas necessárias

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

-- Aplicar triggers
DROP TRIGGER IF EXISTS update_user_transactions_updated_at ON user_transactions;
CREATE TRIGGER update_user_transactions_updated_at 
    BEFORE UPDATE ON user_transactions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_balances_updated_at ON user_balances;
CREATE TRIGGER update_user_balances_updated_at 
    BEFORE UPDATE ON user_balances 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_pagarme_sync_log_updated_at ON pagarme_sync_log;
CREATE TRIGGER update_pagarme_sync_log_updated_at 
    BEFORE UPDATE ON pagarme_sync_log 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Inserir dados de teste (opcional)
INSERT INTO user_transactions (
  user_id, pagarme_order_id, pagarme_charge_id, amount, 
  status, establishment_name, customer_name, payment_method
) VALUES (
  'test_user_123', 'ORDER_TEST_001', 'CHARGE_TEST_001', 1000,
  'paid', 'Loja Teste', 'Cliente Teste', 'credit_card'
) ON CONFLICT (pagarme_order_id) DO NOTHING;

-- Atualizar saldo do usuário de teste
INSERT INTO user_balances (user_id, available_amount, waiting_funds, total_transactions, last_transaction_at)
SELECT 
  'test_user_123',
  COALESCE(SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END), 0),
  COALESCE(SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END), 0),
  COUNT(*),
  MAX(created_at)
FROM user_transactions 
WHERE user_id = 'test_user_123'
ON CONFLICT (user_id) 
DO UPDATE SET
  available_amount = EXCLUDED.available_amount,
  waiting_funds = EXCLUDED.waiting_funds,
  total_transactions = EXCLUDED.total_transactions,
  last_transaction_at = EXCLUDED.last_transaction_at,
  last_updated = NOW();

-- Verificar se as tabelas foram criadas
SELECT 'Tabelas criadas com sucesso!' as status;
SELECT COUNT(*) as total_transactions FROM user_transactions;
SELECT COUNT(*) as total_balances FROM user_balances;


