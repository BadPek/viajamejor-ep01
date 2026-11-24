"""
ViajaMejor - Funcion Serverless (AWS Lambda): Generador de Vouchers con QR.

Requerimiento funcional (Caso 06 - ViajaMejor):
Al confirmarse una reserva en ms-reservas, se publica un evento asincrono
RESERVA_CONFIRMADA en Amazon SQS. Esta funcion procesa el evento de forma
desacoplada, genera el voucher oficial con codigo verificable y payload QR,
lo almacena en Amazon S3 y publica el evento VOUCHER_GENERADO en la cola de
notificaciones para que ms-notificaciones registre el despacho al viajero.

Soporta:
  1. Trigger automatico de Amazon SQS (Partial Batch Response con soporte DLQ).
  2. Invocacion HTTP via Amazon API Gateway (AWS_PROXY).
  3. Invocacion directa (consola AWS Lambda / AWS CLI).
"""

from __future__ import annotations

import hashlib
import json
import logging
import os
from datetime import datetime, timezone
from decimal import Decimal, InvalidOperation
from typing import Any

try:
    import boto3
except ImportError:  # Permite ejecutar pruebas locales sin boto3 instalado
    boto3 = None

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def _calcular_total(items: list[dict[str, Any]]) -> str:
    total = Decimal("0.00")
    for item in items:
        try:
            cantidad = Decimal(str(item.get("cantidad", 1)))
            precio = Decimal(str(item.get("precioUnitario", 0)))
            total += cantidad * precio
        except (InvalidOperation, TypeError, ValueError):
            continue
    return f"{total:.2f}"


def generar_voucher(evento: dict[str, Any]) -> dict[str, Any]:
    """Construye el documento de voucher y su codigo verificable a partir de una reserva."""
    reserva_id = evento.get("reservaId") or evento.get("id")
    nombre = str(evento.get("nombre", "")).strip()
    if not nombre:
        raise ValueError("El evento de reserva debe incluir el campo obligatorio 'nombre'")

    proveedor = str(evento.get("proveedor") or "ViajaMejor GDS").strip()
    fecha_viaje = str(evento.get("fecha") or datetime.now(timezone.utc).strftime("%Y-%m-%d")).strip()
    destinatario = str(evento.get("destinatario") or "viajero@viajamejor.cl").strip()
    items = evento.get("items") if isinstance(evento.get("items"), list) else []

    generado_en = datetime.now(timezone.utc).isoformat()
    semilla = f"{reserva_id}|{nombre}|{proveedor}|{fecha_viaje}|{len(items)}"
    qr_hash = hashlib.sha256(semilla.encode("utf-8")).hexdigest()
    fecha_tag = datetime.now(timezone.utc).strftime("%Y%m%d")
    id_tag = str(reserva_id) if reserva_id is not None else "0"
    codigo_voucher = f"VM-{fecha_tag}-{id_tag}-{qr_hash[:6].upper()}"

    total_calculado = _calcular_total(items)
    qr_payload = f"VIAJAMEJOR|VOUCHER={codigo_voucher}|RESERVA={id_tag}|HASH={qr_hash[:16]}"

    voucher = {
        "eventType": "VOUCHER_GENERADO",
        "codigoVoucher": codigo_voucher,
        "reservaId": reserva_id,
        "nombre": nombre,
        "proveedor": proveedor,
        "fechaViaje": fecha_viaje,
        "destinatario": destinatario,
        "cantidadItems": len(items),
        "totalEstimado": total_calculado,
        "items": items,
        "qrPayload": qr_payload,
        "qrHashSha256": qr_hash,
        "estado": "EMITIDO",
        "generadoEn": generado_en,
    }
    return voucher


def _render_voucher_html(voucher: dict[str, Any]) -> str:
    filas = "".join(
        f"<tr><td>{i.get('descripcion', '-')}</td><td>{i.get('cantidad', 1)}</td>"
        f"<td>{i.get('precioUnitario', 0)}</td></tr>"
        for i in voucher.get("items", [])
    ) or "<tr><td colspan='3'>Reserva general sin detalle de items</td></tr>"

    return f"""<!DOCTYPE html>
<html lang="es">
<head><meta charset="utf-8"><title>Voucher {voucher['codigoVoucher']}</title></head>
<body style="font-family: Arial, sans-serif; max-width: 680px; margin: 24px auto; border: 1px solid #d0d7de; padding: 24px;">
  <h1 style="color: #0b5394;">ViajaMejor — Comprobante Oficial de Reserva</h1>
  <p><strong>Codigo de Voucher:</strong> {voucher['codigoVoucher']}</p>
  <p><strong>Reserva:</strong> #{voucher['reservaId']} — {voucher['nombre']}</p>
  <p><strong>Proveedor:</strong> {voucher['proveedor']} | <strong>Fecha:</strong> {voucher['fechaViaje']}</p>
  <p><strong>Total Estimado:</strong> ${voucher['totalEstimado']}</p>
  <table border="1" cellpadding="6" cellspacing="0" width="100%">
    <thead><tr><th>Descripcion</th><th>Cantidad</th><th>Precio Unitario</th></tr></thead>
    <tbody>{filas}</tbody>
  </table>
  <hr/>
  <p style="font-family: monospace; background: #f6f8fa; padding: 12px;">
    <strong>QR Payload:</strong> {voucher['qrPayload']}
  </p>
  <small>Generado automaticamente por AWS Lambda (viajamejor-voucher-generator) — {voucher['generadoEn']}</small>
</body>
</html>"""


