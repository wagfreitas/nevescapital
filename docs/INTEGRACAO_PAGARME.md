# 💳 Integração Pagar.me - Fluxo de Pagamento

## 📋 Visão Geral

Implementamos um fluxo completo de pagamento com cartão de crédito usando a API V5 do Pagar.me em ambiente Sandbox.

### Fluxo de Telas

```
Tela 1: Nome do Estabelecimento
    ↓
Tela 2: Valor da Venda
    ↓
Tela 3: Dados do Cartão
    ↓
Tela 4: Resumo e Confirmação
    ↓
Tela 5: Resultado (Sucesso/Erro)
```

---

## 🔑 Configuração Inicial

### 1. Criar Conta no Pagar.me

1. Acesse: https://dashboard.pagar.me/
2. Crie uma conta gratuita
3. Acesse o Dashboard

### 2. Obter Chaves de API (Sandbox)

1. No Dashboard, vá em **Configurações** → **API Keys**
2. Copie as chaves do ambiente **Teste (Sandbox)**:
   - `sk_test_...` (Secret Key) - para servidor
   - `pk_test_...` (Public Key) - para cliente

### 3. Configurar no Projeto

Edite o arquivo: `lib/features/payment/data/services/pagarme_service.dart`

```dart
class PagarmeService {
  // Substituir pela sua chave SECRET KEY de teste
  static const String _apiKey = 'sk_test_SUACHAVEAQUI';
  
  // ...
  
  // Na função tokenizarCartao, usar PUBLIC KEY:
  final response = await http.post(
    Uri.parse('$_baseUrl/tokens?appId=pk_test_SUACHAVEPUBLICAAQUI'),
    // ...
  );
}
```

---

## 🧪 Testando com Cartões de Teste

O Pagar.me fornece cartões de teste para simular diferentes cenários:

### ✅ Cartões Aprovados

**Visa:**
```
Número: 4111 1111 1111 1111
CVV: 123
Validade: qualquer data futura (ex: 12/28)
Nome: Qualquer nome
```

**Mastercard:**
```
Número: 5555 5555 5555 4444
CVV: 123
Validade: qualquer data futura
Nome: Qualquer nome
```

**American Express:**
```
Número: 3782 822463 10005
CVV: 1234
Validade: qualquer data futura
Nome: Qualquer nome
```

### ❌ Cartões para Testar Recusa

**Cartão Recusado:**
```
Número: 4000 0000 0000 0002
CVV: 123
Validade: qualquer data futura
Nome: Qualquer nome
```

**Fundos Insuficientes:**
```
Número: 4000 0000 0000 0101
CVV: 123
Validade: qualquer data futura
Nome: Qualquer nome
```

---

## 📁 Estrutura dos Arquivos

```
lib/features/payment/
├── data/
│   └── services/
│       └── pagarme_service.dart      # Service de integração com API
├── presentation/
│   └── screens/
│       ├── payment_step1_screen.dart  # Tela 1: Nome estabelecimento
│       ├── payment_step2_screen.dart  # Tela 2: Valor da venda
│       ├── payment_step3_screen.dart  # Tela 3: Dados do cartão
│       ├── payment_step4_screen.dart  # Tela 4: Resumo
│       └── payment_result_screen.dart # Tela 5: Resultado
└── payment_routes.dart                # Rotas do módulo
```

---

## 🚀 Como Usar

