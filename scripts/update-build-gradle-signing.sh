#!/bin/bash

# Script para atualizar automaticamente o build.gradle.kts com configuração de signing
# Este script adiciona o código necessário para usar o keystore

set -e

BUILD_GRADLE="android/app/build.gradle.kts"
BACKUP_FILE="${BUILD_GRADLE}.backup"

echo "🔧 Atualizando build.gradle.kts com configuração de signing..."

# Verificar se arquivo existe
if [ ! -f "$BUILD_GRADLE" ]; then
    echo "❌ Erro: $BUILD_GRADLE não encontrado"
    exit 1
fi

# Verificar se já está configurado
if grep -q "keystoreProperties" "$BUILD_GRADLE"; then
    echo "✅ build.gradle.kts já está configurado com signing"
    exit 0
fi

# Criar backup
cp "$BUILD_GRADLE" "$BACKUP_FILE"
echo "📋 Backup criado: $BACKUP_FILE"

# Ler o arquivo atual
CONTENT=$(cat "$BUILD_GRADLE")

# Verificar se precisa adicionar import
if ! grep -q "import java.util.Properties" "$BUILD_GRADLE"; then
    # Adicionar import após os outros imports
    CONTENT=$(echo "$CONTENT" | sed '/^plugins {/a\
import java.util.Properties\
import java.io.FileInputStream
')
fi

# Adicionar código de keystore antes do bloco android
KEYSTORE_CODE='val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}'

# Inserir antes do bloco android
CONTENT=$(echo "$CONTENT" | sed "/^android {/i\\
$KEYSTORE_CODE
")

# Adicionar signingConfigs dentro do bloco android
SIGNING_CONFIG='signingConfigs {
    create("release") {
        if (keystorePropertiesFile.exists()) {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
}'

# Inserir após defaultConfig
CONTENT=$(echo "$CONTENT" | sed "/multiDexEnabled = true/a\\
\\
    $SIGNING_CONFIG
")

# Atualizar buildTypes release
CONTENT=$(echo "$CONTENT" | sed 's/signingConfig = signingConfigs.getByName("debug")/signingConfig = signingConfigs.getByName("release")/')

# Salvar arquivo
echo "$CONTENT" > "$BUILD_GRADLE"

echo "✅ build.gradle.kts atualizado com sucesso!"
echo ""
echo "⚠️  IMPORTANTE: Revise o arquivo antes de fazer commit"
echo "   Arquivo: $BUILD_GRADLE"
echo "   Backup: $BACKUP_FILE"
echo ""


