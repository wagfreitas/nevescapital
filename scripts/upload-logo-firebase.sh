#!/bin/bash

# Script para fazer upload da logo para Firebase Hosting
# Uso: ./scripts/upload-logo-firebase.sh

echo "📦 Preparando upload da logo para Firebase Hosting..."

# Verifica se Firebase CLI está instalado
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI não encontrado!"
    echo "📥 Instale com: npm install -g firebase-tools"
    exit 1
fi

# Verifica se está logado no Firebase
echo "🔍 Verificando autenticação..."
if ! firebase projects:list &> /dev/null; then
    echo "🔑 Fazendo login no Firebase..."
    firebase login
fi

# Cria diretório temporário para assets
echo "📁 Criando estrutura de diretórios..."
mkdir -p public/assets/icons
mkdir -p public/assets/images

# Copia a logo
echo "📋 Copiando assets..."
cp assets/icons/PagPag.png public/assets/icons/PagPag.png
cp assets/icons/ios_120.png public/assets/icons/ios_120.png

# Cria arquivo de configuração do Firebase Hosting se não existir
if [ ! -f firebase.json ]; then
    echo "⚙️  Criando firebase.json..."
    cat > firebase.json << EOF
{
  "hosting": {
    "public": "public",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "**/*.@(png|jpg|jpeg|gif|svg|webp)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "max-age=31536000"
          }
        ]
      }
    ]
  }
}
EOF
fi

# Inicializa Firebase se necessário
if [ ! -f .firebaserc ]; then
    echo "🔧 Configurando projeto Firebase..."
    firebase init hosting
fi

# Deploy
echo "🚀 Fazendo deploy para Firebase Hosting..."
firebase deploy --only hosting

echo ""
echo "✅ Upload concluído!"
echo "📧 Use esta URL no template de email:"
echo "   https://apppagpag.firebaseapp.com/assets/icons/PagPag.png"
echo ""
echo "💡 Próximos passos:"
echo "   1. Acesse Firebase Console → Authentication → Templates"
echo "   2. Cole o template HTML de docs/firebase-email-templates/reset-password-template.html"
echo "   3. Substitua a URL da logo se necessário"
echo ""



