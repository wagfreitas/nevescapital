#!/bin/bash

# Script para abrir Xcode e preparar ambiente para publicação
# Uso: ./scripts/open-xcode-publish.sh [--clean|--clear] [--update]

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretórios
PROJECT_ROOT="/Users/wagneralves/StudioProjects/neves_capital"
IOS_DIR="$PROJECT_ROOT/ios"
WORKSPACE="$IOS_DIR/Runner.xcworkspace"

# Flags
CLEAN=false
UPDATE=false

# Parse argumentos
while [[ $# -gt 0 ]]; do
  case $1 in
    --clean|--clear)
      CLEAN=true
      shift
      ;;
    --update)
      UPDATE=true
      shift
      ;;
    *)
      echo -e "${RED}❌ Argumento desconhecido: $1${NC}"
      echo "Uso: $0 [--clean|--clear] [--update]"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}🚀 Preparando ambiente para publicação no Xcode...${NC}"
echo ""

# 1. Verificar se está no diretório correto
if [ ! -d "$PROJECT_ROOT" ]; then
  echo -e "${RED}❌ Erro: Diretório do projeto não encontrado: $PROJECT_ROOT${NC}"
  exit 1
fi

cd "$PROJECT_ROOT"
echo -e "${GREEN}✅ Diretório do projeto encontrado${NC}"

# 2. Verificar se Xcode está instalado
if ! command -v xcodebuild &> /dev/null; then
  echo -e "${RED}❌ Erro: Xcode não encontrado!${NC}"
  echo "   Instale o Xcode da App Store ou via: xcode-select --install"
  exit 1
fi

XCODE_VERSION=$(xcodebuild -version | head -n 1)
echo -e "${GREEN}✅ Xcode encontrado: $XCODE_VERSION${NC}"

# 3. Verificar se Flutter está instalado
if ! command -v flutter &> /dev/null; then
  echo -e "${RED}❌ Erro: Flutter não encontrado!${NC}"
  exit 1
fi

FLUTTER_VERSION=$(flutter --version | head -n 1)
echo -e "${GREEN}✅ Flutter encontrado: $FLUTTER_VERSION${NC}"

# 4. Garantir que Generated.xcconfig existe antes de verificar workspace
# (Necessário para pod install funcionar corretamente)
GENERATED_XCCONFIG="$IOS_DIR/Flutter/Generated.xcconfig"
if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo -e "${YELLOW}⚠️  Generated.xcconfig não encontrado. Gerando...${NC}"
  cd "$PROJECT_ROOT"
  flutter pub get
  
  if [ ! -f "$GENERATED_XCCONFIG" ]; then
    echo -e "${RED}❌ Erro: Não foi possível gerar Generated.xcconfig${NC}"
    echo "   Tente executar manualmente: cd $PROJECT_ROOT && flutter pub get"
    exit 1
  fi
  echo -e "${GREEN}✅ Generated.xcconfig gerado${NC}"
fi

# 4.1. Verificar se o workspace existe
if [ ! -d "$WORKSPACE" ]; then
  echo -e "${YELLOW}⚠️  Workspace não encontrado: $WORKSPACE${NC}"
  echo "   Tentando criar workspace..."
  
  cd "$IOS_DIR"
  
  # Instalar pods se necessário
  if [ ! -d "Pods" ]; then
    echo -e "${BLUE}📦 Instalando CocoaPods...${NC}"
    pod install
  fi
  
  if [ ! -d "$WORKSPACE" ]; then
    echo -e "${RED}❌ Erro: Não foi possível criar o workspace${NC}"
    exit 1
  fi
fi

echo -e "${GREEN}✅ Workspace encontrado${NC}"

# 5. Limpar projeto (se solicitado)
if [ "$CLEAN" = true ]; then
  echo ""
  echo -e "${BLUE}🧹 Limpando projeto Flutter...${NC}"
  cd "$PROJECT_ROOT"
  flutter clean
  echo -e "${GREEN}✅ Projeto limpo${NC}"
  
  # Regenerar Generated.xcconfig após limpar
  echo ""
  echo -e "${BLUE}📦 Regenerando arquivos Flutter...${NC}"
  flutter pub get
  
  # Verificar se Generated.xcconfig foi criado
  if [ ! -f "$GENERATED_XCCONFIG" ]; then
    echo -e "${RED}❌ Erro: Generated.xcconfig não foi gerado após flutter pub get${NC}"
    exit 1
  fi
  echo -e "${GREEN}✅ Arquivos Flutter regenerados${NC}"
  
  # Limpar e reinstalar CocoaPods para sincronizar sandbox
  echo ""
  echo -e "${BLUE}🧹 Limpando CocoaPods...${NC}"
  cd "$IOS_DIR"
  
  # Remover Pods e Podfile.lock se existirem
  if [ -d "Pods" ]; then
    rm -rf Pods
    echo -e "   - Removido diretório Pods${NC}"
  fi
  
  if [ -f "Podfile.lock" ]; then
    rm -f Podfile.lock
    echo -e "   - Removido Podfile.lock${NC}"
  fi
  
  # Reinstalar pods
  echo ""
  echo -e "${BLUE}📦 Reinstalando CocoaPods...${NC}"
  pod install
  
  if [ ! -d "$WORKSPACE" ]; then
    echo -e "${RED}❌ Erro: Não foi possível criar o workspace após pod install${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}✅ CocoaPods reinstalado e sincronizado${NC}"
