#!/usr/bin/env bash
# Inicializa el nodo Manager del cluster Docker Swarm de ViajaMejor,
# crea el Docker Secret de base de datos y muestra el comando para unir Workers.
set -euo pipefail

ADVERTISE_ADDR="${1:-$(hostname -I | awk '{print $1}')}"

echo "== 1. Inicializando nodo Manager Docker Swarm en ${ADVERTISE_ADDR} =="
if docker info --format '{{.Swarm.LocalNodeState}}' | grep -qi "active"; then
  echo "El nodo ya pertenece a un cluster Swarm activo."
else
  docker swarm init --advertise-addr "${ADVERTISE_ADDR}"
fi

echo "== 2. Configurando Docker Secret db_root_password =="
if ! docker secret inspect db_root_password >/dev/null 2>&1; then
  if [[ -z "${DB_PASSWORD:-}" ]]; then
    echo "ERROR: Exporta DB_PASSWORD antes de ejecutar este script (ej. export DB_PASSWORD='MiClaveSegura2026!')."
    exit 1
  fi
  printf "%s" "${DB_PASSWORD}" | docker secret create db_root_password -
  echo "Secret db_root_password creado correctamente."
else
  echo "Secret db_root_password ya existe."
fi

echo "== 3. Estado actual de nodos del cluster =="
docker node ls

echo ""
echo "== 4. Ejecuta el siguiente comando en cada nodo WORKER para unirlo al cluster =="
WORKER_TOKEN="$(docker swarm join-token -q worker)"
echo "docker swarm join --token ${WORKER_TOKEN} ${ADVERTISE_ADDR}:2377"
