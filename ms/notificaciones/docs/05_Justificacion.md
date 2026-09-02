# ms-notificaciones — Justificación del servicio y cobertura de requisitos

**Caso caso06 — ViajaMejor** (Reservas de viajes) · EP01 JVY0101

Este documento justifica la existencia de **ms-notificaciones** como microservicio independiente: qué requisitos del negocio cubre (funcionales, no funcionales y de seguridad), por qué está delimitado así (SRP), y qué tecnología AWS se usa para cada responsabilidad y **por qué**. Los diagramas que respaldan esta justificación están en `docs/diagramas/`.

---

## 1. Misión del servicio

ms-notificaciones hace llegar la información a las personas: consume los eventos de dominio publicados por los demás servicios y los entrega por correo electrónico y notificaciones push, sin acoplarse a ningún productor del caso caso06 (ViajaMejor).

> Es un servicio stateless consumidor puro de eventos: no posee base de datos de negocio propia (solo el registro de envíos); añadir un nuevo canal (SMS, WhatsApp) no toca ningún otro servicio, y su falla jamás bloquea la operación principal del negocio.

---

## 2. Requisitos funcionales que cubre

| RF | Requisito (de `00_PresentacionEmpresa.md`) | Qué hace ms-notificaciones al respecto | Evidencia |
|----|------------------------------------------|-------------------------------|-----------|
| **RF-08** | Notificar confirmaciones, cambios y recordatorios de viaje | Consume los eventos de dominio y entrega la notificación por correo/push al destinatario correspondiente | diagrama de secuencia (notificación por evento) |

**Por qué estos RF justifican un servicio aparte:** Es un servicio stateless consumidor puro de eventos: no posee base de datos de negocio propia (solo el registro de envíos); añadir un nuevo canal (SMS, WhatsApp) no toca ningún otro servicio, y su falla jamás bloquea la operación principal del negocio.

---

## 3. Requisitos no funcionales que cubre

| RNF | Criterio | Cómo lo cumple ms-notificaciones | Decisión técnica |
|-----|----------|--------------------------|------------------|
| **RNF-05** (Rendimiento) | Resultados de búsqueda de disponibilidad en menos de 3 segundos | Respuestas dentro del umbral exigido por el caso (ver alarmas p95) | Caché/bajo acoplamiento + CloudWatch con alarma de latencia |
| **RNF-02** (Disponibilidad) | La búsqueda y disponibilidad deben operar aunque el servicio de pagos o un proveedor externo falle | Aislamiento por eventos: este servicio sigue operando aunque fallen los vecinos | Comunicación asíncrona (SQS/EventBridge) + multi-AZ |
| **RNF-01** (Escalabilidad) | Soportar picos de búsqueda en temporada alta escalando el buscador de forma independiente | Auto scaling independiente de este servicio (2→8 tareas Fargate según carga) | ECS Fargate + alarmas de CloudWatch: solo este componente escala en el pico |

**Justificación SRP (IE9):** ms-notificaciones tiene **una sola razón de cambio**: los canales de salida (correo, push) y las plantillas de los mensajes. Si mañana cambia esa regla, **ningún otro servicio se modifica**.

---

## 4. Requisitos de seguridad que cubre (mapeo STRIDE)

| Amenaza | Escenario en este servicio | Contramedida |
|---------|-----------------------------|--------------|
| **S**poofing | Enviar notificaciones suplantando al sistema | Solo se notifica a partir de eventos firmados del bus (EventBridge/SQS); sin endpoints públicos de envío |
| **T**ampering | Alterar el contenido del mensaje | Plantillas versionadas en el servicio; el evento viaja firmado dentro de la VPC (VPC endpoints) |
| **R**epudiation | Negar que se envió una notificación | Registro de cada envío (destinatario, plantilla, resultado) persistido y auditable |
| **I**nformation disclosure | Filtrar datos personales en el mensaje | Mínima data en el mensaje (sin montos ni datos sensibles); plantillas que no exponen campos privados |
| **D**enial of service | Saturar el canal de correo/push | Cola SQS entre el evento y el envío + rate limit del proveedor + DLQ para reintentos |
| **E**levation of privilege | Usar el servicio para enviar spam masivo | Solo eventos de dominio legítimos disparan envíos; sin endpoint manual sin rol administrador |

