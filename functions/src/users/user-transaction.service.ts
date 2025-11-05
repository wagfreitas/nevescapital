import { Injectable, Inject } from '@nestjs/common';
import { Pool } from 'pg';

export interface UserTransaction {
  user_id: string;
  pagarme_order_id: string;
  pagarme_charge_id?: string;
  amount: number;
  status: string;
  establishment_name?: string;
  customer_name?: string;
  payment_method?: string;
}

@Injectable()
export class UserTransactionService {
  constructor(@Inject('DATABASE_POOL') private readonly pool: Pool) {}

  /**
   * Verifica se uma transação já foi sincronizada
   */
  async isTransactionSynced(orderId: string): Promise<boolean> {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        'SELECT id FROM pagarme_sync_log WHERE order_id = $1 AND sync_status = $2',
        [orderId, 'synced'],
      );
      return result.rows.length > 0;
    } finally {
      client.release();
    }
  }

  /**
   * Salva uma transação
   */
  async saveTransaction(transaction: UserTransaction) {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      // Inserir transação
      const transactionResult = await client.query(
        `INSERT INTO user_transactions (
          user_id, pagarme_order_id, pagarme_charge_id, amount, status,
          establishment_name, customer_name, payment_method
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING id, created_at`,
        [
          transaction.user_id,
          transaction.pagarme_order_id,
          transaction.pagarme_charge_id || null,
          transaction.amount,
          transaction.status,
          transaction.establishment_name || null,
          transaction.customer_name || null,
          transaction.payment_method || null,
        ],
      );

      // Atualizar saldo do usuário
      await this.updateUserBalance(client, transaction.user_id, transaction.amount, transaction.status);

      // Registrar no log de sincronização
      await client.query(
        `INSERT INTO pagarme_sync_log (order_id, charge_id, sync_status, sync_attempts)
         VALUES ($1, $2, $3, 1)
         ON CONFLICT (order_id) DO UPDATE SET
           sync_status = $3,
           sync_attempts = pagarme_sync_log.sync_attempts + 1,
           last_sync_attempt = NOW()`,
        [transaction.pagarme_order_id, transaction.pagarme_charge_id || null, 'synced'],
      );

      await client.query('COMMIT');

      return {
        id: transactionResult.rows[0].id,
        ...transaction,
        created_at: transactionResult.rows[0].created_at,
      };
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  /**
   * Atualiza o saldo do usuário
   */
  private async updateUserBalance(
    client: any,
    userId: string,
    amount: number,
    status: string,
  ): Promise<void> {
    // Atualizar saldo baseado no status
    if (status === 'paid') {
      await client.query(
        `INSERT INTO user_balances (user_id, available_amount, total_transactions, last_transaction_at, last_updated)
         VALUES ($1, $2, 1, NOW(), NOW())
         ON CONFLICT (user_id) DO UPDATE SET
           available_amount = user_balances.available_amount + $2,
           total_transactions = user_balances.total_transactions + 1,
           last_transaction_at = NOW(),
           last_updated = NOW()`,
        [userId, amount],
      );
    } else if (status === 'waiting_payment') {
      await client.query(
        `INSERT INTO user_balances (user_id, waiting_funds, total_transactions, last_transaction_at, last_updated)
         VALUES ($1, $2, 1, NOW(), NOW())
         ON CONFLICT (user_id) DO UPDATE SET
           waiting_funds = user_balances.waiting_funds + $2,
           total_transactions = user_balances.total_transactions + 1,
           last_transaction_at = NOW(),
           last_updated = NOW()`,
        [userId, amount],
      );
    }
  }

  /**
   * Busca saldo do usuário
   */
  async getUserBalance(userId: string) {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        'SELECT * FROM user_balances WHERE user_id = $1',
        [userId],
      );

      if (result.rows.length === 0) {
        return null;
      }

      return result.rows[0];
    } finally {
      client.release();
    }
  }

  /**
   * Busca histórico de transações
   */
  async getUserTransactions(userId: string, limit: number = 50, offset: number = 0) {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        `SELECT * FROM user_transactions 
         WHERE user_id = $1 
         ORDER BY created_at DESC 
         LIMIT $2 OFFSET $3`,
        [userId, limit, offset],
      );

      return result.rows;
    } finally {
      client.release();
    }
  }

  /**
   * Busca estatísticas do usuário
   */
  async getUserStats(userId: string) {
    const client = await this.pool.connect();
    try {
      const result = await client.query(
        `SELECT 
          COUNT(*) as total_transactions,
          SUM(CASE WHEN status = 'paid' THEN amount ELSE 0 END) as total_received,
          SUM(CASE WHEN status = 'failed' THEN amount ELSE 0 END) as total_failed,
          AVG(CASE WHEN status = 'paid' THEN amount ELSE NULL END) as avg_transaction
         FROM user_transactions 
         WHERE user_id = $1`,
        [userId],
      );

      return result.rows[0] || {
        total_transactions: 0,
        total_received: 0,
        total_failed: 0,
        avg_transaction: 0,
      };
    } finally {
      client.release();
    }
  }
}

