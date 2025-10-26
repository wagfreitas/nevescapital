import { Controller, Get, Post, Body, Param, Query } from '@nestjs/common';
import { UserTransactionService, UserTransaction } from './user-transaction.service';

@Controller('transactions')
export class UserTransactionController {
  constructor(private readonly transactionService: UserTransactionService) {}

  /**
   * Salva uma transação confirmada pela Pagar.me
   * POST /api/transactions
   */
  @Post()
  async saveTransaction(@Body() transaction: UserTransaction) {
    try {
      // Validar se a transação não foi duplicada
      const isSynced = await this.transactionService.isTransactionSynced(transaction.pagarme_order_id);
      if (isSynced) {
        return {
          success: false,
          message: 'Transação já foi sincronizada',
        };
      }

      const savedTransaction = await this.transactionService.saveTransaction(transaction);
      
      return {
        success: true,
        data: savedTransaction,
        message: 'Transação salva com sucesso',
      };
    } catch (error) {
      return {
        success: false,
        message: 'Erro ao salvar transação',
        error: error.message,
      };
    }
  }

  /**
   * Busca saldo do usuário logado
   * GET /api/transactions/balance/:userId
   */
  @Get('balance/:userId')
  async getUserBalance(@Param('userId') userId: string) {
    try {
      const balance = await this.transactionService.getUserBalance(userId);
      
      if (!balance) {
        return {
          success: true,
          data: {
            available_amount: 0,
            waiting_funds: 0,
            total_transactions: 0,
          },
        };
      }

      return {
        success: true,
        data: balance,
      };
    } catch (error) {
      return {
        success: false,
        message: 'Erro ao buscar saldo',
        error: error.message,
      };
    }
  }

  /**
   * Busca histórico de transações do usuário
   * GET /api/transactions/history/:userId?limit=50&offset=0
   */
  @Get('history/:userId')
  async getUserTransactions(
    @Param('userId') userId: string,
    @Query('limit') limit: string = '50',
    @Query('offset') offset: string = '0',
  ) {
    try {
      const transactions = await this.transactionService.getUserTransactions(
        userId,
        parseInt(limit),
        parseInt(offset),
      );

      return {
        success: true,
        data: transactions,
        pagination: {
          limit: parseInt(limit),
          offset: parseInt(offset),
          total: transactions.length,
        },
      };
    } catch (error) {
      return {
        success: false,
        message: 'Erro ao buscar histórico',
        error: error.message,
      };
    }
  }

  /**
   * Busca estatísticas do usuário
   * GET /api/transactions/stats/:userId
   */
  @Get('stats/:userId')
  async getUserStats(@Param('userId') userId: string) {
    try {
      const stats = await this.transactionService.getUserStats(userId);

      return {
        success: true,
        data: stats,
      };
    } catch (error) {
      return {
        success: false,
        message: 'Erro ao buscar estatísticas',
        error: error.message,
      };
    }
  }

  /**
   * Verifica status de sincronização de uma transação
   * GET /api/transactions/sync-status/:orderId
   */
  @Get('sync-status/:orderId')
  async getSyncStatus(@Param('orderId') orderId: string) {
    try {
      const isSynced = await this.transactionService.isTransactionSynced(orderId);

      return {
        success: true,
        data: {
          order_id: orderId,
          synced: isSynced,
        },
      };
    } catch (error) {
      return {
        success: false,
        message: 'Erro ao verificar status de sincronização',
        error: error.message,
      };
    }
  }
}
