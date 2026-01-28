#!/bin/bash

# Script para configurar assinatura Android no build.gradle.kts
# Este script atualiza o build.gradle.kts para usar o keystore

set -e

echo "🔧 Configurando assinatura Android..."

KEYSTORE_FILE="$HOME/upload-keystore.jks"
KEY_PROPERTIES="android/key.properties"
BUILD_GRADLE="android/app/build.gradle.kts"

# Verificar se keystore existe
if [ ! -f "$KEYSTORE_FILE" ]; then
    echo "❌ Erro: Keystore não encontrado em: $KEYSTORE_FILE"
    echo "   Execute primeiro: ./scripts/generate-keystore.sh"
    exit 1
fi

# Criar key.properties se não existir
if [ ! -f "$KEY_PROPERTIES" ]; then
    echo "📝 Criando arquivo key.properties..."
    
    read -sp "Digite a senha do keystore: " STORE_PASSWORD
    echo
    read -sp "Digite a senha da chave: " KEY_PASSWORD
    echo
    
    cat > "$KEY_PROPERTIES" << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=upload
storeFile=$KEYSTORE_FILE
EOF
    
    echo "✅ Arquivo key.properties criado!"
    echo ""
    echo "⚠️  IMPORTANTE: Adicione android/key.properties ao .gitignore!"
else
    echo "✅ Arquivo key.properties já existe"
fi

# Verificar se build.gradle.kts já está configurado
if grep -q "signingConfigs" "$BUILD_GRADLE"; then
    echo "✅ build.gradle.kts já está configurado com signing"
else
    echo "📝 Atualizando build.gradle.kts..."
    
    # Criar backup
    cp "$BUILD_GRADLE" "$BUILD_GRADLE.backup"
    
    # Adicionar configuração de signing antes do bloco android
    # Nota: Esta é uma atualização manual - você precisará editar o arquivo
    echo ""
    echo "⚠️  ATENÇÃO: Você precisa editar manualmente o arquivo:"
    echo "   $BUILD_GRADLE"
    echo ""
    echo "Adicione o seguinte código ANTES do bloco 'android {':"
    echo ""
    echo "val keystoreProperties = Properties()"
    echo "val keystorePropertiesFile = rootProject.file(\"key.properties\")"
    echo "if (keystorePropertiesFile.exists()) {"
    echo "    keystoreProperties.load(FileInputStream(keystorePropertiesFile))"
    echo "}"
    echo ""
    echo "E dentro do bloco 'android {', adicione:"
    echo ""
    echo "signingConfigs {"
    echo "    create(\"release\") {"
    echo "        keyAlias = keystoreProperties[\"keyAlias\"] as String"
    echo "        keyPassword = keystoreProperties[\"keyPassword\"] as String"
    echo "        storeFile = file(keystoreProperties[\"storeFile\"] as String)"
    echo "        storePassword = keystoreProperties[\"storePassword\"] as String"
    echo "    }"
    echo "}"
    echo ""
    echo "E no buildType release, altere:"
    echo "signingConfig = signingConfigs.getByName(\"release\")"
    echo ""
fi

echo ""
echo "✅ Configuração concluída!"
echo ""
echo "📋 Próximos passos:"
echo "   1. Edite android/app/build.gradle.kts conforme instruções acima"
echo "   2. Execute: ./scripts/build-android-release.sh"
echo ""


