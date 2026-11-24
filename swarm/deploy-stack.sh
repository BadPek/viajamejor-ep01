#!/usr/bin/env bash
# Despliega o actualiza el stack 'viajamejor' en Docker Swarm y verifica la distribucion multi-nodo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
STACK_NAME="${STACK_NAME:-viajamejor}"

if [[ -z "${DB_PASSWORD:-}" ]]; then
  echo "ERROR: Exporta DB_PASSWORD antes de desplegar el stack."
  exit 1
fi

export DOCKER_REGISTRY="${DOCKER_REGISTRY:-ghcr.io/badpek}"
export IMAGE_TAG="${IMAGE_TAG:-latest}"
export DB_HOST="${DB_HOST:-mysql}"
export DB_PORT="${DB_PORT:-3306}"
export DB_USER="${DB_USER:-root}"
export AWS_REGION="${AWS_REGION:-us-east-1}"

echo "== Asegurando Docker Secret db_root_password =="
if ! docker secret inspect db_root_password >/dev/null 2>&1; then
  printf "%s" "${DB_PASSWORD}" | docker secret create db_root_password -
fi

echo "== Desplegando stack '${STACK_NAME}' con imagenes ${DOCKER_REGISTRY}/*:${IMAGE_TAG} =="
docker stack deploy \
  -c "${ROOT_DIR}/docker-compose.swarm.yml" \
  "${STACK_NAME}" \
  --with-registry-auth

echo "== Esperando convergencia inicial (15s) =="
sleep 15

echo ""
echo "== Nodos del cluster (docker node ls) =="
docker node ls

echo ""
echo "== Servicios del stack (docker stack services ${STACK_NAME}) =="
docker stack services "${STACK_NAME}"

echo ""
echo "== Distribucion de replicas en nodos (docker service ps ${STACK_NAME}_reservas) =="
docker service ps "${STACK_NAME}_reservas" --format "table {{.Name}}\t{{.Node}}\t{{.DesiredState}}\t{{.CurrentState}}"
