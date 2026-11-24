#!/usr/bin/env bash
# Etapa 1 de Provision Cloud (IE5):
# Crea de forma idempotente:
#   - Bucket Amazon S3 para almacenamiento de vouchers (con versionado y bloqueo publico)
#   - Cola Dead Letter Queue (DLQ) Amazon SQS para mensajes fallidos
#   - Cola principal Amazon SQS de reservas con RedrivePolicy (maxReceiveCount=3)
#   - Cola Amazon SQS de notificaciones para consumo asincrono desde ms-notificaciones
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"

BUCKET_NAME="${VOUCHERS_BUCKET:-viajamejor-vouchers-${ACCOUNT_ID}}"
DLQ_NAME="${SQS_DLQ_NAME:-viajamejor-reservas-dlq}"
RESERVAS_QUEUE_NAME="${SQS_RESERVAS_QUEUE_NAME:-viajamejor-reservas-queue}"
NOTIF_QUEUE_NAME="${SQS_NOTIF_QUEUE_NAME:-viajamejor-notificaciones-queue}"

echo "== [1/3] Provisionando bucket Amazon S3: ${BUCKET_NAME} =="
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "Bucket S3 ${BUCKET_NAME} ya existe."
else
  if [[ "${AWS_REGION}" == "us-east-1" ]]; then
    aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${AWS_REGION}" >/dev/null
  else
    aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${AWS_REGION}" \
      --create-bucket-configuration "LocationConstraint=${AWS_REGION}" >/dev/null
  fi
  echo "Bucket S3 ${BUCKET_NAME} creado."
fi

aws s3api put-bucket-versioning \
  --bucket "${BUCKET_NAME}" \
  --versioning-configuration Status=Enabled

aws s3api put-public-access-block \
  --bucket "${BUCKET_NAME}" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

echo "== [2/3] Provisionando Amazon SQS DLQ (${DLQ_NAME}) y cola principal (${RESERVAS_QUEUE_NAME}) =="
DLQ_URL="$(aws sqs create-queue \
  --queue-name "${DLQ_NAME}" \
  --attributes MessageRetentionPeriod=1209600 \
  --region "${AWS_REGION}" \
  --query QueueUrl --output text)"

DLQ_ARN="$(aws sqs get-queue-attributes \
  --queue-url "${DLQ_URL}" \
  --attribute-names QueueArn \
  --region "${AWS_REGION}" \
  --query Attributes.QueueArn --output text)"

RESERVAS_QUEUE_URL="$(aws sqs create-queue \
  --queue-name "${RESERVAS_QUEUE_NAME}" \
  --region "${AWS_REGION}" \
  --query QueueUrl --output text)"

REDRIVE_POLICY="{\"deadLetterTargetArn\":\"${DLQ_ARN}\",\"maxReceiveCount\":\"3\"}"
ATTR_FILE="/tmp/sqs-reservas-attrs.json"
python3 -c "import json; json.dump({'VisibilityTimeout':'60','MessageRetentionPeriod':'345600','RedrivePolicy':'${REDRIVE_POLICY}'}, open('${ATTR_FILE}','w'))"

aws sqs set-queue-attributes \
  --queue-url "${RESERVAS_QUEUE_URL}" \
  --attributes "file://${ATTR_FILE}" \
  --region "${AWS_REGION}"

RESERVAS_QUEUE_ARN="$(aws sqs get-queue-attributes \
  --queue-url "${RESERVAS_QUEUE_URL}" \
  --attribute-names QueueArn \
  --region "${AWS_REGION}" \
  --query Attributes.QueueArn --output text)"

echo "== [3/3] Provisionando cola de notificaciones (${NOTIF_QUEUE_NAME}) =="
NOTIF_QUEUE_URL="$(aws sqs create-queue \
  --queue-name "${NOTIF_QUEUE_NAME}" \
  --attributes VisibilityTimeout=60,MessageRetentionPeriod=345600 \
  --region "${AWS_REGION}" \
  --query QueueUrl --output text)"

NOTIF_QUEUE_ARN="$(aws sqs get-queue-attributes \
  --queue-url "${NOTIF_QUEUE_URL}" \
  --attribute-names QueueArn \
  --region "${AWS_REGION}" \
  --query Attributes.QueueArn --output text)"

OUTPUTS_FILE="${SCRIPT_DIR}/outputs.env"
cat > "${OUTPUTS_FILE}" <<EOF
export AWS_REGION="${AWS_REGION}"
export VOUCHERS_BUCKET="${BUCKET_NAME}"
export SQS_DLQ_URL="${DLQ_URL}"
export SQS_DLQ_ARN="${DLQ_ARN}"
export SQS_RESERVAS_QUEUE_URL="${RESERVAS_QUEUE_URL}"
export SQS_RESERVAS_QUEUE_ARN="${RESERVAS_QUEUE_ARN}"
export SQS_NOTIFICACIONES_QUEUE_URL="${NOTIF_QUEUE_URL}"
export SQS_NOTIFICACIONES_QUEUE_ARN="${NOTIF_QUEUE_ARN}"
EOF

if [[ -n "${GITHUB_ENV:-}" ]]; then
  {
    echo "VOUCHERS_BUCKET=${BUCKET_NAME}"
    echo "SQS_DLQ_URL=${DLQ_URL}"
    echo "SQS_RESERVAS_QUEUE_URL=${RESERVAS_QUEUE_URL}"
    echo "SQS_RESERVAS_QUEUE_ARN=${RESERVAS_QUEUE_ARN}"
    echo "SQS_NOTIFICACIONES_QUEUE_URL=${NOTIF_QUEUE_URL}"
    echo "SQS_NOTIFICACIONES_QUEUE_ARN=${NOTIF_QUEUE_ARN}"
  } >> "${GITHUB_ENV}"
fi

echo "OK: S3 y SQS (+ DLQ) provisionados."
echo "  Bucket S3:             ${BUCKET_NAME}"
echo "  SQS Reservas:          ${RESERVAS_QUEUE_URL}"
echo "  SQS DLQ:               ${DLQ_URL}"
echo "  SQS Notificaciones:    ${NOTIF_QUEUE_URL}"
