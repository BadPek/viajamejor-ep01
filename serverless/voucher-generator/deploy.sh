#!/usr/bin/env bash
# Empaqueta y despliega la funcion AWS Lambda viajamejor-voucher-generator
# Compatible con AWS Academy Learner Lab (LabRole) y cuentas AWS estandar.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_REGION="${AWS_REGION:-us-east-1}"
FUNCTION_NAME="${LAMBDA_FUNCTION_NAME:-viajamejor-voucher-generator}"
VOUCHERS_BUCKET="${VOUCHERS_BUCKET:-}"
SQS_RESERVAS_QUEUE_ARN="${SQS_RESERVAS_QUEUE_ARN:-}"
SQS_NOTIFICACIONES_QUEUE_URL="${SQS_NOTIFICACIONES_QUEUE_URL:-}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
ROLE_ARN="${LAMBDA_ROLE_ARN:-arn:aws:iam::${ACCOUNT_ID}:role/LabRole}"

echo "== Empaquetando funcion serverless ${FUNCTION_NAME} =="
ZIP_FILE="/tmp/${FUNCTION_NAME}.zip"
rm -f "${ZIP_FILE}"
(cd "${SCRIPT_DIR}" && python3 -c "import zipfile; z=zipfile.ZipFile('${ZIP_FILE}','w',zipfile.ZIP_DEFLATED); z.write('handler.py'); z.close()")

ENV_VARS="Variables={VOUCHERS_BUCKET=${VOUCHERS_BUCKET},SQS_NOTIFICACIONES_QUEUE_URL=${SQS_NOTIFICACIONES_QUEUE_URL}}"

if aws lambda get-function --function-name "${FUNCTION_NAME}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  echo "== Actualizando codigo y configuracion de Lambda existente =="
  aws lambda update-function-code \
    --function-name "${FUNCTION_NAME}" \
    --zip-file "fileb://${ZIP_FILE}" \
    --region "${AWS_REGION}" >/dev/null

  aws lambda wait function-updated \
    --function-name "${FUNCTION_NAME}" \
    --region "${AWS_REGION}"

  aws lambda update-function-configuration \
    --function-name "${FUNCTION_NAME}" \
    --runtime python3.12 \
    --handler handler.lambda_handler \
    --timeout 30 \
    --memory-size 256 \
    --environment "${ENV_VARS}" \
    --region "${AWS_REGION}" >/dev/null
else
  echo "== Creando funcion Lambda ${FUNCTION_NAME} con rol ${ROLE_ARN} =="
  aws lambda create-function \
    --function-name "${FUNCTION_NAME}" \
    --runtime python3.12 \
    --role "${ROLE_ARN}" \
    --handler handler.lambda_handler \
    --zip-file "fileb://${ZIP_FILE}" \
    --timeout 30 \
    --memory-size 256 \
    --environment "${ENV_VARS}" \
    --region "${AWS_REGION}" >/dev/null

  aws lambda wait function-active-v2 \
    --function-name "${FUNCTION_NAME}" \
    --region "${AWS_REGION}"
fi

# Configurar Event Source Mapping SQS -> Lambda si se entrego el ARN de la cola
if [[ -n "${SQS_RESERVAS_QUEUE_ARN}" ]]; then
  EXISTING_UUID="$(aws lambda list-event-source-mappings \
    --function-name "${FUNCTION_NAME}" \
    --event-source-arn "${SQS_RESERVAS_QUEUE_ARN}" \
    --region "${AWS_REGION}" \
    --query 'EventSourceMappings[0].UUID' \
    --output text)"

  if [[ "${EXISTING_UUID}" == "None" || -z "${EXISTING_UUID}" ]]; then
    echo "== Asociando trigger SQS -> Lambda (${SQS_RESERVAS_QUEUE_ARN}) =="
    aws lambda create-event-source-mapping \
      --function-name "${FUNCTION_NAME}" \
      --event-source-arn "${SQS_RESERVAS_QUEUE_ARN}" \
      --batch-size 5 \
      --function-response-types "ReportBatchItemFailures" \
      --region "${AWS_REGION}" >/dev/null
  else
    echo "== Trigger SQS -> Lambda ya configurado (UUID=${EXISTING_UUID}) =="
  fi
fi

LAMBDA_ARN="$(aws lambda get-function --function-name "${FUNCTION_NAME}" --region "${AWS_REGION}" --query 'Configuration.FunctionArn' --output text)"
echo "OK: Funcion serverless desplegada -> ${LAMBDA_ARN}"