fi

# 6. Atualizar dependências (se solicitado)
if [ "$UPDATE" = true ]; then
  echo ""
  echo -e "${BLUE}📦 Atualizando dependências...${NC}"
  cd "$PROJECT_ROOT"
  
  echo "   - Flutter pub get..."
  flutter pub get
  
  echo "   - CocoaPods..."
  cd "$IOS_DIR"
  pod install
  
  echo -e "${GREEN}✅ Dependências atualizadas${NC}"
fi

# 6.5. Verificação final: garantir que Generated.xcconfig existe e pods estão sincronizados
GENERATED_XCCONFIG="$IOS_DIR/Flutter/Generated.xcconfig"
if [ ! -f "$GENERATED_XCCONFIG" ]; then
  echo ""
  echo -e "${YELLOW}⚠️  Generated.xcconfig não encontrado. Gerando...${NC}"
  cd "$PROJECT_ROOT"
  flutter pub get
  
  # Verificar se o arquivo foi criado com sucesso
  if [ ! -f "$GENERATED_XCCONFIG" ]; then
    echo -e "${RED}❌ Erro: Não foi possível gerar Generated.xcconfig${NC}"
    echo "   Tente executar manualmente: cd $PROJECT_ROOT && flutter pub get"
    exit 1
  fi
  echo -e "${GREEN}✅ Generated.xcconfig gerado${NC}"
fi

# Verificar se CocoaPods está instalado e sincronizado
cd "$IOS_DIR"
if [ ! -d "Pods" ] || [ ! -f "Podfile.lock" ]; then
  echo ""
  echo -e "${YELLOW}⚠️  CocoaPods não instalado ou incompleto. Instalando...${NC}"
  pod install
  if [ ! -d "$WORKSPACE" ]; then
    echo -e "${RED}❌ Erro: Não foi possível criar o workspace após pod install${NC}"
    exit 1
  fi
  echo -e "${GREEN}✅ CocoaPods instalado e sincronizado${NC}"
fi

# 7. Verificar versão atual
echo ""
echo -e "${BLUE}📋 Informações do projeto:${NC}"
cd "$PROJECT_ROOT"

if [ -f "pubspec.yaml" ]; then
  VERSION=$(grep "^version:" pubspec.yaml | cut -d " " -f 2)
  APP_NAME=$(grep "^name:" pubspec.yaml | cut -d " " -f 2)
  echo -e "   App: ${GREEN}$APP_NAME${NC}"
  echo -e "   Versão: ${GREEN}$VERSION${NC}"
fi

# 8. Verificar configurações do Xcode
echo ""
echo -e "${BLUE}🔍 Verificando configurações do Xcode...${NC}"

cd "$IOS_DIR"

# Verificar Bundle ID
BUNDLE_ID=$(xcodebuild -showBuildSettings -workspace Runner.xcworkspace -scheme Runner 2>/dev/null | grep "PRODUCT_BUNDLE_IDENTIFIER" | head -n 1 | cut -d "=" -f 2 | xargs)
if [ -n "$BUNDLE_ID" ]; then
  echo -e "   Bundle ID: ${GREEN}$BUNDLE_ID${NC}"
else
  echo -e "   ${YELLOW}⚠️  Bundle ID não encontrado (verifique no Xcode)${NC}"
fi

# 9. Abrir Xcode
echo ""
echo -e "${GREEN}🚀 Abrindo Xcode...${NC}"
echo -e "${BLUE}   Workspace: $WORKSPACE${NC}"
echo ""

open "$WORKSPACE"

# 10. Mostrar instruções
echo ""
echo -e "${GREEN}✅ Xcode aberto com sucesso!${NC}"
echo ""
echo -e "${YELLOW}📝 Próximos passos para publicação:${NC}"
echo ""
echo -e "   1. ${BLUE}Verificar Signing & Capabilities:${NC}"
echo "      • Selecione 'Runner' no painel esquerdo"
echo "      • Aba 'Signing & Capabilities'"
echo "      • Verifique Team, Bundle ID e 'Automatically manage signing'"
echo ""
echo -e "   2. ${BLUE}Selecionar dispositivo:${NC}"
echo "      • No topo, selecione: 'Any iOS Device (arm64)'"
echo "      • NÃO selecione simulador!"
echo ""
echo -e "   3. ${BLUE}Criar Archive:${NC}"
echo "      • Menu: Product → Archive"
echo "      • Aguarde a compilação (5-15 minutos)"
echo ""
echo -e "   4. ${BLUE}Upload para App Store Connect:${NC}"
echo "      • Quando Archive terminar, clique em 'Distribute App'"
echo "      • Selecione 'App Store Connect' → 'Upload'"
echo ""
echo -e "${YELLOW}💡 Dica: Use Fastlane para automatizar:${NC}"
echo "   cd ios && fastlane beta"
echo ""
echo -e "${GREEN}✨ Boa sorte com a publicação!${NC}"






