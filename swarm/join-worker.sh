#!/usr/bin/env bash
# Une un nodo Worker al cluster Docker Swarm de ViajaMejor.
# Uso: bash swarm/join-worker.sh <SWARM_WORKER_TOKEN> <MANAGER_IP>
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Uso: $0 <SWARM_WORKER_TOKEN> <MANAGER_IP>"
  echo "Ejemplo: $0 SWMTKN-1-xxxx 10.0.1.10"
  exit 1
fi

TOKEN="$1"
MANAGER_IP="$2"

if docker info --format '{{.Swarm.LocalNodeState}}' | grep -qi "active"; then
  echo "Este nodo ya esta unido a un cluster Swarm activo."
  exit 0
fi

echo "== Uniendo nodo Worker al Manager ${MANAGER_IP}:2377 =="
docker swarm join --token "${TOKEN}" "${MANAGER_IP}:2377"
echo "OK: Nodo unido exitosamente como Worker. Verifica con 'docker node ls' en el Manager."