### 1. Navegar para o Fluxo de Pagamento

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PaymentStep1Screen(),
  ),
);
```

### 2. Adicionar ao Menu Principal

No `home_screen.dart` ou `dashboard_screen.dart`:

```dart
ElevatedButton.icon(
  icon: const Icon(Icons.payment),
  label: const Text('Nova Venda'),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentStep1Screen(),
      ),
    );
  },
),
```

---

## 🔧 Funcionalidades Implementadas

### ✅ Validações

- [x] Nome do estabelecimento (mínimo 3 caracteres)
- [x] Valor mínimo (R$ 1,00)
- [x] Formatação automática de valor monetário
- [x] Validação de número do cartão (13-16 dígitos)
- [x] Formatação automática do número do cartão (espaços a cada 4 dígitos)
- [x] Validação de CVV (3-4 dígitos)
- [x] Validação de data de vencimento (MM/AA)
- [x] Formatação automática da data (/)

### 💳 Processamento

- [x] Integração com API V5 do Pagar.me
- [x] Criação de pedido (order)
- [x] Captura automática do pagamento
- [x] Tratamento de erros
- [x] Feedback visual (loading)

### 🎨 Interface

- [x] Design seguindo identidade visual do app
- [x] Indicador de progresso (dots)
- [x] Máscaras de entrada
- [x] Mensagens de validação
- [x] Telas de sucesso/erro

---

## 📡 Endpoints Utilizados

### Criar Pedido
```
POST https://api.pagar.me/core/v5/orders
```

**Headers:**
```
Content-Type: application/json
Authorization: Basic {base64(sk_test_xxx:)}
```

**Body:**
```json
{
  "amount": 10000,
  "description": "Venda - Loja do Daniel",
  "payment_method": "credit_card",
  "credit_card": {
    "card": {
      "number": "4111111111111111",
      "holder_name": "TESTE USUARIO",
      "exp_month": 12,
      "exp_year": 2028,
      "cvv": "123"
    },
    "installments": 1,
    "statement_descriptor": "Loja Daniel",
    "capture": true
  },
  "customer": {
    "name": "TESTE USUARIO",
    "type": "individual"
  }
}
```

### Consultar Pedido
```
GET https://api.pagar.me/core/v5/orders/{orderId}
```

---

## 🛡️ Segurança

### Boas Práticas Implementadas

1. **Criptografia SSL/TLS** - Todas as requisições usam HTTPS
2. **Não armazenamos dados do cartão** - Enviado diretamente para Pagar.me
3. **Validações client-side** - Reduz erros antes do envio
4. **Feedback visual** - Loading durante processamento
5. **Máscara de cartão** - Exibe apenas últimos 4 dígitos

### ⚠️ Importante

- **NUNCA** commite chaves de API no código
- Use variáveis de ambiente para produção
- As chaves de teste (sandbox) não processam cobranças reais
- Sempre valide os dados no servidor também

---

## 🐛 Tratamento de Erros

### Erros Comuns e Soluções

**"Cartão inválido"**
- Verifique se o número do cartão está correto
- Use cartões de teste válidos

**"Transação negada"**
- Use cartões de teste aprovados
- Verifique se está no ambiente Sandbox

**"Erro de conexão"**
- Verifique sua internet
- Confirme se a API do Pagar.me está online

**"Unauthorized"**
- Verifique se a chave de API está correta
- Confirme se está usando chave de teste (sk_test_...)

---

## 📊 Testando o Fluxo Completo

### Teste 1: Pagamento Aprovado

1. Iniciar fluxo de pagamento
2. Inserir: "Loja Teste"
3. Inserir: R$ 50,00
4. Usar cartão: `4111 1111 1111 1111`
5. CVV: `123`
6. Validade: `12/28`
7. Nome: `TESTE APROVADO`
8. ✅ Deve aprovar

### Teste 2: Pagamento Recusado

1. Iniciar fluxo de pagamento
2. Inserir: "Loja Teste"
3. Inserir: R$ 100,00
4. Usar cartão: `4000 0000 0000 0002`
5. CVV: `123`
6. Validade: `12/28`
7. Nome: `TESTE RECUSADO`
8. ❌ Deve recusar

---

## 🔄 Próximas Implementações

### Melhorias Futuras

- [ ] PIX como método de pagamento alternativo
- [ ] Parcelamento (2x, 3x, etc.)
- [ ] Boleto bancário
- [ ] Salvamento de cartão (tokenização)
- [ ] Histórico de transações
- [ ] Comprovante em PDF
- [ ] Notificações push
- [ ] Dashboard de vendas
- [ ] Relatórios

---

## 📚 Documentação Oficial

- **Pagar.me API V5:** https://docs.pagar.me/reference/introdu%C3%A7%C3%A3o-1
- **Dashboard:** https://dashboard.pagar.me/
- **Cartões de Teste:** https://docs.pagar.me/docs/testando-sua-integra%C3%A7%C3%A3o
- **Suporte:** https://suporte.pagar.me/

---

## 🎯 Comandos Úteis

```bash
# Executar o app
flutter run

# Limpar cache
flutter clean

# Atualizar dependências
flutter pub get

# Build para iOS
flutter build ios

# Build para Android
flutter build apk
```

---

## ✅ Checklist de Integração

- [x] Criar conta no Pagar.me
- [x] Obter chaves de API (sandbox)
- [x] Configurar chaves no código
- [x] Implementar telas do fluxo
- [x] Integrar com API
- [ ] Testar com cartões aprovados
- [ ] Testar com cartões recusados
- [ ] Testar validações de formulário
- [ ] Testar fluxo completo end-to-end
- [ ] Documentar para equipe
- [ ] Preparar para ambiente de produção

---

## 🆘 Suporte

Se tiver dúvidas:

1. Consulte a documentação oficial do Pagar.me
2. Verifique o código nos arquivos criados
3. Teste com cartões de teste válidos
4. Verifique os logs de erro

---

**Desenvolvido para:** PagPag - Neves Capital  
**Data:** Outubro 2024  
**Versão:** 1.0.0


