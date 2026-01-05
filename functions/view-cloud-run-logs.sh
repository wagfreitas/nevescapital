#!/bin/bash

# Script para visualizar logs do Cloud Run

PROJECT_ID="pagpagapp"
SERVICE_NAME="neves-capital-api"
REGION="us-central1"

echo "📋 Visualizando logs do Cloud Run..."
echo "📋 Projeto: ${PROJECT_ID}"
echo "📋 Serviço: ${SERVICE_NAME}"
echo "📋 Região: ${REGION}"
echo ""

# Verificar argumentos
LIMIT=${1:-50}
FOLLOW=${2:-""}

if [ "$FOLLOW" == "follow" ] || [ "$FOLLOW" == "-f" ]; then
    echo "🔄 Modo follow ativado (Ctrl+C para sair)"
    echo ""
    gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=${SERVICE_NAME} AND resource.labels.location=${REGION}" \
        --project=${PROJECT_ID} \
        --limit=${LIMIT} \
        --format="table(timestamp,severity,textPayload,jsonPayload.message)" \
        --freshness=1h \
        --follow
else
    echo "📊 Últimas ${LIMIT} linhas de log:"
    echo ""
    gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=${SERVICE_NAME} AND resource.labels.location=${REGION}" \
        --project=${PROJECT_ID} \
        --limit=${LIMIT} \
        --format="table(timestamp,severity,textPayload,jsonPayload.message)" \
        --freshness=1h
fi

echo ""
echo "💡 Dicas:"
echo "   - Para seguir logs em tempo real: ./view-cloud-run-logs.sh 100 follow"
echo "   - Para ver mais linhas: ./view-cloud-run-logs.sh 200"
echo "   - Para filtrar por erro: gcloud logging read \"resource.type=cloud_run_revision AND resource.labels.service_name=${SERVICE_NAME} AND severity>=ERROR\" --project=${PROJECT_ID} --limit=50"

