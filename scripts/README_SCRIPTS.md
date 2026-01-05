# 📜 Scripts do Projeto

Guia rápido de uso dos scripts disponíveis.

---

## 🚀 Abrir Xcode para Publicação

### Script Completo (Recomendado)

```bash
./scripts/open-xcode-publish.sh
```

**Opções disponíveis:**
- `--clean`: Limpa o projeto Flutter antes de abrir
- `--update`: Atualiza dependências (Flutter + CocoaPods) antes de abrir

**Exemplos:**
```bash
# Apenas abrir Xcode
./scripts/open-xcode-publish.sh

# Limpar e abrir
./scripts/open-xcode-publish.sh --clean

# Atualizar dependências e abrir
./scripts/open-xcode-publish.sh --update

# Limpar, atualizar e abrir
./scripts/open-xcode-publish.sh --clean --update
```

**O que o script faz:**
1. ✅ Verifica se Xcode está instalado
2. ✅ Verifica se Flutter está instalado
3. ✅ Verifica se o workspace existe
4. ✅ Instala CocoaPods se necessário
5. ✅ Limpa projeto (se `--clean`)
6. ✅ Atualiza dependências (se `--update`)
7. ✅ Mostra informações do projeto (versão, bundle ID)
8. ✅ Abre o Xcode com o workspace correto
9. ✅ Mostra instruções de publicação

---

### Script Rápido

```bash
./scripts/open-xcode.sh
```

Abre o Xcode diretamente, sem verificações. Use quando já tiver certeza de que tudo está configurado.

---

## 📦 Outros Scripts Úteis

### Incrementar Versão

```bash
./scripts/increment_version.sh [patch|minor|major]
```

**Exemplos:**
```bash
./scripts/increment_version.sh patch   # 1.0.0 → 1.0.1
./scripts/increment_version.sh minor   # 1.0.0 → 1.1.0
./scripts/increment_version.sh major   # 1.0.0 → 2.0.0
```

---

## 🎯 Workflow Completo de Publicação

### 1. Preparar Ambiente

```bash
# Limpar, atualizar e abrir Xcode
./scripts/open-xcode-publish.sh --clean --update
```

### 2. No Xcode

1. **Verificar Signing:**
   - Selecione "Runner" → "Signing & Capabilities"
   - Verifique Team, Bundle ID, "Automatically manage signing"

2. **Selecionar Dispositivo:**
   - Selecione: "Any iOS Device (arm64)"

3. **Criar Archive:**
   - Menu: **Product → Archive**
   - Aguarde (5-15 minutos)

4. **Upload:**
   - Clique "Distribute App"
   - Selecione "App Store Connect" → "Upload"

### 3. Alternativa: Fastlane (Automação)

```bash
cd ios
fastlane beta  # Para TestFlight
```

---

## 📋 Checklist Antes de Publicar

- [ ] Versão atualizada (`./scripts/increment_version.sh`)
- [ ] Projeto limpo e dependências atualizadas
- [ ] Xcode configurado corretamente (Team, Bundle ID)
- [ ] Testado localmente
- [ ] Changelog preparado

---

## 🐛 Problemas Comuns

### Erro: "Workspace não encontrado"

```bash
cd ios
pod install
```

### Erro: "Xcode não encontrado"

```bash
xcode-select --install
```

### Erro: "Flutter não encontrado"

Verifique se o Flutter está no PATH:
```bash
which flutter
export PATH="$PATH:/caminho/para/flutter/bin"
```

---

## 📚 Documentação Completa

- **Guia Xcode:** `docs/GUIA_UPLOAD_XCODE.md`
- **Guia Fastlane:** `docs/GUIA_FASTLANE.md`
- **Próximos Passos:** `PROXIMOS_PASSOS_PUBLICACAO_APPLE.md`

---

**Boa sorte com a publicação! 🚀**






