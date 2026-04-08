# Payment Gateway (Pagar.me)

## Current Integration

Pagar.me Core V5 API. Service: `lib/features/payment/data/services/pagarme_service.dart`.

```dart
class PagarmeService {
  static String get _apiKey => EnvService.pagarmeApiKey;
  static String get _baseUrl => EnvService.pagarmeBaseUrl;  // https://api.pagar.me/core/v5

  Future<Map<String, dynamic>> processarPagamentoCartao({
    required String nomeEstabelecimento,
    required int valorCentavos,
    required String nomeTitular,
    required String numeroCartao,
    required String cvv,
    required String vencimento,
  }) async { ... }
}
```

## Authentication

Basic Auth with API key:

```dart
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Basic ${base64Encode(utf8.encode('$_apiKey:'))}',
}
```

## Supported Methods

- Credit card only (currently)
- No PIX, no debit, no boleto implemented yet

## Response Pattern

```dart
// Success
{ 'success': true, 'message': 'Pagamento aprovado', 'transactionId': '...', 'orderId': '...' }

// Failure
{ 'success': false, 'message': 'Pagamento recusado: ...' }
```

## Known Issues / Technical Debt

1. **Hardcoded billing address** -- `Rua das Flores, 123, SP` in every transaction
2. **Hardcoded customer data** -- `teste@pagpag.com.br`, CPF `00000000000`
3. **Hardcoded test key** -- `tokenizarCartao()` uses `pk_test_SUACHAVEAQUI`
4. No webhook/callback support for async payment status
5. No retry mechanism for failed payments
6. No duplicate payment prevention
7. No rate limiting on payment requests

## Payment Flow (5 Steps)

1. Enter amount (PaymentStep1Screen)
2. Card number input (PaymentStep2Screen)
3. Card details -- holder, expiry, CVV (PaymentStep3Screen)
4. Review + confirm (PaymentStep4Screen)
5. Processing + result (PaymentStep5Screen / PaymentResultScreen)

## Sale Storage

After successful payment, saved to Firestore:
- Path: `users/{userId}/sales/{saleId}`
- Net value: 97% of gross (3% fee)
- Fields: valorCentavos, cardBrand, cardLastFour, status, createdAt

## Rules

- Amount always in centavos (integer) -- never floating point
- Card number stripped of spaces before sending
- Statement descriptor max 13 characters
- Expiry format: MM/AA (converted to MM/YYYY for API)
