// Declarações mínimas para evitar dependência de @types/node no lint
// ignore_for_file: constant_identifier_names

declare const process: {
  env: Record<string, string | undefined>;
};

// Classe Buffer simplificada apenas com método utilizado
declare class Buffer {
  static from(input: string, encoding: string): Buffer;
}

export interface AppConfig {
  databaseUrl: string;
  encryptionKey: Buffer;
  requireSsl: boolean;
}

export function loadConfig(): AppConfig {
  const databaseUrl = process.env.DATABASE_URL;
  if (!databaseUrl) {
    throw new Error('DATABASE_URL não configurada');
  }

  const encryptionKeyHex = process.env.ENCRYPTION_KEY;
  if (!encryptionKeyHex) {
    throw new Error('ENCRYPTION_KEY não configurada');
  }

  if (encryptionKeyHex.length !== 64) {
    throw new Error('ENCRYPTION_KEY deve conter 32 bytes em hexadecimal');
  }

  return {
    databaseUrl,
    encryptionKey: Buffer.from(encryptionKeyHex, 'hex'),
    requireSsl: process.env.DB_SSL !== 'false',
  };
}
