# 🚀 Guia de Publicação na Apple App Store - PagPag

## ✅ Status Atual

**Versão do App:** 1.0.0+3  
**Nome:** PagPag  
**Bundle ID:** (precisa ser configurado)  
**Ambiente:** ✅ Flutter 3.35.5 + Xcode 26.0.1 prontos  

---

## 📋 PASSO A PASSO PARA PUBLICAÇÃO

### PASSO 1: Criar Conta Apple Developer (SE NÃO TEM)

1. Acesse: https://developer.apple.com/programs/
2. Clique em "Enroll"
3. Pague $99 USD/ano
4. Aguarde aprovação (24-48h)

**JÁ TEM CONTA?** Pule para o Passo 2.

---

### PASSO 2: Configurar Bundle ID no Xcode

**Execute estes comandos:**

```bash
cd /Users/wagneralves/StudioProjects/neves_capital/ios
open Runner.xcworkspace
```

⚠️ **IMPORTANTE:** Abra `.xcworkspace`, NÃO `.xcodeproj`

**No Xcode que abrir:**

1. No painel esquerdo, clique em **Runner** (topo, ícone azul)
2. No painel central, clique no target **Runner** (sob TARGETS)
3. Clique na aba **Signing & Capabilities**
4. Configure:
   - **Team:** Selecione sua conta Apple Developer
   - **Bundle Identifier:** `com.nevescapital.pagpag` (ou outro único)
   - **Automatically manage signing:** ✅ Marque
5. Certifique-se que não há erros vermelhos

---

### PASSO 3: Preparar Materiais Obrigatórios

#### A. Política de Privacidade (OBRIGATÓRIO)

**Você precisa:**
1. Criar uma política de privacidade
2. Publicá-la em um site (pode ser GitHub Pages, Notion, ou seu site)
3. Ter a URL pronta

**Sugestão rápida:** Use o template em `docs/TEMPLATE_POLITICA_PRIVACIDADE.md`

#### B. Screenshots (OBRIGATÓRIO - mínimo 3)

**Como fazer:**
1. Rodar app no simulador iPhone 15 Pro Max:
```bash
flutter run -d "iPhone 16e"
```

2. No simulador, navegar pelas telas principais:
   - Tela de Login
   - Dashboard
   - Nova Venda
   - Perfil

3. Para cada tela, pressionar **Cmd + S** para salvar screenshot

4. Screenshots salvos em: `~/Desktop`

5. Tamanho esperado: 1290x2796 pixels

#### C. Ícone 1024x1024 (OBRIGATÓRIO)

Você já tem ícones em `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

Verifique se há um `Icon-App-1024x1024@1x.png` - se não, crie um.

#### D. Textos de Marketing

**Nome do App:** PagPag

**Subtítulo (max 30 chars):**
```
Pagamentos rápidos no PIX
```

**Descrição (max 4000 chars):**
```
PagPag é a solução completa para receber pagamentos via cartão de crédito e transferir instantaneamente para sua chave PIX.

🚀 PRINCIPAIS RECURSOS:
• Transforme seu celular em maquininha de cartão
• Receba pagamentos em segundos no PIX
• Taxas competitivas e transparentes
• Histórico completo de vendas
• Autenticação segura com biometria

💳 COMO FUNCIONA:
1. Cadastre sua chave PIX
2. Insira os dados do cartão do cliente
3. Receba o valor líquido instantaneamente

🔒 SEGURANÇA:
• Criptografia de ponta a ponta
• Autenticação com Face ID / Touch ID
• Conformidade com LGPD
• Dados protegidos no Firebase

📱 INTERFACE MODERNA:
Design intuitivo e profissional. Faça sua primeira venda em menos de 1 minuto!

Baixe agora e comece a vender!
```

**Keywords (max 100 chars):**
```
pagamento,pix,cartao,credito,venda,maquininha,transferencia,financeiro,pagpag
```

**Support URL:**
```
https://www.pagpagbrasil.com.br/suporte
```
(ou crie um email: suporte@nevescapital.com.br)

---

### PASSO 4: Build de Produção

**Execute:**

```bash
cd /Users/wagneralves/StudioProjects/neves_capital

# Limpar projeto
flutter clean

# Instalar dependências
flutter pub get

# Atualizar pods iOS
cd ios
pod install
cd ..

