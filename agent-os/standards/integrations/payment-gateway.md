# Payment Gateway

## Status: Sem integração ativa

A integração anterior com Pagar.me foi removida. O projeto está avaliando novas soluções de pagamento.

## Quando nova integração for implementada:
- Criar service em `lib/features/payment/data/services/`
- Configurar chaves via `.env` e `EnvService`
- Implementar webhook no backend NestJS para callbacks
- Usar dados reais do usuário (nunca hardcoded)
