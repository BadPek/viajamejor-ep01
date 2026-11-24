#!/usr/bin/env bash
# Etapa 2 de Provision Cloud (IE5):
# Provisiona de forma idempotente la base de datos relacional Amazon RDS MySQL 8.0
# y su Security Group dedicado para ViajaMejor.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_REGION="${AWS_REGION:-us-east-1}"
DB_INSTANCE_ID="${RDS_INSTANCE_ID:-viajamejor-mysql-db}"
DB_USER="${DB_USER:-admin}"
DB_CLASS="${RDS_INSTANCE_CLASS:-db.t3.micro}"
SG_NAME="${RDS_SG_NAME:-viajamejor-rds-sg}"
SKIP_RDS="${SKIP_RDS_PROVISION:-false}"

if [[ "${SKIP_RDS}" == "true" ]]; then
  echo "SKIP_RDS_PROVISION=true: omitiendo creacion de instancia RDS."
  exit 0
fi

if [[ -z "${DB_PASSWORD:-}" ]]; then
  echo "ERROR: DB_PASSWORD debe ser inyectada via variable de entorno o GitHub Secret."
  exit 1
fi

echo "== [1/2] Asegurando Security Group para RDS (${SG_NAME}) =="
VPC_ID="$(aws ec2 describe-vpcs --filters Name=is-default,Values=true --region "${AWS_REGION}" --query 'Vpcs[0].VpcId' --output text)"
SG_ID="$(aws ec2 describe-security-groups --filters "Name=group-name,Values=${SG_NAME}" "Name=vpc-id,Values=${VPC_ID}" --region "${AWS_REGION}" --query 'SecurityGroups[0].GroupId' --output text)"

if [[ "${SG_ID}" == "None" || -z "${SG_ID}" ]]; then
  SG_ID="$(aws ec2 create-security-group \
    --group-name "${SG_NAME}" \
    --description "Security Group MySQL RDS ViajaMejor" \
    --vpc-id "${VPC_ID}" \
    --region "${AWS_REGION}" \
    --query GroupId --output text)"
  aws ec2 authorize-security-group-ingress \
    --group-id "${SG_ID}" \
    --protocol tcp \
    --port 3306 \
    --cidr "${RDS_ALLOWED_CIDR:-0.0.0.0/0}" \
    --region "${AWS_REGION}" >/dev/null
  echo "Security Group ${SG_NAME} creado (${SG_ID})."
else
  echo "Security Group ${SG_NAME} ya existe (${SG_ID})."
fi

echo "== [2/2] Provisionando Amazon RDS MySQL 8.0 (${DB_INSTANCE_ID}) =="
if aws rds describe-db-instances --db-instance-identifier "${DB_INSTANCE_ID}" --region "${AWS_REGION}" >/dev/null 2>&1; then
  STATUS="$(aws rds describe-db-instances --db-instance-identifier "${DB_INSTANCE_ID}" --region "${AWS_REGION}" --query 'DBInstances[0].DBInstanceStatus' --output text)"
  echo "Instancia RDS ${DB_INSTANCE_ID} ya existe (estado: ${STATUS})."
else
  aws rds create-db-instance \
    --db-instance-identifier "${DB_INSTANCE_ID}" \
    --db-instance-class "${DB_CLASS}" \
    --engine mysql \
    --master-username "${DB_USER}" \
    --master-user-password "${DB_PASSWORD}" \
    --allocated-storage 20 \
    --storage-type gp2 \
    --db-name reservasdb \
    --vpc-security-group-ids "${SG_ID}" \
    --publicly-accessible \
    --backup-retention-period 0 \
    --no-multi-az \
    --region "${AWS_REGION}" >/dev/null
  echo "Creacion de RDS ${DB_INSTANCE_ID} iniciada. Esperando disponibilidad..."
fi

if [[ "${WAIT_FOR_RDS:-true}" == "true" ]]; then
  aws rds wait db-instance-available \
    --db-instance-identifier "${DB_INSTANCE_ID}" \
    --region "${AWS_REGION}"
fi

RDS_ENDPOINT="$(aws rds describe-db-instances \
  --db-instance-identifier "${DB_INSTANCE_ID}" \
  --region "${AWS_REGION}" \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)"

echo "export RDS_ENDPOINT=\"${RDS_ENDPOINT}\"" >> "${SCRIPT_DIR}/outputs.env"
if [[ -n "${GITHUB_ENV:-}" && "${RDS_ENDPOINT}" != "None" ]]; then
  echo "RDS_ENDPOINT=${RDS_ENDPOINT}" >> "${GITHUB_ENV}"
fi

echo "OK: Amazon RDS MySQL disponible en -> ${RDS_ENDPOINT}:3306"
