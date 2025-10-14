# 📱 Guia Completo: Publicação na Apple App Store

## 📋 Pré-requisitos

Antes de começar, você precisa ter:

### 1. **Apple Developer Account**
- Inscrição no Apple Developer Program ($99/ano)
- Acesse: https://developer.apple.com/programs/
- O processo de aprovação pode levar 24-48 horas

### 2. **Equipamento**
- ✅ Mac (você já tem)
- ✅ Xcode instalado (versão mais recente recomendada)

### 3. **Certificados e Provisioning Profiles**
- Serão criados durante o processo

---

## 🎯 Etapa 1: Preparar o Projeto

### 1.1 Definir Bundle Identifier único

Seu app precisa de um identificador único no formato: `com.suaempresa.nomeapp`

**Exemplo:** `com.nevescapital.apppagpag` ou `com.nevescapital.nevescapital`

Vamos configurar isso no Xcode.

### 1.2 Configurar versão e build number

Já está configurado no `pubspec.yaml`:
```yaml
version: 1.0.0+1
```
- `1.0.0` = Version (visível para usuários)
- `1` = Build Number (incrementa a cada upload)

### 1.3 Ícone do App

Você precisa fornecer o ícone em vários tamanhos. O Flutter facilita isso com:
- Usar a ferramenta `flutter_launcher_icons` OU
- Adicionar manualmente em `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

**Tamanhos necessários:**
- 1024x1024 (App Store)
- 180x180, 120x120, 87x87, 80x80, 60x60, 58x58, 40x40, 29x29, 20x20

---

## 🎯 Etapa 2: Configurar no Xcode

### 2.1 Abrir o projeto no Xcode

```bash
cd ios
open Runner.xcworkspace
```

⚠️ **IMPORTANTE:** Sempre abra o `.xcworkspace`, NÃO o `.xcodeproj` (por causa do CocoaPods)

### 2.2 Configurar Signing & Capabilities

1. No Xcode, selecione o projeto **Runner** (topo da hierarquia)
2. Selecione o target **Runner**
3. Vá para a aba **Signing & Capabilities**
4. Configure:
   - **Team:** Selecione sua equipe (Apple Developer Account)
   - **Bundle Identifier:** Defina um único (ex: `com.nevescapital.apppagpag`)
   - **Automatically manage signing:** ✅ Marque essa opção

O Xcode criará automaticamente:
- Development Certificate
- Distribution Certificate
- Provisioning Profiles

### 2.3 Verificar orientações suportadas

Em **Deployment Info**, defina:
- ✅ Portrait (recomendado)
- Landscape (se necessário)

---

## 🎯 Etapa 3: Criar App no App Store Connect

### 3.1 Acessar App Store Connect

1. Acesse: https://appstoreconnect.apple.com/
2. Clique em **"My Apps"**
3. Clique no botão **"+"** → **"New App"**

### 3.2 Preencher informações básicas

**Informações necessárias:**

- **Platform:** iOS
- **Name:** Nome do app (ex: "Neves Capital" ou "PagPag")
- **Primary Language:** Portuguese (Brazil)
- **Bundle ID:** O mesmo que você configurou no Xcode
- **SKU:** Um identificador único interno (ex: "nevescapital001")
- **User Access:** Full Access (recomendado)

### 3.3 Preparar informações do app

Você precisará fornecer:

#### Screenshots (Capturas de Tela)
- **iPhone 6.7"** (iPhone 14 Pro Max, 15 Pro Max): 1290x2796
- **iPhone 6.5"** (iPhone 11 Pro Max, XS Max): 1242x2688
- **iPad Pro 12.9"** (se suportar iPad): 2048x2732

**Mínimo:** 3 screenshots, **Recomendado:** 5-10 screenshots

#### Descrição do App
- **App Name:** Até 30 caracteres
- **Subtitle:** Até 30 caracteres
- **Promotional Text:** Até 170 caracteres (editável após publicação)
- **Description:** Até 4000 caracteres
- **Keywords:** Até 100 caracteres (separados por vírgula)
- **Support URL:** URL do site de suporte
- **Marketing URL:** (opcional)

#### Ícone
- 1024x1024 pixels (sem transparência, formato PNG)

#### Classificação de Conteúdo
- Responder questionário sobre o conteúdo do app

#### Informações de Contato
- Nome, e-mail, telefone

#### Informações de Privacidade
- **Privacy Policy URL:** Obrigatório para apps financeiros

---

## 🎯 Etapa 4: Build e Archive

### 4.1 Limpar o projeto

```bash
# No terminal, na raiz do projeto
flutter clean
flutter pub get
cd ios
pod install
cd ..
```

### 4.2 Criar build de produção

```bash
flutter build ios --release
```

Este comando:
- Compila o app em modo release
- Otimiza o código
- Remove debug symbols
- Gera o arquivo `.app`

### 4.3 Archive no Xcode

1. Abra o Xcode: `open ios/Runner.xcworkspace`
2. No menu superior, selecione:
   - Device: **"Any iOS Device (arm64)"**
3. Menu: **Product** → **Archive**
4. Aguarde o processo (pode levar 5-15 minutos)

### 4.4 Upload para App Store Connect

Quando o Archive finalizar:

1. A janela **Organizer** abrirá automaticamente
2. Selecione o archive mais recente
3. Clique em **"Distribute App"**
4. Selecione **"App Store Connect"**
5. Clique em **"Upload"**
6. Selecione:
   - ✅ Upload your app's symbols
   - ✅ Manage Version and Build Number (deixe o Xcode gerenciar)
7. Clique em **"Next"** → **"Upload"**

O upload pode levar de 5-30 minutos dependendo do tamanho e internet.

---

## 🎯 Etapa 5: Submeter para Revisão

### 5.1 Processar o build

Após o upload:
1. Acesse App Store Connect
2. Vá em **"My Apps"** → Seu app
3. Vá na aba **"TestFlight"**
4. O build aparecerá em **"Processing"**
5. Aguarde (15-60 minutos) até ficar **"Ready to Submit"**

### 5.2 Configurar versão para submissão

1. Vá na aba **"App Store"**
2. Clique em **"+ Version"** ou edite a versão existente
3. Preencha todas as informações obrigatórias:
   - Screenshots
   - Descrição
   - Keywords
   - Support URL
   - Privacy Policy URL
   - etc.

### 5.3 Adicionar o build

1. Na seção **"Build"**, clique em **"Select a build"**
2. Escolha o build que você acabou de fazer upload
3. Responda as perguntas sobre criptografia:
   - "Does your app use encryption?" → Geralmente **YES** (Firebase usa HTTPS)
   - Se sim, responda o questionário

### 5.4 Submeter para revisão

1. Clique em **"Add for Review"**
2. Responda perguntas adicionais (se houver)
3. Clique em **"Submit for Review"**

---

## 🎯 Etapa 6: Processo de Revisão da Apple

### 6.1 Timeline

- **In Review:** 24-48 horas (média)
- Pode ser mais rápido ou até 5-7 dias

### 6.2 Status possíveis

- **Waiting for Review:** Na fila
- **In Review:** Apple está testando
- **Pending Developer Release:** Aprovado! Você controla quando lançar
- **Ready for Sale:** Publicado na App Store
- **Rejected:** Precisa fazer correções

### 6.3 Se for rejeitado

- Leia o feedback da Apple cuidadosamente
- Faça as correções necessárias
- Incremente o build number
- Faça novo upload
- Resubmeta

---

## 📱 Checklist Final Antes de Submeter

### Código
- [ ] App funciona sem crashes
- [ ] Todas as funcionalidades testadas
- [ ] Sem console logs de debug
- [ ] Versão e build number corretos
- [ ] Bundle Identifier configurado

### App Store Connect
- [ ] Screenshots de qualidade
- [ ] Descrição completa e clara
- [ ] Keywords relevantes
- [ ] Ícone 1024x1024 sem transparência
- [ ] Privacy Policy URL configurada
- [ ] Support URL configurada
- [ ] Classificação de conteúdo respondida

### Certificados
- [ ] Team selecionado no Xcode
- [ ] Signing configurado corretamente
- [ ] Archive gerado sem erros

### Compliance
- [ ] Informações de exportação de criptografia respondidas
- [ ] Termos de uso aceitos
- [ ] Política de privacidade em conformidade com LGPD

---

## 🚨 Pontos de Atenção para Apps Financeiros

Como seu app é financeiro (PagPag/Neves Capital), a Apple tem requisitos extras:

### 1. **Documentação Financeira**
Pode ser solicitado:
- Comprovação de licenças financeiras
- Termos de uso claros
- Política de privacidade detalhada sobre dados financeiros

### 2. **Funcionalidades Sensíveis**
- ✅ Autenticação biométrica implementada
- ✅ Firebase Auth configurado
- Considerar 2FA (Two-Factor Authentication)

### 3. **Compliance**
- Conformidade com regulações brasileiras (LGPD)
- Termos claros sobre taxas e tarifas
- Processo claro de cancelamento/exclusão de conta

---

## 🛠️ Comandos Úteis

```bash
# Verificar versão do Flutter
flutter --version

