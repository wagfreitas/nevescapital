# 🔥 Configuração do Firebase - Guia Completo

## 📋 Pré-requisitos
- Conta Google
- Projeto Flutter configurado
- Terminal com acesso ao Flutter CLI

## 🚀 Passo 1: Criar Projeto no Firebase Console

1. **Acesse o Firebase Console:**
   - Vá para: https://console.firebase.google.com/
   - Faça login com sua conta Google

2. **Criar Novo Projeto:**
   - Clique em "Adicionar projeto"
   - Nome do projeto: `neves-capital` (ou seu nome preferido)
   - Desabilite Google Analytics (opcional)
   - Clique em "Criar projeto"

## 📱 Passo 2: Configurar App Android

1. **Adicionar App Android:**
   - No console Firebase, clique no ícone Android
   - Package name: `com.example.nevesCapital`
   - App nickname: `Neves Capital Android`
   - Clique em "Registrar app"

2. **Baixar google-services.json:**
   - Baixe o arquivo `google-services.json`
   - Coloque em: `android/app/google-services.json`

3. **Configurar build.gradle:**
   - Adicione no `android/build.gradle`:
   ```gradle
   buildscript {
     dependencies {
       classpath 'com.google.gms:google-services:4.3.15'
     }
   }
   ```
   - Adicione no `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

## 🍎 Passo 3: Configurar App iOS

1. **Adicionar App iOS:**
   - No console Firebase, clique no ícone iOS
   - Bundle ID: `com.example.nevesCapital`
   - App nickname: `Neves Capital iOS`
   - Clique em "Registrar app"

2. **Baixar GoogleService-Info.plist:**
   - Baixe o arquivo `GoogleService-Info.plist`
   - Coloque em: `ios/Runner/GoogleService-Info.plist`

3. **Configurar Xcode:**
   - Abra `ios/Runner.xcworkspace` no Xcode
   - Arraste o `GoogleService-Info.plist` para o projeto
   - Certifique-se que está no target "Runner"

## 🔧 Passo 4: Configurar Authentication

1. **Habilitar Authentication:**
   - No console Firebase, vá em "Authentication"
   - Clique em "Começar"
   - Vá na aba "Sign-in method"
   - Habilite "Email/Password"

2. **Configurar Regras de Segurança:**
   - Vá em "Firestore Database" (se usar)
   - Configure regras básicas:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

## 📦 Passo 5: Instalar Firebase CLI

```bash
# Instalar Firebase CLI
npm install -g firebase-tools

# Fazer login
firebase login

# Inicializar projeto (opcional)
firebase init
```

## 🔑 Passo 6: Configurar Variáveis de Ambiente

1. **Criar arquivo de configuração:**
   ```dart
   // lib/config/firebase_config.dart
   class FirebaseConfig {
     static const String apiKey = 'sua-api-key';
     static const String authDomain = 'seu-projeto.firebaseapp.com';
     static const String projectId = 'seu-projeto-id';
     static const String storageBucket = 'seu-projeto.appspot.com';
     static const String messagingSenderId = '123456789';
     static const String appId = 'seu-app-id';
   }
   ```

## 🧪 Passo 7: Testar Configuração

1. **Executar app:**
   ```bash
   flutter run
   ```

2. **Verificar logs:**
   - Deve aparecer: "Firebase initialized successfully"
   - Sem erros de configuração

## 🚨 Troubleshooting

### Erro: "No Firebase App '[DEFAULT]' has been created"
- Verifique se os arquivos de configuração estão nos locais corretos
- Execute `flutter clean` e `flutter pub get`

### Erro: "GoogleService-Info.plist not found"
- Verifique se o arquivo está em `ios/Runner/`
- Certifique-se que está adicionado ao target no Xcode

### Erro: "google-services.json not found"
- Verifique se o arquivo está em `android/app/`
- Verifique se o package name está correto

## 📝 Próximos Passos

1. ✅ Configurar Cloud Functions para PostgreSQL
2. ✅ Implementar regras de segurança
3. ✅ Configurar Analytics (opcional)
4. ✅ Configurar Crashlytics (opcional)
5. ✅ Configurar Performance Monitoring (opcional)

## 🔐 Segurança

- **Nunca commite** arquivos de configuração com dados sensíveis
- Use **variáveis de ambiente** em produção
- Configure **regras de segurança** adequadas
- Mantenha as **dependências atualizadas**

---

**🎯 Após seguir este guia, seu Firebase estará configurado e pronto para uso!**
