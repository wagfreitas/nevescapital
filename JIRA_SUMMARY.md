# Limpeza e Padronização do Fluxo de Cadastro + Melhorias de UX

**Branch:** `feature/cleanup-registration-flow`

---

## 1. Reescrita das 6 Telas do Cadastro

### Arquivos Renomeados

| Antes | Depois |
|---|---|
| `step2_phone_screen.dart` | `registration_phone_screen.dart` |
| `step3_otp_screen.dart` | `registration_otp_screen.dart` |
| `step4_email_screen.dart` | `registration_email_screen.dart` |
| `step5_personal_data_1_screen.dart` | `registration_personal_data_screen.dart` |
| `step6_address_screen.dart` | `registration_address_screen.dart` |
| `step7_personal_data_2_screen.dart` | `registration_additional_info_screen.dart` |

### Métricas

- **Antes:** 3.388 linhas em 6 arquivos
- **Depois:** 3.008 linhas em 6 arquivos
- **Redução:** ~380 linhas (código morto, logs, duplicação)

### Padronizações aplicadas

1. **Persistência local direta** — substituído `RegistrationLifecycleObserver` e `RegistrationNavigationHelper` (que dependiam do Firestore) por `LocalRegistrationStorage.saveLocal()` com merge via `copyWith`
2. **Save antes de voltar** — `_handleBack()` salva progresso localmente antes de `Navigator.pop`, preservando dados ao navegar para trás
3. **Save antes de avançar** — `_handleNext()` salva progresso localmente com merge antes de navegar
4. **PopScope** — adicionado em todas as telas para interceptar swipe-back (iOS) e botão voltar (Android)
5. **Remoção de logs verbose** — logs MOCK, emojis excessivos, stackTraces desnecessários
6. **Remoção de código morto** — `autoSubmitPhone`, `_clearAllFields`, `_mockVerifyOtp`, `_complementFocusNode`, etc.
7. **Extração de métodos** — `_handleBack()`, `_saveProgressLocally()`, `_inputDecoration()` centralizados

---

## 2. Correções de Bugs

### 2.1 Navegação WhatsApp OTP → CPF destruía a pilha
- **Problema:** `whatsapp_otp_screen.dart` usava `pushAndRemoveUntil((route) => false)` ao navegar para cadastro, destruindo Phone Login e OTP da pilha
- **Fix:** Trocado para `Navigator.push`
- **Impacto:** Agora é possível voltar de CPF → OTP → Phone Login com dados preservados

### 2.2 Dados não persistiam ao navegar para trás
- **Problema:** `_lifecycleObserver.saveNow()` usava guard `shouldSaveProgress` que verificava `ModalRoute.isCurrent` — no momento do back a rota já não era "current" e o save era ignorado
- **Fix:** Save direto no `LocalRegistrationStorage`

### 2.3 Dados de outras telas eram sobrescritos ao salvar
- **Problema:** Cada tela criava `RegistrationProgress` novo com apenas seus campos, sobrescrevendo dados de outras telas
- **Fix:** Carrega progresso existente (`getLocal`) e faz merge via `copyWith` antes de salvar

### 2.4 Save ao avançar falhava silenciosamente
- **Problema:** `saveNow(localOnly: false)` tentava Firestore primeiro; se falhava, o save local nunca executava
- **Fix:** Save direto no `LocalRegistrationStorage`

### 2.5 Overflow na tela de dados do cartão
- **Problema:** `payment_step4_screen.dart` — overflow de 2.6px no bottom
- **Fix:** Campos do formulário envolvidos em `SingleChildScrollView`

### 2.6 Backspace em campo vazio não voltava foco (tela OTP)
- **Problema:** Apertar backspace num campo OTP vazio não movia o cursor para o campo anterior
- **Fix:** Envolvido cada campo em `KeyboardListener` que detecta `LogicalKeyboardKey.backspace` e move o foco quando o campo atual está vazio

### 2.7 Dropdown de Faixa de Renda abria para cima
- **Problema:** Na tela de Informações Pessoais, ao selecionar um valor do final da lista, o dropdown abria para cima cobrindo a pergunta de PEP
- **Fix:** Substituído `DropdownButtonFormField` por um bottom sheet (consistente com o seletor de ocupação)

---

## 3. Melhorias de UX e Padronização Visual

### 3.1 Títulos padronizados
- `Dados da Loja`, `Valor da Venda`, `Dados Bancários`, `Dados do Cartão`, `Resumo da Venda` — todos com `fontSize: 20` (antes eram `fontSize: 28`)
- `Insira seu CPF` → `CPF`
- `Insira seu email` → `Email`

### 3.2 Indicador de progresso mais compacto
- `RegistrationProgressIndicator.preferredSize` reduzido de 28px → 16px
- Padding interno: `(16, 0, 16, 12)` → `(16, 0, 16, 4)` — barras mais próximas do título
- Aplicado em todas as telas de cadastro (`registration_*`) e em todas as 5 telas de pagamento (`payment_step1` a `payment_step5`)
- Body top padding ajustado de `+ 28 +` para `+ 16 +`

### 3.3 Tela "Dados da Loja" (payment_step1) reestruturada
- Título movido para a AppBar (usando `GlassAppBar`, padrão do resto do app)
- Rótulo "Ramo de Atuação" agora sempre visível acima do valor selecionado (mesmo padrão do `edit_store_data_screen` da seção Conta)

### 3.4 Tela de Endereço (registration_address)
- Convertida de `AppBar` padrão para `GlassAppBar` transparente (consistência com resto do cadastro)
- Padding top calculado para que o rótulo flutuante do CEP não seja cortado pela AppBar

### 3.5 Tela "Selecione o Ramo de Atuação"
- Campo de busca aproximado do título (`topPadding` reduzido)
- Aplicado em `payment_step1_screen.dart` e `edit_store_data_screen.dart`

### 3.6 CPF screen refatorado
- `_handleNext` quebrado em 3 métodos claros: `_handleNext()`, `_handleLogin()`, `_handleRegistration()`
- `_handleRegistration` carrega progresso salvo para preservar dados digitados anteriormente

### 3.7 Swipe-back consistente
- `KeyboardDismissWrapper` ajustado (`excludeFromSemantics: true`) para não interferir no gesto de voltar do iOS
- Todas as telas de cadastro envolvidas em `PopScope` que intercepta o gesto e executa o `_handleBack` (salva progresso)

---

## 4. Arquivos modificados (lista técnica)

| Arquivo | Mudança |
|---|---|
| `registration_navigator.dart` | Imports/nomes atualizados para as 6 telas |
| `unified_cpf_screen.dart` | Refatorado, carrega progresso salvo |
| `whatsapp_otp_screen.dart` | `pushAndRemoveUntil` → `push`; backspace em campo vazio |
| `payment_step1_screen.dart` | AppBar + rótulo "Ramo" visível + padding busca |
| `payment_step2-5_screen.dart` | Fonte do título padronizada + progress indicator menor |
| `payment_step4_screen.dart` | Fix overflow |
| `edit_store_data_screen.dart` | Padding busca |
| `keyboard_dismiss_button.dart` | `excludeFromSemantics` |
| `registration_progress_indicator.dart` | preferredSize 28 → 16 |

---

## 5. Limitações conhecidas

### iOS < 26 não suporta autofill OTP via WhatsApp

- `AutofillHints.oneTimeCode` só funciona com SMS (app Mensagens nativo da Apple)
- WhatsApp/Telegram só serão suportados a partir do iOS 26
- Avaliar: aguardar iOS 26 / fallback SMS / push FCM com código embutido / chip de clipboard
- Ticket separado a ser criado
