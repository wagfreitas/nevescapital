# Ajustes UX – Jornada de Venda e Perfil

**Branch:** `feature/ajustes`
**Escopo:** telas de pagamento (step1–step5), tela de edição de dados pessoais, tela de edição de dados da loja e validação de cartão.

---

## Resumo

Padronização visual das 5 telas da jornada de venda (Dados da Loja → Valor → Dados Bancários → Dados do Cartão → Resumo) seguindo o mesmo padrão já aplicado no fluxo de cadastro, além de correções pontuais de bugs:

- UX/layout: botão "Avançar" com caixa transparente, telas fora do padrão do cadastro, área verde extra em "Dados Pessoais", AppBar aparecendo durante processamento da venda.
- Validação de cartão: Amex de 15 dígitos não era validado; máscara 4-6-5 foi unificada em 4-4-4-4.
- Busca de Ramo de Atuação: "acou" não encontrava "Açougue" (bug em `_removeAccents`); acentos e cedilha agora são tratados corretamente e há matching por subsequência.

---

## Itens entregues

### 1. Padronização das telas de venda (step1–step5)

Todas as 5 telas agora seguem o mesmo padrão do fluxo de cadastro (`registration_*_screen.dart`):

- `Scaffold(resizeToAvoidBottomInset: true)` — sem `extendBodyBehindAppBar`, sem `SafeArea` redundante
- `GlassAppBar` com título **fontSize 20, bold, branco**
- Progress indicator com altura 16px
- `KeyboardDismissWrapper` em volta do body
- Padding padrão `EdgeInsets.fromLTRB(24, 16, 24, 0)`
- Estrutura: `Column` com `Expanded(Form(SingleChildScrollView))` + `SizedBox(24)` + `CustomButton` + `SizedBox(24)`
- Scroll com `clipBehavior: Clip.none` e `keyboardDismissBehavior: onDrag`

**Mudanças específicas:**

| Tela | Ajuste |
|---|---|
| step1 – Dados da Loja | Removido `SafeArea` redundante; `Form` agora envolve o `SingleChildScrollView` dentro do `Expanded` |
| step2 – Valor | Substituído `SafeArea + symmetric(h:24) + SizedBox(16)` por `KeyboardDismissWrapper + fromLTRB(24,16,24,0)` |
| step3 – Dados Bancários | Botão "Avançar" saiu de um `Padding` separado e entrou na estrutura padrão; caixa "ATENÇÃO" não bleeda mais atrás do botão |
| step4 – Dados do Cartão | Aviso de segurança movido para dentro do scroll; botão agora fora do scroll, na base |
| step5 – Resumo | Removido `SafeArea`; padding unificado; AppBar continua oculta quando `_isProcessing` |

### 2. Validação de cartão – suporte Amex 15 dígitos

**Arquivo:** `lib/shared/helpers/card_brand_detector.dart`, `lib/features/payment/presentation/screens/payment_step4_screen.dart`

Antes o validador tratava todos os cartões como 16 dígitos e rejeitava Amex válidos (ex.: `378282246310005`).

Helpers adicionados ao `CardBrandDetector`:
- `getExpectedDigits(brand)` — Amex: 15, Diners: 14, demais: 16
- `getMaxDigits(brand)` — mesmo critério + 19 para `unknown`
- `getGroupSizes(brand)` — **sempre `[4, 4, 4, 4]`** (agrupa de 4 em 4 independente da bandeira)
- `getCvvLength(brand)` — Amex: 4, demais: 3

A máscara do `_CardNumberFormatter` usa esses helpers; o validador aceita Luhn válido com o comprimento correto por bandeira.

> **Nota:** a máscara original era 4-6-5 para Amex e 4-6-4 para Diners (padrão do cartão físico), mas foi unificada em 4-4-4-4 a pedido (ex.: Amex passa a ser `3782 8224 6310 005`).

### 3. Correção na busca de Ramo de Atuação

**Arquivos:** `lib/features/payment/presentation/screens/payment_step1_screen.dart` e `lib/features/profile/presentation/screens/edit_store_data_screen.dart`

