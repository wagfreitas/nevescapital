#!/bin/bash

# Script para processar ícone iOS preenchendo toda área

INPUT="assets/icons/logo.png"
OUTPUT="assets/icons/logo_ios_filled.png"

echo "🖼️  Processando ícone para iOS..."

# Verificar se imagemagick está instalado
if ! command -v convert &> /dev/null; then
    echo "📦 Instalando ImageMagick..."
    brew install imagemagick || {
        echo "❌ ImageMagick não encontrado. Instale com: brew install imagemagick"
        echo "💡 Alternativa: Use uma ferramenta online para redimensionar para 1024x1024"
        exit 1
    }
fi

# Criar ícone 1024x1024 com fundo verde (preenchendo toda área)
# Primeiro, extrair a cor dominante do fundo (verde escuro)
BG_COLOR="#122118"  # Cor verde escuro do background

echo "📐 Redimensionando para 1024x1024 com fundo preenchido..."

# Criar imagem 1024x1024 com fundo verde
convert -size 1024x1024 xc:"$BG_COLOR" \
    \( "$INPUT" -resize 950x950 -background none -gravity center \) \
    -composite \
    "$OUTPUT"

echo "✅ Ícone processado: $OUTPUT"
echo ""
echo "📊 Dimensões:"
identify "$OUTPUT" || sips -g pixelWidth -g pixelHeight "$OUTPUT"
echo ""
echo "💡 Próximo passo: Atualize pubspec.yaml para usar: assets/icons/logo_ios_filled.png"



