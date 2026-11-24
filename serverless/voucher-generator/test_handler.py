import json
import os
import unittest
from unittest.mock import MagicMock

import handler


class VoucherGeneratorHandlerTest(unittest.TestCase):
    def setUp(self) -> None:
        os.environ.pop("VOUCHERS_BUCKET", None)
        os.environ.pop("SQS_NOTIFICACIONES_QUEUE_URL", None)

    def test_invocacion_directa_genera_voucher_con_total_y_qr(self) -> None:
        evento = {
            "reservaId": 42,
            "nombre": "Vacaciones Cancun 2026",
            "proveedor": "Amadeus GDS",
            "fecha": "2026-12-10",
            "items": [
                {"descripcion": "Vuelo SCL-CUN", "cantidad": 2, "precioUnitario": 450000},
                {"descripcion": "Hotel All Inclusive", "cantidad": 5, "precioUnitario": 180000},
            ],
        }
        res = handler.lambda_handler(evento)
        self.assertEqual(res["eventType"], "VOUCHER_GENERADO")
        self.assertEqual(res["reservaId"], 42)
        self.assertEqual(res["totalEstimado"], "1800000.00")
        self.assertTrue(res["codigoVoucher"].startswith("VM-"))
        self.assertIn("VIAJAMEJOR|VOUCHER=", res["qrPayload"])

    def test_trigger_sqs_procesa_batch_y_reporta_fallo_parcial_a_dlq(self) -> None:
        sqs_event = {
            "Records": [
                {
                    "messageId": "msg-ok-1",
                    "body": json.dumps(
                        {
                            "reservaId": 10,
                            "nombre": "Escapada Mendoza",
                            "proveedor": "LATAM",
                            "fecha": "2026-12-20",
                            "items": [{"descripcion": "Vuelo", "cantidad": 1, "precioUnitario": 120000}],
                        }
                    ),
                },
                {
                    "messageId": "msg-bad-2",
                    "body": json.dumps({"reservaId": 11, "nombre": ""}),
                },
            ]
        }
        res = handler.lambda_handler(sqs_event)
        self.assertEqual(res["processedCount"], 1)
        self.assertEqual(res["batchItemFailures"], [{"itemIdentifier": "msg-bad-2"}])

    def test_api_gateway_proxy_retorna_200_y_400(self) -> None:
        ok_event = {
            "httpMethod": "POST",
            "body": json.dumps({"reservaId": 7, "nombre": "Hotel Santiago", "proveedor": "Sabre"}),
        }
        ok_res = handler.lambda_handler(ok_event)
        self.assertEqual(ok_res["statusCode"], 200)
        body = json.loads(ok_res["body"])
        self.assertEqual(body["estado"], "EMITIDO")

        bad_event = {"httpMethod": "POST", "body": json.dumps({"nombre": ""})}
        bad_res = handler.lambda_handler(bad_event)
        self.assertEqual(bad_res["statusCode"], 400)

    def test_persistencia_s3_y_envio_sqs_notificaciones(self) -> None:
        os.environ["VOUCHERS_BUCKET"] = "viajamejor-vouchers-test"
        os.environ["SQS_NOTIFICACIONES_QUEUE_URL"] = "https://sqs.us-east-1.amazonaws.com/123456789012/notif"
        mock_s3 = MagicMock()
        mock_sqs = MagicMock()
        mock_sqs.send_message.return_value = {"MessageId": "sqs-msg-999"}

        voucher = handler.generar_voucher({"reservaId": 99, "nombre": "Vuelo Madrid"})
        res = handler._persistir_y_notificar(voucher, s3_client=mock_s3, sqs_client=mock_sqs)

        self.assertEqual(mock_s3.put_object.call_count, 2)
        mock_sqs.send_message.assert_called_once()
        self.assertEqual(res["s3Bucket"], "viajamejor-vouchers-test")
        self.assertEqual(res["notificationMessageId"], "sqs-msg-999")


if __name__ == "__main__":
    unittest.main()
