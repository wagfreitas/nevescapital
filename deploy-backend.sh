#!/bin/bash

echo "🚀 Fazendo deploy do backend para Cloud Run..."
echo ""

# Verificar se está na pasta functions
if [ ! -f "functions/package.json" ]; then
    echo "❌ Erro: Execute este script da raiz do projeto"
    exit 1
fi

# Verificar se gcloud está instalado
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI não encontrado"
    echo "   Instale: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Verificar se está autenticado
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo "❌ Não autenticado no gcloud"
    echo "   Execute: gcloud auth login"
    exit 1
fi

echo "📦 Fazendo build do backend..."
cd functions

# Build
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Erro no build"
    exit 1
fi

echo ""
echo "🚀 Fazendo deploy para Cloud Run..."
echo ""

# Deploy com variáveis de ambiente
gcloud run deploy neves-capital-api \
  --source . \
  --region us-central1 \
  --project pagpagapp \
  --allow-unauthenticated \
  --set-env-vars="API_KEY=neves-capital-api-key-prod-2024,GOOGLE_CLOUD_PROJECT=pagpagapp"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deploy concluído com sucesso!"
    echo ""
    echo "📍 URL: https://neves-capital-api-124871515546.us-central1.run.app"
    echo "📚 Docs: https://neves-capital-api-124871515546.us-central1.run.app/api/docs"
else
    echo "❌ Erro no deploy"
    exit 1
fi

