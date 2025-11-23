-- Migration: Criar tabela para códigos OTP de recuperação de senha
-- Arquivo: functions/src/database/migrations/002_create_password_reset_otps.sql

CREATE TABLE IF NOT EXISTS password_reset_otps (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  phone VARCHAR(500) NOT NULL, -- telefone para onde foi enviado (criptografado)
  otp_code_hash VARCHAR(255) NOT NULL, -- hash do código OTP (SHA256)
  otp_code VARCHAR(6) NOT NULL, -- código OTP original (será deletado após uso)
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  verified BOOLEAN DEFAULT FALSE,
  attempts INTEGER DEFAULT 0, -- tentativas de verificação
  reset_token VARCHAR(255), -- token temporário gerado após verificação do OTP
  token_expires_at TIMESTAMP WITH TIME ZONE, -- expiração do token (15 minutos)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  verified_at TIMESTAMP WITH TIME ZONE,
  
  CONSTRAINT fk_password_reset_otp_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Índices para performance
CREATE INDEX IF NOT EXISTS idx_password_reset_otp_user_id ON password_reset_otps(user_id);
CREATE INDEX IF NOT EXISTS idx_password_reset_otp_code_hash ON password_reset_otps(otp_code_hash);
CREATE INDEX IF NOT EXISTS idx_password_reset_otp_expires ON password_reset_otps(expires_at);
CREATE INDEX IF NOT EXISTS idx_password_reset_otp_verified ON password_reset_otps(verified);

-- Índice composto para buscas rápidas
CREATE INDEX IF NOT EXISTS idx_password_reset_otp_user_verified ON password_reset_otps(user_id, verified, expires_at);

-- Comentários
COMMENT ON TABLE password_reset_otps IS 'Armazena códigos OTP para recuperação de senha via SMS/WhatsApp';
COMMENT ON COLUMN password_reset_otps.otp_code_hash IS 'Hash SHA256 do código OTP para comparação segura';
COMMENT ON COLUMN password_reset_otps.otp_code IS 'Código OTP original (será deletado após verificação ou expiração)';
COMMENT ON COLUMN password_reset_otps.attempts IS 'Número de tentativas de verificação do código';