# Build iOS release
flutter build ios --release
```

Aguarde a compilação (5-10 minutos).

---

### PASSO 5: Archive no Xcode

**No Xcode (Runner.xcworkspace aberto):**

1. No menu superior, selecione dispositivo: **Any iOS Device (arm64)**
2. Menu: **Product** → **Archive**
3. Aguarde (5-15 minutos)
4. Janela **Organizer** abrirá automaticamente

---

### PASSO 6: Upload para App Store Connect

**Na janela Organizer:**

1. Selecione o archive mais recente
2. Clique **"Distribute App"**
3. Selecione **"App Store Connect"**
4. Clique **"Upload"**
5. Marque:
   - ✅ Upload your app's symbols
   - ✅ Manage Version and Build Number
6. **Next** → **Upload**

Aguarde upload (5-30 min dependendo da internet).

---

### PASSO 7: Criar App no App Store Connect

**Acesse:** https://appstoreconnect.apple.com/

1. Login com Apple Developer Account
2. Clique **"My Apps"**
3. Clique no **"+"** → **"New App"**
4. Preencha:
   - **Platform:** iOS
   - **Name:** PagPag
   - **Primary Language:** Portuguese (Brazil)
   - **Bundle ID:** com.nevescapital.pagpag (o mesmo do Xcode)
   - **SKU:** pagpag001
   - **User Access:** Full Access
5. Clique **"Create"**

---

### PASSO 8: Preencher Informações do App

**Na página do app criado:**

#### 8.1 App Information
- **Name:** PagPag
- **Category:** Finance
- **Subcategory:** Personal Finance
- **Privacy Policy URL:** [SUA URL AQUI]
- **Support URL:** https://www.pagpagbrasil.com.br/suporte

#### 8.2 Pricing and Availability
- **Price:** Free
- **Availability:** Brazil

#### 8.3 App Privacy
- Responder questionário sobre dados coletados:
  - ✅ Nome, Email, CPF (para cadastro)
  - ✅ Dados financeiros (transações)
  - ✅ Location (NÃO - se não usa)
  - etc.

#### 8.4 Prepare for Submission - iOS App (Version 1.0)

**Screenshots:** Upload 3-10 screenshots

**App Preview:** (opcional - vídeo)

**Promotional Text:** (opcional - editável depois)
```
Transforme seu celular em maquininha! Receba em segundos no PIX.
```

**Description:** Cole a descrição preparada acima

**Keywords:** Cole as keywords preparadas

**Support URL:** https://www.pagpagbrasil.com.br/suporte

**Marketing URL:** (opcional)

**Version:** 1.0.0

**Copyright:** 2025 Neves Capital

**App Icon:** Upload 1024x1024 PNG (sem transparência)

---

### PASSO 9: Aguardar Build Processar

No App Store Connect:
1. Vá na aba **TestFlight**
2. Build aparecerá em "Processing"
3. Aguarde 15-60 minutos
4. Status mudará para "Ready to Submit"

---

### PASSO 10: Adicionar Build e Submeter

**Quando build estiver processado:**

1. App Store Connect → Aba **App Store**
2. Versão 1.0 → Seção **Build**
3. Clique **"Select a build"**
4. Escolha o build que você fez upload
5. **Export Compliance:**
   - "Does your app use encryption?" → **YES**
   - "Is your app designed to use cryptography?" → **YES** (HTTPS/TLS)
   - "Does your app implement any encryption algorithms?" → **NO**
6. **Age Rating:** Responda questionário (provavelmente 4+)
7. Verifique que TUDO está preenchido
8. Clique **"Add for Review"**
9. Clique **"Submit for Review"**

---

### PASSO 11: Aguardar Revisão

**Timeline:**
- **Waiting for Review:** 1-2 dias
- **In Review:** 24-48 horas
- **Resultado:** Approved ou Rejected

**Se aprovado:**
- Status: "Pending Developer Release"
- Você escolhe quando publicar
- Ou deixe "Automatically release"

**Se rejeitado:**
- Leia feedback da Apple
- Faça correções
- Incremente build: `1.0.0+4`
- Repita processo de Archive e Upload

---

## 🎯 COMANDOS RÁPIDOS

### Preparar Build
```bash
cd /Users/wagneralves/StudioProjects/neves_capital
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter build ios --release
```

### Abrir Xcode
```bash
cd /Users/wagneralves/StudioProjects/neves_capital/ios
open Runner.xcworkspace
```

### Rodar para Screenshots
```bash
cd /Users/wagneralves/StudioProjects/neves_capital
flutter run -d "iPhone 16e"
```

### Incrementar Versão (para updates)
Editar `pubspec.yaml`:
```yaml
version: 1.0.1+4  # 1.0.1 = version, 4 = build number
```

---

## ⚠️ PONTOS CRÍTICOS PARA APPS FINANCEIROS

### 1. Documentação Legal
- [ ] **Política de Privacidade** - OBRIGATÓRIO
- [ ] **Termos de Uso** - RECOMENDADO
- [ ] Compliance com LGPD
- [ ] Transparência sobre taxas

### 2. Segurança
- [x] Autenticação segura (Firebase Auth)
- [x] Biometria (Face ID/Touch ID)
- [ ] Política clara de dados sensíveis

### 3. Funcionalidades Financeiras
Apple pode pedir:
- [ ] Licença para operar serviços financeiros
- [ ] Comprovação de parcerias (ex: Pagar.me)
- [ ] Termos claros sobre processamento de pagamentos

**RECOMENDAÇÃO:** Consulte um advogado especializado em fintech.

---

## 📸 CHECKLIST DE MATERIAIS

### Obrigatórios
- [ ] 3-10 Screenshots (1290x2796)
- [ ] Ícone 1024x1024 PNG
- [ ] Política de Privacidade (URL pública)
- [ ] Descrição do app
- [ ] Keywords
- [ ] Support URL
- [ ] Classificação etária
- [ ] Questionário de privacidade respondido

### Recomendados
- [ ] Termos de Uso (URL)
- [ ] App Preview (vídeo)
- [ ] Marketing URL
- [ ] Promotional Text

---

## 🎉 COMEÇAR AGORA

### O Que Fazer HOJE:

1. **Screenshots** (30-60 min)
   ```bash
   flutter run -d "iPhone 16e"
   # Navegue pelo app e pressione Cmd+S em cada tela
   ```

2. **Política de Privacidade** (1-2 horas)
   - Editar `docs/TEMPLATE_POLITICA_PRIVACIDADE.md`
   - Publicar online (GitHub Pages, Notion, site próprio)

3. **Configurar Xcode** (15 min)
   ```bash
   open ios/Runner.xcworkspace
   # Configure Team e Bundle ID
   ```

4. **Build Release** (10 min)
   ```bash
   flutter clean
   flutter pub get
   cd ios && pod install && cd ..
   flutter build ios --release
   ```

5. **Archive** (20-30 min)
   - No Xcode: Product → Archive
   - Upload para App Store Connect

### O Que Fazer AMANHÃ:

1. Criar app no App Store Connect
2. Preencher todas as informações
3. Adicionar build quando processar
4. Submeter para revisão

### RESULTADO EM 5-7 DIAS:

✅ App publicado na App Store!

---

## 📞 Precisa de Ajuda?

- **Documentação completa:** `docs/PUBLICACAO_APP_STORE.md`
- **Screenshots:** `docs/GUIA_SCREENSHOTS.md`
- **Política Privacidade:** `docs/TEMPLATE_POLITICA_PRIVACIDADE.md`
- **Apple Support:** https://developer.apple.com/support/

---

## ⏱️ Estimativa de Tempo Total

| Etapa | Tempo |
|-------|-------|
| Preparar materiais | 2-4 horas |
| Configurar Xcode | 30 min |
| Build e Archive | 30-60 min |
| Criar app no App Store Connect | 1-2 horas |
| Aguardar processamento | 15-60 min |
| Submeter | 15 min |
| **Aguardar revisão Apple** | **1-5 dias** |
| **TOTAL** | **~1 semana** |

---

## 🎯 PRÓXIMO COMANDO A EXECUTAR

```bash
# 1. Limpar e preparar build
cd /Users/wagneralves/StudioProjects/neves_capital
flutter clean && flutter pub get

# 2. Atualizar pods iOS
cd ios && pod install && cd ..

# 3. Build release
flutter build ios --release

# 4. Abrir Xcode para Archive
open ios/Runner.xcworkspace
```

**Depois de executar, no Xcode:**
- Product → Archive
- Distribute App → App Store Connect → Upload

---

Pronto para começar? Execute os comandos acima! 🚀

