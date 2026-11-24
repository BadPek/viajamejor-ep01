#!/usr/bin/env bash
# Etapa 4 de Provision Cloud (IE5 + IE12):
# Crea o actualiza Amazon API Gateway (REST API) protegiendo los endpoints con API Key + Usage Plan:
#   - POST /voucher        -> AWS_PROXY hacia Lambda viajamejor-voucher-generator (requiere x-api-key)
#   - ANY  /reservas       -> HTTP_PROXY hacia ms-reservas en Swarm (si SWARM_MANAGER_HOST esta definido)
#   - ANY  /notificaciones -> HTTP_PROXY hacia ms-notificaciones en Swarm (si SWARM_MANAGER_HOST esta definido)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_REGION="${AWS_REGION:-us-east-1}"
API_NAME="${API_GW_NAME:-viajamejor-api-gw}"
STAGE_NAME="${API_GW_STAGE:-prod}"
FUNCTION_NAME="${LAMBDA_FUNCTION_NAME:-viajamejor-voucher-generator}"
SWARM_HOST="${SWARM_MANAGER_HOST:-}"

ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
LAMBDA_ARN="$(aws lambda get-function --function-name "${FUNCTION_NAME}" --region "${AWS_REGION}" --query 'Configuration.FunctionArn' --output text)"

echo "== [1/4] Creando/verificando REST API Gateway: ${API_NAME} =="
API_ID="$(aws apigateway get-rest-apis --region "${AWS_REGION}" --query "items[?name=='${API_NAME}'].id | [0]" --output text)"
if [[ "${API_ID}" == "None" || -z "${API_ID}" ]]; then
  API_ID="$(aws apigateway create-rest-api \
    --name "${API_NAME}" \
    --description "API Gateway protegido con API Key para ViajaMejor" \
    --endpoint-configuration types=REGIONAL \
    --region "${AWS_REGION}" \
    --query id --output text)"
  echo "REST API creada: ${API_ID}"
else
  echo "REST API existente: ${API_ID}"
fi

ROOT_ID="$(aws apigateway get-resources --rest-api-id "${API_ID}" --region "${AWS_REGION}" --query "items[?path=='/'].id | [0]" --output text)"

ensure_resource() {
  local parent_id="$1"
  local path_part="$2"
  local full_path="$3"
  local res_id
  res_id="$(aws apigateway get-resources --rest-api-id "${API_ID}" --region "${AWS_REGION}" --query "items[?path=='${full_path}'].id | [0]" --output text)"
  if [[ "${res_id}" == "None" || -z "${res_id}" ]]; then
    res_id="$(aws apigateway create-resource \
      --rest-api-id "${API_ID}" \
      --parent-id "${parent_id}" \
      --path-part "${path_part}" \
      --region "${AWS_REGION}" \
      --query id --output text)"
  fi
  echo "${res_id}"
}

echo "== [2/4] Configurando ruta protegida POST /voucher -> Lambda =="
VOUCHER_RES_ID="$(ensure_resource "${ROOT_ID}" "voucher" "/voucher")"

aws apigateway delete-method \
  --rest-api-id "${API_ID}" \
  --resource-id "${VOUCHER_RES_ID}" \
  --http-method POST \
  --region "${AWS_REGION}" >/dev/null 2>&1 || true

aws apigateway put-method \
  --rest-api-id "${API_ID}" \
  --resource-id "${VOUCHER_RES_ID}" \
  --http-method POST \
  --authorization-type NONE \
  --api-key-required \
  --region "${AWS_REGION}" >/dev/null

aws apigateway put-integration \
  --rest-api-id "${API_ID}" \
  --resource-id "${VOUCHER_RES_ID}" \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:${AWS_REGION}:lambda:path/2015-03-31/functions/${LAMBDA_ARN}/invocations" \
  --region "${AWS_REGION}" >/dev/null

