declare function require(module: string): any;

const { Pool } = require('pg');

import { loadConfig } from './config';
import { encrypt, decrypt } from './crypto';

const config = loadConfig();

const pool = new Pool({
  connectionString: config.databaseUrl,
  ssl: config.requireSsl ? { rejectUnauthorized: false } : undefined,
});

interface UserRecord {
  id: string;
  firebase_uid: string;
  email: string;
  name: string;
  phone_encrypted: string | null;
  document_encrypted: string | null;
  created_at: string;
  updated_at: string;
}

export async function upsertUser(params: {
  firebaseUid: string;
  email: string;
  name: string;
  phone?: string | null;
  document?: string | null;
}): Promise<UserRecord> {
  const client = await pool.connect();
  try {
    const result = await client.query(
      `INSERT INTO users (
         firebase_uid, email, name, phone_encrypted, document_encrypted
       ) VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (firebase_uid) DO UPDATE SET
         email = EXCLUDED.email,
         name = EXCLUDED.name,
         phone_encrypted = EXCLUDED.phone_encrypted,
         document_encrypted = EXCLUDED.document_encrypted,
         updated_at = NOW()
       RETURNING *;`,
      [
        params.firebaseUid,
        params.email,
        params.name,
        params.phone ? encrypt(params.phone, config.encryptionKey) : null,
        params.document ? encrypt(params.document, config.encryptionKey) : null,
      ],
    );

    return result.rows[0];
  } finally {
    client.release();
  }
}

export async function getUserByFirebaseUid(firebaseUid: string): Promise<UserRecord | null> {
  const client = await pool.connect();
  try {
    const result = await client.query('SELECT * FROM users WHERE firebase_uid = $1 LIMIT 1;', [firebaseUid]);
    if (result.rows.length === 0) {
      return null;
    }
    return result.rows[0];
  } finally {
    client.release();
  }
}

export function mapRecordToResponse(record: UserRecord) {
  return {
    id: record.id,
    email: record.email,
    name: record.name,
    phone: record.phone_encrypted ? decrypt(record.phone_encrypted, config.encryptionKey) : null,
    document: record.document_encrypted ? decrypt(record.document_encrypted, config.encryptionKey) : null,
    created_at: record.created_at,
    updated_at: record.updated_at,
  };
}
