declare function require(module: string): any;
declare const exports: Record<string, unknown>;

const functions = require('firebase-functions');
const express = require('express');

import { authenticate, AuthenticatedRequest } from './middleware';
import { getUserByFirebaseUid, mapRecordToResponse, upsertUser } from './db';
import { loadConfig } from './config';

const config = loadConfig();

const app = express();
app.use(express.json());

app.post('/users', authenticate, async (req: AuthenticatedRequest, res: any) => {
  try {
    const { name, email, phone, document } = req.body ?? {};
    if (!name || typeof name !== 'string') {
      return res.status(400).json({ message: 'Nome é obrigatório' });
    }

    const resolvedEmail = typeof email === 'string' && email.length > 0 ? email : req.user?.email;
    if (!resolvedEmail) {
      return res.status(400).json({ message: 'Email é obrigatório' });
    }

    const record = await upsertUser({
      firebaseUid: req.user?.uid ?? '',
      email: resolvedEmail,
      name,
      phone: typeof phone === 'string' && phone.length > 0 ? phone : null,
      document: typeof document === 'string' && document.length > 0 ? document : null,
    });

    res.status(201).json(mapRecordToResponse(record));
  } catch (error) {
    res.status(500).json({ message: 'Erro ao criar usuário', details: String(error) });
  }
});

app.get('/users/me', authenticate, async (req: AuthenticatedRequest, res: any) => {
  try {
    const record = await getUserByFirebaseUid(req.user?.uid ?? '');
    if (!record) {
      return res.status(404).json({ message: 'Usuário não encontrado' });
    }
    res.json(mapRecordToResponse(record));
  } catch (error) {
    res.status(500).json({ message: 'Erro ao carregar usuário', details: String(error) });
  }
});

app.put('/users/me', authenticate, async (req: AuthenticatedRequest, res: any) => {
  try {
    const { name, phone, document } = req.body ?? {};
    if (!name || typeof name !== 'string') {
      return res.status(400).json({ message: 'Nome é obrigatório' });
    }

    const existing = await getUserByFirebaseUid(req.user?.uid ?? '');
    if (!existing) {
      return res.status(404).json({ message: 'Usuário não encontrado' });
    }

    const record = await upsertUser({
      firebaseUid: req.user?.uid ?? '',
      email: existing.email,
      name,
      phone: typeof phone === 'string' && phone.length > 0 ? phone : null,
      document: typeof document === 'string' && document.length > 0 ? document : null,
    });

    res.json(mapRecordToResponse(record));
  } catch (error) {
    res.status(500).json({ message: 'Erro ao atualizar usuário', details: String(error) });
  }
});

exports.api = functions.region('southamerica-east1').https.onRequest(app);

// Exporta configurações para testes ou ferramentas
exports.__config = config;
