# 🚀 Guia Rápido: TestFlight para Teste no Device Físico

## 🎯 O QUE É TESTFLIGHT?

TestFlight é a plataforma oficial da Apple para distribuir versões beta do seu app para testadores.

**Vantagens:**
- ✅ Instala no iPhone físico
- ✅ Não precisa cabo USB
- ✅ Testa funcionalidades reais (câmera, biometria, etc)
- ✅ Até 10,000 testadores externos
- ✅ Sem revisão da Apple (para internal testing)
- ✅ Builds expiram em 90 dias

---

## 📋 PASSO A PASSO COMPLETO

### PASSO 1: Abrir Xcode e Fazer Archive

**Execute:**
```bash
cd /Users/wagneralves/StudioProjects/neves_capital/ios
open Runner.xcworkspace
```

**No Xcode que abrir:**

1. **Verificar Team:**
   - Painel esquerdo → Clique em **Runner** (ícone azul)
   - Target **Runner** → Aba **Signing & Capabilities**
   - Verifique se **Team** está selecionado
   - **Bundle ID:** `com.nevescapital.pagpag`
   - **Automatically manage signing:** ✅ marcado

2. **Selecionar Dispositivo:**
   - Menu superior (ao lado de "Runner"): selecione **"Any iOS Device (arm64)"**
   - **NÃO** selecione simulador

3. **Archive:**
   - Menu: **Product** → **Archive**
   - Aguarde compilação (10-20 minutos)
   - ☕ Pegue um café...

---

### PASSO 2: Upload para App Store Connect

**Quando Archive finalizar:**

1. Janela **Organizer** abre automaticamente
2. No painel esquerdo, clique em **Archives**
3. Selecione o archive mais recente (topo)
4. Clique botão **"Distribute App"**
5. Selecione **"App Store Connect"**
6. Clique **"Next"**
7. Selecione **"Upload"**
8. Marque as opções:
   - ✅ **Upload your app's symbols** (para crashlytics)
   - ✅ **Manage Version and Build Number** (deixe Xcode gerenciar)
9. Clique **"Next"**
10. Revise as informações
11. Clique **"Upload"**
12. Aguarde upload (5-30 minutos dependendo da internet)

---

### PASSO 3: Criar App no App Store Connect (se ainda não criou)

**Acesse:** https://appstoreconnect.apple.com/

1. Login com Apple Developer Account
2. Clique em **"My Apps"**
3. Se o app já existe, pule para PASSO 4
4. Se não existe, clique **"+"** → **"New App"**:
   - **Platform:** iOS
   - **Name:** PagPag
   - **Primary Language:** Portuguese (Brazil)
   - **Bundle ID:** com.nevescapital.pagpag
   - **SKU:** pagpag001
   - **User Access:** Full Access
5. Clique **"Create"**

---

### PASSO 4: Aguardar Build Processar

**No App Store Connect:**

1. Vá no seu app → Aba **"TestFlight"**
2. Seção **"iOS Builds"**
3. Seu build aparecerá com status **"Processing"**
4. Aguarde 15-60 minutos
5. Status mudará para **"Ready to Submit"** ou **"Missing Compliance"**

**Se aparecer "Missing Compliance":**
- Clique no aviso amarelo
- Responda:
  - "Uses Encryption?" → **YES**
  - "Implements algorithms?" → **NO** (apenas HTTPS)
- **Submit**

---

### PASSO 5: Adicionar Testador (VOCÊ)

**No App Store Connect → TestFlight:**

1. **Internal Testing:**
   - Clique em **"Internal Testing"** (menu esquerdo)
   - Clique no grupo **"App Store Connect Users"** ou crie novo grupo
   - Clique **"+"** para adicionar testadores
   - Selecione seu email (usuário App Store Connect)
   - **Save**

2. **Ou External Testing (se preferir):**
   - Clique em **"External Testing"**
   - Crie novo grupo de teste
   - Adicione seu email
   - **Não precisa de revisão Apple para internal testing!**

---

### PASSO 6: Selecionar Build para Teste

**No grupo de teste que criou:**

1. Seção **"Builds"**
2. Clique **"+"** ou **"Add Build"**
3. Selecione o build que acabou de processar
4. **Save**

---

### PASSO 7: Instalar TestFlight no iPhone

**No seu iPhone:**

1. Abra **App Store**
2. Busque: **"TestFlight"**
3. Instale o app oficial da Apple (gratuito)

---

### PASSO 8: Aceitar Convite e Instalar

**Você receberá um email:**

**Opção A: Via Email**
1. Abra o email no iPhone
2. Clique no link de convite
3. Abre TestFlight automaticamente
4. Clique **"Accept"**
5. Clique **"Install"**
6. App será instalado!

**Opção B: Código de Convite**
1. Abra TestFlight no iPhone
2. Clique **"Redeem"**
3. Digite código do convite
4. **"Install"**

---

## ⚡ MÉTODO ALTERNATIVO (MAIS RÁPIDO)

### Instalar Direto via Xcode (sem TestFlight)

**Se quiser testar AGORA mesmo:**

1. **Conecte iPhone no Mac** via cabo USB

2. **Confie no computador:**
   - No iPhone, quando aparecer "Trust This Computer?" → **Trust**
   - Digite senha do iPhone

3. **No Xcode:**
   - Selecione seu iPhone físico no menu (vai aparecer automaticamente)
   - Menu: **Product** → **Run**
   - Ou pressione **Cmd + R**

4. **No iPhone:**
   - Primeira vez pode pedir:
   - Settings → General → VPN & Device Management
   - Confiar no developer
   - Voltar e abrir o app

**Pronto! App instalado e rodando no seu iPhone!**

---

## 🧪 TESTANDO O SCAN DE CARTÃO

**Com app instalado no iPhone físico:**

1. Abra o PagPag
2. Faça login
3. Clique "Nova Venda"
4. Preencha Steps 1, 2, 3
5. No **Step 4**, clique **"📷 Escanear Cartão com Câmera"**
6. Aponte para um cartão de crédito real
7. **VEJA A MÁGICA:**
   - Número é lido ✅
   - Nome é lido ✅
   - Validade é lida ✅
   - Campos preenchidos automaticamente! 🎉

---

## 🎯 QUAL MÉTODO VOCÊ PREFERE?

### Opção A: Via Xcode (MAIS RÁPIDO - 5 minutos)
```bash
# 1. Conecte iPhone no Mac
# 2. Abra Xcode
open ios/Runner.xcworkspace
# 3. Selecione seu iPhone
# 4. Cmd + R
```
**Tempo:** 5 minutos  
**Vantagem:** Imediato

### Opção B: Via TestFlight (MAIS PROFISSIONAL - 1-2 horas)
```bash
# 1. Archive no Xcode
# 2. Upload para App Store Connect
# 3. Aguardar processar
# 4. Adicionar testador
# 5. Instalar via TestFlight
```
**Tempo:** 1-2 horas  
**Vantagem:** Distribuição profissional, pode enviar para outros testadores

---

## 🚀 COMANDOS PARA EXECUÇÃO IMEDIATA

### Se escolher Xcode (rápido):
```bash
cd /Users/wagneralves/StudioProjects/neves_capital/ios
open Runner.xcworkspace
```
Então: Conecte iPhone → Selecione device → Cmd+R

### Se escolher TestFlight (profissional):
```bash
cd /Users/wagneralves/StudioProjects/neves_capital/ios
open Runner.xcworkspace
```
Então: Product → Archive → Upload

---

**Qual você prefere? A (rápido) ou B (profissional)?**

