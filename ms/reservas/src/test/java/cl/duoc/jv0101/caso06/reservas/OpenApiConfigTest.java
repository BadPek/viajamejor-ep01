package cl.duoc.jv0101.caso06.reservas;

import org.junit.jupiter.api.Test;
import cl.duoc.jv0101.caso06.reservas.config.OpenApiConfig;

import static org.assertj.core.api.Assertions.assertThat;

class OpenApiConfigTest {

    @Test
    void beanOpenApiGenerado() {
        assertThat(new OpenApiConfig().customOpenAPI()).isNotNull();
    }
}
