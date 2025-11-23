-- Tabela para armazenar OTPs de cadastro (usuários ainda não criados)
CREATE TABLE IF NOT EXISTS registration_otps (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  cpf VARCHAR(500) NOT NULL, -- CPF criptografado
  phone VARCHAR(500) NOT NULL, -- telefone criptografado
  otp_code_hash VARCHAR(255) NOT NULL, -- hash do código OTP (SHA256)
  otp_code VARCHAR(6) NOT NULL, -- código OTP original (será deletado após uso)
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  verified BOOLEAN DEFAULT FALSE,
  attempts INTEGER DEFAULT 0, -- tentativas de verificação
  verified_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Índice para busca rápida por CPF e telefone
  CONSTRAINT unique_active_registration_otp UNIQUE (cpf, phone, verified)
);

-- Índice para limpeza de OTPs expirados
CREATE INDEX IF NOT EXISTS idx_registration_otps_expires_at ON registration_otps(expires_at);

-- Índice para busca por CPF e telefone
CREATE INDEX IF NOT EXISTS idx_registration_otps_cpf_phone ON registration_otps(cpf, phone);