# Verificar problemas no iOS
flutter doctor -v

# Limpar build cache
flutter clean

# Atualizar dependências
flutter pub get

# Build para iOS (teste)
flutter build ios --debug

# Build para iOS (produção)
flutter build ios --release

# Abrir no simulador iOS
flutter run -d "iPhone 15"

# Listar dispositivos
flutter devices
```

---

## 📞 Suporte e Recursos

### Documentação Oficial
- **Flutter iOS Deployment:** https://docs.flutter.dev/deployment/ios
- **App Store Connect:** https://developer.apple.com/app-store-connect/
- **App Store Review Guidelines:** https://developer.apple.com/app-store/review/guidelines/

### Em caso de dúvidas
- Apple Developer Forums
- Flutter Community
- Stack Overflow

---

## 🎉 Próximos Passos (Após Publicação)

1. **Monitor Analytics**
   - App Store Connect → Analytics
   - Acompanhe downloads, crashes, reviews

2. **Responder Reviews**
   - Responda feedback dos usuários

3. **Atualizações**
   - Incremente version e build number
   - Repita o processo de Archive e Upload

4. **TestFlight** (Opcional)
   - Use para testes beta antes de publicar
   - Adicione testadores internos/externos

---

## 🎯 Começando Agora

Qual etapa você quer começar primeiro?

1. **Configurar Bundle ID e preparar o Xcode?**
2. **Criar o app no App Store Connect?**
3. **Gerar screenshots e materiais de marketing?**
4. **Fazer o primeiro build e archive?**

Me avise qual parte quer começar e vou te guiar detalhadamente! 🚀

