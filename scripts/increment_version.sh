#!/bin/bash

# Script para incrementar versão do app automaticamente
# Uso: ./scripts/increment_version.sh [patch|minor|major]

set -e

PUBSPEC_FILE="pubspec.yaml"

if [ ! -f "$PUBSPEC_FILE" ]; then
  echo "❌ Erro: pubspec.yaml não encontrado"
  exit 1
fi

# Lê versão atual
CURRENT_VERSION=$(grep "^version:" "$PUBSPEC_FILE" | cut -d " " -f 2 | cut -d "+" -f 1)
CURRENT_BUILD=$(grep "^version:" "$PUBSPEC_FILE" | cut -d "+" -f 2)

# Parse versão (ex: 1.2.3)
IFS='.' read -r -a VERSION_PARTS <<< "$CURRENT_VERSION"
MAJOR=${VERSION_PARTS[0]}
MINOR=${VERSION_PARTS[1]}
PATCH=${VERSION_PARTS[2]}

# Tipo de incremento (patch por padrão)
INCREMENT_TYPE=${1:-patch}

# Incrementa build sempre
NEW_BUILD=$((CURRENT_BUILD + 1))

# Incrementa versão baseado no tipo
case $INCREMENT_TYPE in
  major)
    MAJOR=$((MAJOR + 1))
    MINOR=0
    PATCH=0
    ;;
  minor)
    MINOR=$((MINOR + 1))
    PATCH=0
    ;;
  patch)
    PATCH=$((PATCH + 1))
    ;;
  *)
    echo "❌ Tipo inválido: $INCREMENT_TYPE"
    echo "Uso: $0 [patch|minor|major]"
    exit 1
    ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# Atualiza pubspec.yaml
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS
  sed -i '' "s/^version:.*/version: $NEW_VERSION+$NEW_BUILD/" "$PUBSPEC_FILE"
else
  # Linux
  sed -i "s/^version:.*/version: $NEW_VERSION+$NEW_BUILD/" "$PUBSPEC_FILE"
fi

echo "✅ Versão atualizada:"
echo "   Antes: $CURRENT_VERSION+$CURRENT_BUILD"
echo "   Agora: $NEW_VERSION+$NEW_BUILD"
echo ""
echo "📝 Lembre-se de commitar a mudança:"
echo "   git add pubspec.yaml"
echo "   git commit -m 'chore: bump version to $NEW_VERSION+$NEW_BUILD'"
