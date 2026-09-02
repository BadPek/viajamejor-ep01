# Zoom a un solo servicio: ms-reservas

Esta carpeta muestra la técnica de **zoom progresivo del modelo C4** aplicada a un único microservicio núcleo del caso ViajaMejor: **`ms-reservas`**. Permite evidenciar cómo se parte del contexto general (Nivel 1) y se desciende hasta sus componentes internos, su comportamiento secuencial en el tiempo y su infraestructura cloud dedicada.

## Índice de diagramas de zoom

| Diagrama | Nivel | Qué responde | Indicadores de evaluación |
|---|---|---|---|
| [`S1-Contexto`](S1-Contexto.png) | C4-1 (Contexto) | ¿Quién interactúa con `ms-reservas` y con qué servicios vecinos se comunica? Muestra el servicio como caja central y sus dependencias (búsqueda, pagos, integraciones, Redis, SQS, EventBridge) como sistemas vecinos. | IE1, IE2 |
| [`S2-Contenedor`](S2-Contenedor.png) | C4-2 (Contenedor) | ¿Qué contenedores integran el servicio (API REST Spring Boot, BD relacional propia en Aurora) y cómo se conecta con el ecosistema? | IE4, IE6, IE9 |
| [`S3-Componentes`](S3-Componentes.png) | C4-3 (Componentes) | ¿Cómo se estructura internamente el código Java? Dónde residen el Circuit Breaker de llamadas externas, el servicio de bloqueo atómico de cupos en Redis, los clientes REST y el publicador de eventos SQS. | IE9, IE10, IE11 |
| [`S4-Secuencia`](S4-Secuencia.png) | Secuencia UML | ¿Cómo interactúan los componentes paso a paso en el tiempo durante una confirmación de reserva? Muestra la saga de compra con bloqueo temporal, cobro, persistencia transaccional y publicación de eventos. | IE6, IE8 |
| [`S5-Infra-AWS`](S5-Infra-AWS.png) | Infraestructura dedicada | ¿Cómo se despliega `ms-reservas` en AWS? Auto scaling en ECS Fargate (2 a 10 tareas), base de datos Aurora PostgreSQL dedicada, Security Groups por capa, pipeline CI/CD Blue/Green y monitoreo con CloudWatch y X-Ray. | IE5, IE7, IE8, RNF-01 |

## Aspectos Clave Destacados en este Zoom

1. **Invariante de Negocio (RNF-06 / Integridad)**:
   - Nunca se sobrevendrá un cupo de vuelo u hotel durante el proceso de pago. Esto se garantiza mediante un bloqueo atómico temporal en **Amazon ElastiCache Redis** utilizando la instrucción `SETNX` con un tiempo de expiración (TTL) de 15 minutos.
2. **Resiliencia ante Proveedores Externos Lentos (RNF-02 / RNF-03)**:
   - La comunicación con `ms-integraciones` y `ms-pagos` está protegida mediante el patrón **Circuit Breaker (Resilience4j)**, evitando que demoras o caídas en aerolíneas o pasarelas degraden el núcleo de reservas.
3. **Desacople Asíncrono de Emisión (IE10 / Bajo Acoplamiento)**:
   - Una vez confirmado el pago, `ms-reservas` no hace esperar al viajero para la emisión del ticket o voucher; encola un mensaje persistente en **Amazon SQS (+ DLQ)** y publica eventos de dominio en **Amazon EventBridge**.

## Cómo regenerar las imágenes PNG

```bash
# Requiere Java y PlantUML:
plantuml -tpng *.puml
```