def _persistir_y_notificar(
    voucher: dict[str, Any],
    s3_client: Any = None,
    sqs_client: Any = None,
) -> dict[str, Any]:
    bucket = os.environ.get("VOUCHERS_BUCKET", "").strip()
    notif_queue_url = os.environ.get("SQS_NOTIFICACIONES_QUEUE_URL", "").strip()
    region = os.environ.get("AWS_REGION", "us-east-1")

    s3_key = f"vouchers/{voucher['codigoVoucher']}.json"
    html_key = f"vouchers/{voucher['codigoVoucher']}.html"

    if bucket and (s3_client is not None or boto3 is not None):
        s3 = s3_client or boto3.client("s3", region_name=region)
        s3.put_object(
            Bucket=bucket,
            Key=s3_key,
            Body=json.dumps(voucher, ensure_ascii=False, indent=2).encode("utf-8"),
            ContentType="application/json",
        )
        s3.put_object(
            Bucket=bucket,
            Key=html_key,
            Body=_render_voucher_html(voucher).encode("utf-8"),
            ContentType="text/html; charset=utf-8",
        )
        voucher["s3Bucket"] = bucket
        voucher["s3Key"] = s3_key
        voucher["s3HtmlKey"] = html_key
        logger.info("Voucher almacenado en S3: s3://%s/%s", bucket, s3_key)
    else:
        voucher["s3Key"] = "local-dry-run"
        logger.info("VOUCHERS_BUCKET no configurado; ejecucion sin escritura S3")

    if notif_queue_url and (sqs_client is not None or boto3 is not None):
        sqs = sqs_client or boto3.client("sqs", region_name=region)
        resp = sqs.send_message(
            QueueUrl=notif_queue_url,
            MessageBody=json.dumps(voucher, ensure_ascii=False),
            MessageAttributes={
                "eventType": {"DataType": "String", "StringValue": "VOUCHER_GENERADO"},
                "source": {"DataType": "String", "StringValue": "lambda-voucher-generator"},
            },
        )
        voucher["notificationMessageId"] = resp.get("MessageId")
        logger.info("Evento VOUCHER_GENERADO enviado a SQS notificaciones: %s", resp.get("MessageId"))

    return voucher


def lambda_handler(event: dict[str, Any], context: Any = None) -> dict[str, Any]:
    """Entrypoint principal de AWS Lambda."""
    logger.info("Evento recibido: %s", json.dumps(event, default=str))

    # 1. Trigger de Amazon SQS (soporta batch y reporte parcial para DLQ)
    if isinstance(event, dict) and "Records" in event:
        procesados = []
        fallos = []
        for record in event["Records"]:
            msg_id = record.get("messageId", "unknown")
            try:
                body = record.get("body", "{}")
                payload = json.loads(body) if isinstance(body, str) else body
                voucher = generar_voucher(payload)
                resultado = _persistir_y_notificar(voucher)
                procesados.append(resultado)
            except Exception as exc:
                logger.exception("Error procesando mensaje SQS %s: %s", msg_id, exc)
                fallos.append({"itemIdentifier": msg_id})

        return {
            "batchItemFailures": fallos,
            "processedCount": len(procesados),
            "vouchers": procesados,
        }

    # 2. Invocacion HTTP via Amazon API Gateway (AWS_PROXY)
    if isinstance(event, dict) and ("httpMethod" in event or "requestContext" in event):
        try:
            raw_body = event.get("body") or "{}"
            payload = json.loads(raw_body) if isinstance(raw_body, str) else raw_body
            voucher = generar_voucher(payload)
            resultado = _persistir_y_notificar(voucher)
            return {
                "statusCode": 200,
                "headers": {
                    "Content-Type": "application/json",
                    "X-Function-Name": "viajamejor-voucher-generator",
                },
                "body": json.dumps(resultado, ensure_ascii=False),
            }
        except ValueError as exc:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "Bad Request", "message": str(exc)}, ensure_ascii=False),
            }

    # 3. Invocacion directa (consola AWS Lambda / CLI)
    voucher = generar_voucher(event if isinstance(event, dict) else {})
    return _persistir_y_notificar(voucher)