---

## 5. Stack tecnológico y por qué cada tecnología

### 5.1 Stack de la aplicación

| Tecnología | Para qué se usa en ms-notificaciones |
|------------|------------------------------|
| **Java 21 + Spring Boot 3.3** | Framework estándar de la asignatura: implementa la API REST, la lógica de negocio y el acceso a datos del servicio |
| **Spring Data JPA** | Persistencia de las entidades del dominio en la base de datos propia (repositorios por entidad) |
| **Bean Validation** | Validación de los payloads de entrada antes de procesar (jakarta.validation) |
| **springdoc-openapi** | Documentación viva del contrato REST (Swagger UI / ReDoc) para consumidores y equipo |
| **Docker + Docker Compose** | Empaquetado reproducible; la misma imagen corre en local y en ECS Fargate |
| **JUnit 5 + Mockito + MockMvc** | Pruebas unitarias y de contrato HTTP (cobertura 100 % LINE con JaCoCo) |
| **Cucumber (BDD)** | Escenarios en español alineados a los endpoints, ejecutados contra el servidor real |

### 5.2 Stack AWS y justificación de cada servicio

| Servicio AWS | Rol en ms-notificaciones | Por qué se eligió |
|--------------|----------------|--------------------|
| **Amazon SQS (+ DLQ)** | Buffer entre el evento de dominio y el envío | Si el proveedor falla, el mensaje reintenta y no se pierde (RNF de rendimiento/disponibilidad) |
| **Amazon SNS** | Fan-out del mensaje hacia los canales | Un evento, N canales (correo, push) sin código de despacho |
| **Amazon EventBridge** | Fuente de los eventos de dominio | Consumidor puro: ningún productor está acoplado a él |
| **ECS Fargate** | Runtime con auto scaling 2→8 tareas | Escalado independiente en los picos de notificación |
| **Amazon SES / FCM** | Entrega física de correo y push | Servicios managed de entrega con reputación y rate limits gestionados |
| **CloudWatch** | Métricas de envío y DLQ | Visibilidad de entregas fallidas (IE8) |

### 5.3 Patrones aplicados (IE5)

| Patrón | Dónde |
|--------|-------|
| **Event-Driven Architecture** | Consumidor puro de eventos del bus: ningún productor lo conoce |
| **Cola de mensajes (SQS + DLQ)** | Buffer entre el evento y el envío, con reintentos |
| **Publish/Subscribe** | SNS hace fan-out del mensaje hacia correo y push |

---

## 6. Delimitación: qué NO hace ms-notificaciones (IE9/IE10)

| No hace | Lo hace | Por qué |
|---------|---------|---------|
| usuarios | ms-usuarios | razones de cambio distintas: la autenticación se centraliza aquí, pero el negocio de cada dominio queda en su servicio |
| búsqueda | ms-busqueda | razones de cambio distintas: el catálogo consulta y publica; las operaciones de negocio las orquesta el servicio transaccional |
| reservas | ms-reservas | razones de cambio distintas: la operación se orquesta aquí, pero cada colaborador es autónomo |
| pagos | ms-pagos | razones de cambio distintas: el dinero se procesa aquí, pero la operación que lo origina vive en el servicio central |
| integraciones | ms-integraciones | razones de cambio distintas: el seguimiento vive aquí, pero la operación que lo origina vive en el servicio central |

---

## 7. Diagramas que respaldan esta justificación

```
docs/diagramas/
 c4/
    C4-1-Contexto     el servicio, sus actores y sus vecinos
    C4-2-Contenedor   la API, la BD propia y los componentes del dominio
    C4-3-Componentes  validador/service, clientes, publicador, repos
 secuencia/
    Secuencia-Notificacion   notificación por evento
 infraestructura/
     Infra-AWS         despliegue solo de este servicio, con iconos oficiales AWS
```

