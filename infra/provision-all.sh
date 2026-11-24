#!/usr/bin/env bash
# Orquestador maestro de Provision Cloud (AWS) para ViajaMejor.
# Ejecuta secuencialmente todas las etapas de creacion/actualizacion de recursos cloud.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================================"
echo "  ViajaMejor — Provision Automatizada de Recursos Cloud"
echo "============================================================"

bash "${SCRIPT_DIR}/01-provision-storage-and-queues.sh"
bash "${SCRIPT_DIR}/02-provision-database.sh"
bash "${SCRIPT_DIR}/03-deploy-serverless.sh"
bash "${SCRIPT_DIR}/04-provision-api-gateway.sh"

echo ""
echo "============================================================"
echo "  Provision Cloud completada con exito."
echo "============================================================"
if [[ -f "${SCRIPT_DIR}/outputs.env" ]]; then
  cat "${SCRIPT_DIR}/outputs.env"
fi
