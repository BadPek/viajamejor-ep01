# Funcion Serverless — `viajamejor-voucher-generator`

## 1. Requerimiento Funcional de Negocio

En la plataforma **ViajaMejor (Caso 06)**, la emision de comprobantes y codigos QR de viaje no debe bloquear la transaccion sincrona de creacion de reserva ni penalizar la latencia bajo picos de trafico (temporadas altas y CyberDays).

Esta funcion FaaS (AWS Lambda, Python 3.12) resuelve ese requerimiento de forma **puntual y dirigida por eventos**:

```text
ms-reservas (Productor)
   │  POST /api/reservas → publica evento RESERVA_CONFIRMADA
   ▼
Amazon SQS (viajamejor-reservas-queue + DLQ)
   │  Trigger automatico (Event Source Mapping, batch size 5)
   ▼
AWS Lambda (viajamejor-voucher-generator)
   ├── 1. Genera codigo de voucher unico (VM-YYYYMMDD-ID-HASH) + QR payload SHA-256
   ├── 2. Almacena comprobante JSON y HTML en Amazon S3 (viajamejor-vouchers-*)
   └── 3. Publica evento VOUCHER_GENERADO en SQS (viajamejor-notificaciones-queue)
            ▼
       ms-notificaciones (Consumidor) → persiste notificacion en MySQL
```

---

## 2. Estructura de Archivos

| Archivo | Proposito |
|---|---|
| `handler.py` | Handler principal (`lambda_handler`) compatible con SQS (Partial Batch Response), API Gateway Proxy e invocacion directa. |
| `test_handler.py` | Pruebas unitarias (`unittest`) de generacion de voucher, batch SQS con fallo parcial a DLQ, API Gateway (200/400) y persistencia S3/SQS. |
| `event-sample.json` | Payload SQS de ejemplo para pruebas locales, CLI o consola AWS Lambda. |
| `template.yaml` | Definicion declarativa AWS SAM / CloudFormation (S3, SQS, DLQ y Lambda). |
| `deploy.sh` | Script idempotente AWS CLI integrado en el pipeline CI/CD (compatible con `LabRole` de AWS Academy). |

---

## 3. Variables de Entorno

| Variable | Descripcion |
|---|---|
| `VOUCHERS_BUCKET` | Nombre del bucket Amazon S3 donde se almacenan los archivos `vouchers/<codigo>.json` y `.html`. |
| `SQS_NOTIFICACIONES_QUEUE_URL` | URL de la cola SQS donde se publica el evento `VOUCHER_GENERADO` para `ms-notificaciones`. |
| `AWS_REGION` | Region de despliegue (por defecto `us-east-1`). |

---

## 4. Instrucciones de Prueba

### 4.1 Pruebas Unitarias Locales (sin cuenta AWS)
```bash
cd serverless/voucher-generator
python3 -m unittest discover -v
```

### 4.2 Prueba Local con Evento de Ejemplo
```bash
cd serverless/voucher-generator
python3 -c "import json, handler; print(json.dumps(handler.lambda_handler(json.load(open('event-sample.json'))), indent=2))"
```

### 4.3 Despliegue e Invocacion Real en AWS
```bash
export AWS_REGION=us-east-1
export VOUCHERS_BUCKET=viajamejor-vouchers-<ACCOUNT_ID>
bash serverless/voucher-generator/deploy.sh

aws lambda invoke \
  --function-name viajamejor-voucher-generator \
  --cli-binary-format raw-in-base64-out \
  --payload file://serverless/voucher-generator/event-sample.json \
  /tmp/voucher-output.json

cat /tmp/voucher-output.json
```
