package cl.duoc.jv0101.caso06.notificaciones.messaging;

import cl.duoc.jv0101.caso06.notificaciones.model.EnvioNotificacion;
import cl.duoc.jv0101.caso06.notificaciones.model.Notificacion;
import cl.duoc.jv0101.caso06.notificaciones.service.NotificacionService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PreDestroy;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.DeleteMessageRequest;
import software.amazon.awssdk.services.sqs.model.Message;
import software.amazon.awssdk.services.sqs.model.ReceiveMessageRequest;

@Component
@ConditionalOnProperty(name = "viajamejor.aws.sqs.polling-enabled", havingValue = "true")
public class NotificacionQueueConsumer {

    private static final Logger log = LoggerFactory.getLogger(NotificacionQueueConsumer.class);

    private final NotificacionService notificacionService;
    private final ObjectMapper objectMapper;
    private final String queueUrl;
    private final String awsRegion;
    private volatile SqsClient sqsClient;

    public NotificacionQueueConsumer(
            NotificacionService notificacionService,
            ObjectMapper objectMapper,
            @Value("${viajamejor.aws.sqs.queue-url:}") String queueUrl,
            @Value("${viajamejor.aws.region:us-east-1}") String awsRegion) {
        this.notificacionService = notificacionService;
        this.objectMapper = objectMapper;
        this.queueUrl = queueUrl;
        this.awsRegion = awsRegion;
    }

    @Scheduled(fixedDelayString = "${viajamejor.aws.sqs.poll-interval-ms:10000}")
    public void consumirMensajes() {
        if (queueUrl == null || queueUrl.isBlank()) {
            return;
        }

        try {
            ReceiveMessageRequest request = ReceiveMessageRequest.builder()
                    .queueUrl(queueUrl)
                    .maxNumberOfMessages(5)
                    .waitTimeSeconds(5)
                    .build();

            List<Message> messages = getClient().receiveMessage(request).messages();
            for (Message message : messages) {
                procesarMensaje(message);
            }
        } catch (Exception ex) {
            log.error("Error consumiendo mensajes desde SQS: {}", ex.getMessage());
        }
    }

    private void procesarMensaje(Message message) {
        try {
            JsonNode root = objectMapper.readTree(message.body());
            String codigoVoucher = root.path("codigoVoucher").asText("SIN-VOUCHER");
            String nombreReserva = root.path("nombre").asText("Reserva ViajaMejor");
            String destinatario = root.path("destinatario").asText("viajero@viajamejor.cl");
            String s3Key = root.path("s3Key").asText("local");

            Notificacion notificacion = new Notificacion();
            notificacion.setNombre("Voucher " + codigoVoucher + " - " + nombreReserva);
            notificacion.setTipo("VOUCHER_CONFIRMADO");
            notificacion.setCanal("EMAIL_SQS_ASYNC");

            EnvioNotificacion envio = new EnvioNotificacion();
            envio.setDestinatario(destinatario);
            envio.setEstado("ENVIADO (" + s3Key + ")");
            envio.setProveedor("AWS_SQS_LAMBDA");
            notificacion.addEnvioNotificacion(envio);

            notificacionService.create(notificacion);

            getClient().deleteMessage(DeleteMessageRequest.builder()
                    .queueUrl(queueUrl)
                    .receiptHandle(message.receiptHandle())
                    .build());

            log.info("Mensaje SQS procesado y notificacion persistida. messageId={}, voucher={}",
                    message.messageId(), codigoVoucher);
        } catch (Exception ex) {
            log.error("Error procesando mensaje SQS messageId={}: {}", message.messageId(), ex.getMessage());
        }
    }

    private SqsClient getClient() {
        if (sqsClient == null) {
            synchronized (this) {
                if (sqsClient == null) {
                    sqsClient = SqsClient.builder()
                            .region(Region.of(awsRegion))
                            .build();
                }
            }
        }
        return sqsClient;
    }

    @PreDestroy
    public void close() {
        if (sqsClient != null) {
            sqsClient.close();
        }
    }
}
