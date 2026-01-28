# 🚀 Quick Start - Publicação Google Play

## Passo a Passo Rápido

### 1️⃣ Primeira Vez - Configuração Inicial

```bash
# 1. Gerar keystore (apenas uma vez)
./scripts/generate-keystore.sh

# 2. Configurar assinatura
./scripts/setup-android-signing.sh

# 3. Atualizar build.gradle.kts automaticamente
./scripts/update-build-gradle-signing.sh
```

### 2️⃣ Build e Publicação

```bash
# Build do App Bundle
./scripts/build-android-release.sh
```

### 3️⃣ Upload no Google Play Console

1. Acesse: https://play.google.com/console
2. Vá em: **Teste** > **Teste interno**
3. Clique em: **Criar nova versão**
4. Faça upload do arquivo: `build/app/outputs/bundle/release/app-release.aab`
5. Clique em: **Iniciar teste interno**

## 📝 Checklist Rápido

- [ ] Keystore gerado
- [ ] key.properties configurado
- [ ] build.gradle.kts atualizado
- [ ] Versão incrementada no pubspec.yaml
- [ ] Build executado com sucesso
- [ ] Upload feito no Google Play Console

## 🔄 Para Atualizações Futuras

Apenas execute:
```bash
./scripts/build-android-release.sh
```

E faça upload da nova versão no Google Play Console.

## ⚠️ Importante

- **NUNCA** commite o arquivo `android/key.properties`
- **NUNCA** compartilhe o keystore ou senhas
- **SEMPRE** incremente o `versionCode` no pubspec.yaml


