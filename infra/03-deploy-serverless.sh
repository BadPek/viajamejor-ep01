#!/usr/bin/env bash
# Etapa 3 de Provision Cloud (IE5 + IE10):
# Despliega la funcion AWS Lambda viajamejor-voucher-generator y conecta el trigger SQS.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -f "${SCRIPT_DIR}/outputs.env" ]]; then
  # shellcheck disable=SC1091
  source "${SCRIPT_DIR}/outputs.env"
fi

bash "${ROOT_DIR}/serverless/voucher-generator/deploy.sh"
