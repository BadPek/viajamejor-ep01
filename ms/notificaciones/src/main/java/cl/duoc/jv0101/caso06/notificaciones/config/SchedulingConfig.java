package cl.duoc.jv0101.caso06.notificaciones.config;

import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;

@Configuration
@EnableScheduling
@ConditionalOnProperty(name = "viajamejor.aws.sqs.polling-enabled", havingValue = "true")
public class SchedulingConfig {
}
