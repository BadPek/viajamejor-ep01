#!/usr/bin/env bash
# Ejecuta compilacion, pruebas unitarias/MockMvc/Cucumber y cobertura JaCoCo (mvn clean verify)
# en los 7 microservicios y las pruebas de la funcion serverless.
set -euo pipefail

SERVICES="usuarios busqueda reservas pagos integraciones fidelizacion notificaciones"
for s in $SERVICES; do
  echo "== verificando ms/$s (mvn clean verify) =="
  (cd "ms/$s" && mvn -B -q clean verify)
done

echo "== verificando funcion serverless (voucher-generator) =="
python3 -m unittest discover -s serverless/voucher-generator -v

echo "OK: 7 microservicios (JaCoCo 100%) y funcion serverless verificados con exito."
