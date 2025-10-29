#!/bin/bash

# Script para converter logo em Base64 e mostrar como usar no template

LOGO_PATH="assets/icons/PagPag.png"

if [ ! -f "$LOGO_PATH" ]; then
    echo "❌ Logo não encontrada em: $LOGO_PATH"
    exit 1
fi

echo "🖼️  Convertendo logo para Base64..."
echo ""

# Converter para Base64
BASE64=$(base64 -i "$LOGO_PATH")

echo "✅ Conversão completa!"
echo ""
echo "📝 Copie o Base64 abaixo e use no template:"
echo ""
echo "data:image/png;base64,$BASE64"
echo ""
echo "💡 Para usar no código TypeScript, defina:"
echo "   const LOGO_BASE64 = '${BASE64:0:50}...';"
echo ""
echo "📏 Tamanho: $(echo -n "$BASE64" | wc -c | xargs) caracteres"
echo "📦 Tamanho original: $(ls -lh "$LOGO_PATH" | awk '{print $5}')"
echo ""

