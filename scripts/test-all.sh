#!/usr/bin/env bash
# Ejecuta pruebas y valida cobertura JaCoCo en los 7 microservicios.
set -euo pipefail
SERVICES="usuarios busqueda reservas pagos integraciones fidelizacion notificaciones"
for s in $SERVICES; do
  echo "== probando ms/$s =="
  (cd "ms/$s" && mvn -q test)
done
echo "OK: pruebas unitarias, MockMvc, Cucumber y JaCoCo completadas con exito."
