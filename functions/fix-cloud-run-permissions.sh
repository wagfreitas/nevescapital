#!/bin/bash

echo "🔐 Configurando permissões IAM para o serviço Cloud Run..."
echo ""

# Verificar se gcloud está instalado
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI não encontrado"
    exit 1
fi

PROJECT_ID="pagpagapp"
SERVICE_NAME="neves-capital-api"
REGION="us-central1"
SERVICE_ACCOUNT="${SERVICE_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "📋 Projeto: ${PROJECT_ID}"
echo "📋 Serviço: ${SERVICE_NAME}"
echo "📋 Região: ${REGION}"
echo ""

# 1. Obter o email da conta de serviço do Cloud Run
echo "🔍 Obtendo conta de serviço do Cloud Run..."
SERVICE_ACCOUNT_EMAIL=$(gcloud run services describe ${SERVICE_NAME} \
  --region=${REGION} \
  --project=${PROJECT_ID} \
  --format="value(spec.template.spec.serviceAccountName)" 2>/dev/null)

# Se não encontrar conta específica, obter o número do projeto e usar a conta padrão do Compute Engine
if [ -z "$SERVICE_ACCOUNT_EMAIL" ]; then
    echo "⚠️  Conta de serviço específica não encontrada. Obtendo conta padrão do Compute Engine..."
    PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} --format="value(projectNumber)" 2>/dev/null)
    
    if [ -z "$PROJECT_NUMBER" ]; then
        echo "❌ Erro: Não foi possível obter o número do projeto"
        exit 1
    fi
    
    SERVICE_ACCOUNT_EMAIL="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
    echo "📋 Usando conta padrão do Compute Engine: ${SERVICE_ACCOUNT_EMAIL}"
else
    echo "✅ Conta de serviço encontrada: ${SERVICE_ACCOUNT_EMAIL}"
fi

echo ""

# 2. Conceder permissões necessárias para o Firestore
echo "🔐 Concedendo permissões IAM..."

# Role para acessar Firestore/Datastore
echo "  → Adicionando role: roles/datastore.user"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/datastore.user" \
  --condition=None

# Role alternativa mais permissiva (se necessário)
echo "  → Adicionando role: roles/firebase.admin (opcional, mais permissiva)"
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
  --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role="roles/firebase.admin" \
  --condition=None

echo ""
echo "✅ Permissões configuradas!"
echo ""
echo "📝 Nota: Pode levar alguns minutos para as permissões serem propagadas."
echo "📝 Se o erro persistir, aguarde alguns minutos e tente novamente."


