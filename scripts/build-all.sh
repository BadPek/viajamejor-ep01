#!/usr/bin/env bash
# Compila y empaqueta los 7 microservicios de ViajaMejor (genera el .jar ejecutable en target/).
set -euo pipefail
SERVICES="usuarios busqueda reservas pagos integraciones fidelizacion notificaciones"
for s in $SERVICES; do
  echo "== empaquetando ms/$s =="
  (cd "ms/$s" && mvn -q clean package -DskipTests)
done
echo "OK: artefactos generados en ms/<servicio>/target/*.jar"
