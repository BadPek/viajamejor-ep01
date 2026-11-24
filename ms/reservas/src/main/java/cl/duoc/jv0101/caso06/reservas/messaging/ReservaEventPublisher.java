package cl.duoc.jv0101.caso06.reservas.messaging;

import cl.duoc.jv0101.caso06.reservas.model.Reserva;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PreDestroy;
import java.time.OffsetDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.sqs.SqsClient;
import software.amazon.awssdk.services.sqs.model.MessageAttributeValue;
import software.amazon.awssdk.services.sqs.model.SendMessageRequest;
import software.amazon.awssdk.services.sqs.model.SendMessageResponse;

@Component
public class ReservaEventPublisher {

    private static final Logger log = LoggerFactory.getLogger(ReservaEventPublisher.class);

    private final ObjectMapper objectMapper;
    private final String queueUrl;
    private final String awsRegion;
    private volatile SqsClient sqsClient;

    public ReservaEventPublisher(
            ObjectMapper objectMapper,
            @Value("${viajamejor.aws.sqs.queue-url:}") String queueUrl,
            @Value("${viajamejor.aws.region:us-east-1}") String awsRegion) {
        this.objectMapper = objectMapper;
        this.queueUrl = queueUrl;
        this.awsRegion = awsRegion;
    }

    public void publicarReservaConfirmada(Reserva reserva) {
        if (queueUrl == null || queueUrl.isBlank()) {
            log.info("SQS_RESERVAS_QUEUE_URL no configurada; evento RESERVA_CONFIRMADA omitido en modo local (reservaId={})",
                    reserva.getId());
            return;
        }

        try {
            Map<String, Object> evento = new LinkedHashMap<>();
            evento.put("eventType", "RESERVA_CONFIRMADA");
            evento.put("source", "ms-reservas");
            evento.put("reservaId", reserva.getId());
            evento.put("nombre", reserva.getNombre());
            evento.put("proveedor", reserva.getProveedor());
            evento.put("fecha", reserva.getFecha());
            evento.put("items", reserva.getItems());
            evento.put("timestamp", OffsetDateTime.now().toString());

            String payload = objectMapper.writeValueAsString(evento);

            Map<String, MessageAttributeValue> attributes = Map.of(
                    "eventType", MessageAttributeValue.builder()
                            .dataType("String")
                            .stringValue("RESERVA_CONFIRMADA")
                            .build(),
                    "source", MessageAttributeValue.builder()
                            .dataType("String")
                            .stringValue("ms-reservas")
                            .build()
            );

            SendMessageRequest request = SendMessageRequest.builder()
                    .queueUrl(queueUrl)
                    .messageBody(payload)
                    .messageAttributes(attributes)
                    .build();

            SendMessageResponse response = getClient().sendMessage(request);
            log.info("Evento RESERVA_CONFIRMADA publicado en SQS. reservaId={}, messageId={}",
                    reserva.getId(), response.messageId());
        } catch (Exception ex) {
            log.error("Error publicando evento RESERVA_CONFIRMADA en SQS para reservaId={}: {}",
                    reserva.getId(), ex.getMessage());
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
