#!/usr/bin/env bash
# Demostracion de escalado dinamico (scale up / scale down) en Docker Swarm
# verificando continuidad de servicio y balanceo de carga (Routing Mesh) via X-Instance-Host.
set -euo pipefail

STACK_NAME="${STACK_NAME:-viajamejor}"
SERVICE_NAME="${STACK_NAME}_reservas"
TARGET_HOST="${TARGET_HOST:-localhost}"

verificar_endpoint() {
  local etiqueta="$1"
  echo "--- Verificando endpoint durante: ${etiqueta} ---"
  for i in 1 2 3 4; do
    RESP="$(curl -s -i "http://${TARGET_HOST}:8083/api/reservas")"
    CODE="$(echo "${RESP}" | head -n 1 | tr -d '\r')"
    HOST_HDR="$(echo "${RESP}" | grep -i '^X-Instance-Host:' | tr -d '\r' || true)"
    echo "  Peticion #${i}: ${CODE} | ${HOST_HDR}"
  done
}

echo "== 1. Estado inicial de ${SERVICE_NAME} =="
docker service ps "${SERVICE_NAME}" --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}"
verificar_endpoint "estado inicial"

echo ""
echo "== 2. Escalando hacia arriba: ${SERVICE_NAME}=4 =="
docker service scale "${SERVICE_NAME}=4"
docker service ps "${SERVICE_NAME}" --filter "desired-state=running" --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}"
verificar_endpoint "4 replicas activas"

echo ""
echo "== 3. Escalando hacia abajo: ${SERVICE_NAME}=2 =="
docker service scale "${SERVICE_NAME}=2"
docker service ps "${SERVICE_NAME}" --filter "desired-state=running" --format "table {{.Name}}\t{{.Node}}\t{{.CurrentState}}"
verificar_endpoint "2 replicas restauradas"
