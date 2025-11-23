-- Migration: Criar tabelas para dados da loja e chaves PIX
-- Arquivo: functions/src/database/migrations/003_create_user_stores_and_pix_keys.sql

-- Tabela de dados da loja do usuário
CREATE TABLE IF NOT EXISTS user_stores (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  store_name VARCHAR(255) NOT NULL, -- Nome da loja
  business_type VARCHAR(100) NOT NULL, -- Ramo de atividade
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT fk_user_store FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT unique_user_store UNIQUE (user_id)
);

-- Tabela de chaves PIX do usuário
CREATE TABLE IF NOT EXISTS user_pix_keys (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pix_key VARCHAR(255) NOT NULL, -- Chave PIX (CPF, email, telefone, chave aleatória)
  key_type VARCHAR(20) NOT NULL, -- CPF, EMAIL, PHONE, RANDOM
  is_verified BOOLEAN DEFAULT FALSE, -- Se a chave foi verificada
  is_primary BOOLEAN DEFAULT FALSE, -- Se é a chave principal
  display_order INTEGER DEFAULT 0, -- Ordem de exibição
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  CONSTRAINT fk_user_pix_key FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  CONSTRAINT unique_pix_key UNIQUE (pix_key) -- Uma chave PIX só pode ser usada uma vez
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_user_stores_user_id ON user_stores(user_id);
CREATE INDEX IF NOT EXISTS idx_user_pix_keys_user_id ON user_pix_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_user_pix_keys_key_type ON user_pix_keys(key_type);
CREATE INDEX IF NOT EXISTS idx_user_pix_keys_is_primary ON user_pix_keys(is_primary);

-- Trigger para atualizar updated_at automaticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_stores_updated_at 
    BEFORE UPDATE ON user_stores 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_pix_keys_updated_at 
    BEFORE UPDATE ON user_pix_keys 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Comentários
COMMENT ON TABLE user_stores IS 'Armazena dados da loja do usuário (nome e ramo de atividade)';
COMMENT ON TABLE user_pix_keys IS 'Armazena chaves PIX cadastradas pelo usuário';
COMMENT ON COLUMN user_pix_keys.key_type IS 'Tipo da chave: CPF, EMAIL, PHONE, RANDOM';
COMMENT ON COLUMN user_pix_keys.is_verified IS 'Indica se a chave PIX foi verificada como válida';