aws lambda add-permission \
  --function-name "${FUNCTION_NAME}" \
  --statement-id "apigw-invoke-${API_ID}" \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:${AWS_REGION}:${ACCOUNT_ID}:${API_ID}/*/POST/voucher" \
  --region "${AWS_REGION}" >/dev/null 2>&1 || true

if [[ -n "${SWARM_HOST}" ]]; then
  echo "== [2b/4] Configurando rutas protegidas HTTP_PROXY hacia Swarm (${SWARM_HOST}) =="

  for pair in "reservas:8083" "notificaciones:8087" "usuarios:8081" "busqueda:8082" "pagos:8084"; do
    SVC="${pair%%:*}"
    PORT="${pair##*:}"
    RES_ID="$(ensure_resource "${ROOT_ID}" "${SVC}" "/${SVC}")"
    PROXY_ID="$(ensure_resource "${RES_ID}" "{proxy+}" "/${SVC}/{proxy+}")"

    for m in GET POST; do
      aws apigateway delete-method \
        --rest-api-id "${API_ID}" \
        --resource-id "${RES_ID}" \
        --http-method "${m}" \
        --region "${AWS_REGION}" >/dev/null 2>&1 || true

      aws apigateway put-method \
        --rest-api-id "${API_ID}" \
        --resource-id "${RES_ID}" \
        --http-method "${m}" \
        --authorization-type NONE \
        --api-key-required \
        --region "${AWS_REGION}" >/dev/null

      aws apigateway put-integration \
        --rest-api-id "${API_ID}" \
        --resource-id "${RES_ID}" \
        --http-method "${m}" \
        --type HTTP_PROXY \
        --integration-http-method "${m}" \
        --uri "http://${SWARM_HOST}:${PORT}/api/${SVC}" \
        --region "${AWS_REGION}" >/dev/null
    done

    aws apigateway delete-method \
      --rest-api-id "${API_ID}" \
      --resource-id "${PROXY_ID}" \
      --http-method ANY \
      --region "${AWS_REGION}" >/dev/null 2>&1 || true

    aws apigateway put-method \
      --rest-api-id "${API_ID}" \
      --resource-id "${PROXY_ID}" \
      --http-method ANY \
      --authorization-type NONE \
      --api-key-required \
      --request-parameters "method.request.path.proxy=true" \
      --region "${AWS_REGION}" >/dev/null

    aws apigateway put-integration \
      --rest-api-id "${API_ID}" \
      --resource-id "${PROXY_ID}" \
      --http-method ANY \
      --type HTTP_PROXY \
      --integration-http-method ANY \
      --uri "http://${SWARM_HOST}:${PORT}/api/${SVC}/{proxy}" \
      --request-parameters "integration.request.path.proxy=method.request.path.proxy" \
      --region "${AWS_REGION}" >/dev/null
  done
else
  echo "Aviso: SWARM_MANAGER_HOST no definido; se configuro /voucher (Lambda). Exporta SWARM_MANAGER_HOST para exponer los microservicios via API Gateway."
fi

echo "== [3/4] Desplegando stage '${STAGE_NAME}' =="
aws apigateway create-deployment \
  --rest-api-id "${API_ID}" \
  --stage-name "${STAGE_NAME}" \
  --region "${AWS_REGION}" >/dev/null

echo "== [4/4] Configurando API Key y Usage Plan (autenticacion obligatoria x-api-key) =="
KEY_NAME="viajamejor-client-key"
KEY_ID="$(aws apigateway get-api-keys --name-query "${KEY_NAME}" --region "${AWS_REGION}" --query "items[?name=='${KEY_NAME}'].id | [0]" --output text)"
if [[ "${KEY_ID}" == "None" || -z "${KEY_ID}" ]]; then
  KEY_ID="$(aws apigateway create-api-key \
    --name "${KEY_NAME}" \
    --enabled \
    --region "${AWS_REGION}" \
    --query id --output text)"
fi

PLAN_NAME="viajamejor-standard-plan"
PLAN_ID="$(aws apigateway get-usage-plans --region "${AWS_REGION}" --query "items[?name=='${PLAN_NAME}'].id | [0]" --output text)"
if [[ "${PLAN_ID}" == "None" || -z "${PLAN_ID}" ]]; then
  PLAN_ID="$(aws apigateway create-usage-plan \
    --name "${PLAN_NAME}" \
    --throttle burstLimit=100,rateLimit=50 \
    --quota limit=10000,period=MONTH \
    --api-stages "apiId=${API_ID},stage=${STAGE_NAME}" \
    --region "${AWS_REGION}" \
    --query id --output text)"
else
  aws apigateway update-usage-plan \
    --usage-plan-id "${PLAN_ID}" \
    --patch-operations "op=add,path=/apiStages,value=${API_ID}:${STAGE_NAME}" \
    --region "${AWS_REGION}" >/dev/null 2>&1 || true
fi

aws apigateway create-usage-plan-key \
  --usage-plan-id "${PLAN_ID}" \
  --key-id "${KEY_ID}" \
  --key-type API_KEY \
  --region "${AWS_REGION}" >/dev/null 2>&1 || true

API_URL="https://${API_ID}.execute-api.${AWS_REGION}.amazonaws.com/${STAGE_NAME}"
echo "export API_GATEWAY_URL=\"${API_URL}\"" >> "${SCRIPT_DIR}/outputs.env"
echo "export API_GATEWAY_KEY_ID=\"${KEY_ID}\"" >> "${SCRIPT_DIR}/outputs.env"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "API_GATEWAY_URL=${API_URL}" >> "${GITHUB_ENV}"
fi

echo "OK: API Gateway desplegado en -> ${API_URL}"
echo "  Prueba sin credencial (debe devolver 403): curl -i -X POST ${API_URL}/voucher"
echo "  Obtener API Key en CLI: aws apigateway get-api-key --api-key ${KEY_ID} --include-value --query value --output text"