**Bug:** digitar "acou" não encontrava "Açougue". A função `_removeAccents` tinha a string `unaccented` com **6 `o`s** em vez de 5, deslocando todo o mapeamento — `ç` virava `n` em vez de `c`. Resultado: "Açougues" era normalizado como "anougues".

**Fix:** substituída a abordagem frágil de `split('') + indexOf` por `replaceAll` com regex por grupo de acentos. Mais legível e imune a erros de contagem.

Além disso, foi adicionada correspondência por **subsequência** para queries com 3+ caracteres (ex.: "acogue" também casa com "açougue").

### 4. AppBar oculta durante processamento da venda (step5)

**Arquivo:** `lib/features/payment/presentation/screens/payment_step5_screen.dart`

Quando o usuário clica em "Finalizar a Venda", a barra superior com o resumo some (`appBar: _isProcessing ? null : GlassAppBar(...)`) e a mensagem "Processando pagamento…" fica centralizada.

### 5. Ajustes em "Dados Pessoais" (perfil)

**Arquivo:** `lib/features/profile/presentation/screens/edit_personal_data_screen.dart`

- Label "Email" parava de cortar: removido `Spacer()` que competia com `Expanded(flex:1)`; padding movido para dentro do `SingleChildScrollView` com `clipBehavior: Clip.none`.
- Área verde extra acima do botão "Atualizar" removida; top padding alinhado com a tela de `bank_account_screen`.

### 6. Botão "Avançar" em step3 (dados bancários)

**Arquivo:** `lib/features/payment/presentation/screens/payment_step3_screen.dart`

- Removido o `clipBehavior: Clip.none` que fazia a caixa "ATENÇÃO" transparecer atrás do botão.
- Mantida a lógica `_hasChanges` só para decidir se salva no Firestore — o botão **sempre avança** (independente de ter alteração nos dados bancários).

---

## Arquivos alterados

```
lib/shared/helpers/card_brand_detector.dart
lib/features/payment/presentation/screens/payment_step1_screen.dart
lib/features/payment/presentation/screens/payment_step2_screen.dart
lib/features/payment/presentation/screens/payment_step3_screen.dart
lib/features/payment/presentation/screens/payment_step4_screen.dart
lib/features/payment/presentation/screens/payment_step5_screen.dart
lib/features/profile/presentation/screens/edit_personal_data_screen.dart
lib/features/profile/presentation/screens/edit_store_data_screen.dart
```

Total: **8 arquivos**, ~331 insertions / ~210 deletions.

---

## Como testar

### Jornada de venda padronizada
1. Nova Venda → preencher cada uma das 5 telas.
2. Verificar: título 20pt bold, progress indicator consistente, botão "Avançar" 56px altura na base da tela, padding lateral 24.
3. Em step5, ao clicar em "Finalizar a Venda", a barra superior deve sumir e a mensagem "Processando pagamento…" deve ficar centralizada.

### Amex 15 dígitos
1. Step4 (Dados do Cartão) → inserir `3782 8224 6310 005`.
2. A máscara deve formatar como `3782 8224 6310 005` (4-4-4-3).
3. A bandeira Amex deve aparecer no `suffixIcon`.
4. CVV deve aceitar 4 dígitos.
5. Validador não deve reclamar de comprimento.

### Busca de Ramo de Atuação
1. Step1 (Dados da Loja) → clicar em "Ramo de Atuação".
2. Digitar `acou` → deve listar "Açougues e Peixarias".
3. Digitar `saude` → deve listar "Saúde e Bem-Estar".
4. Digitar `acogue` (sem o `u`) → também deve casar via subsequência.

### Validações visuais
1. Step3: caixa "ATENÇÃO" não deve transparecer atrás do botão "Avançar".
2. Perfil → Dados Pessoais: label "Email" não deve cortar; sem área verde extra acima de "Atualizar".

---

## Notas técnicas

- Nenhuma mudança em backend/API.
- Sem mudança em modelos/entidades.
- Sem dependências novas.
- Roda em `feature/ajustes`, base em `main`.
- `flutter analyze --no-pub` nos arquivos afetados: **No issues found**.
