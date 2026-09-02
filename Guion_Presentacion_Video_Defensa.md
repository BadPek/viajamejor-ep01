# Guión de Presentación en Video y Guía de Defensa Oral — ViajaMejor

**EP01 · JVY0101 — Java: Diseño y Construcción de Soluciones Nativas en Nube**  
**Integrantes:** Andrés y Catalina  
**Caso Asignado:** Caso 06 — ViajaMejor  
**Duración Total Estimada del Video:** 6 minutos (rango permitido: 3 a 8 minutos)

---

## 1. Estructura General y Asignación de Roles

| Sección | Tiempo | Expositor | Diagrama en Pantalla | Indicadores de la Rúbrica |
|---|---|---|---|---|
| **1. Introducción y Caso de Negocio** | 0:00 – 1:15 | **Andrés** | Diapositiva Título + `C4-1-Contexto.png` | **IE1, IE2** |
| **2. Descomposición y Microservicios vs Monolito** | 1:15 – 2:45 | **Catalina** | `C4-2-Contenedores.png` | **IE3, IE9, IE10** |
| **3. Flujo Crítico de Datos y Patrones Cloud** | 2:45 – 4:15 | **Andrés** | `C4-4-Dinamico.png` + `S4-Secuencia.png` | **IE5, IE6, IE8** |
| **4. Infraestructura AWS, Seguridad y Monitoreo** | 4:15 – 5:30 | **Catalina** | `Infra-AWS.png` + `Infra-Red.png` | **IE7, IE8, IE11** |
| **5. Calidad del Código, Pruebas y Cierre** | 5:30 – 6:30 | **Andrés y Catalina** | VS Code / `Infra-CICD.png` | **IE12, IE13** |

---

## 2. Guión Paso a Paso para la Grabación del Video

### Parte 1: Introducción y Contexto del Negocio (0:00 – 1:15) — **Expone: Andrés**
* **Visual en pantalla:** Mostrar carátula del proyecto y luego el diagrama `entrega/c4/C4-1-Contexto.png`.
* **Guión Andrés:**
  > "Buenas tardes profesor y compañeros. Junto a Catalina presentamos nuestra propuesta arquitectónica cloud native para la plataforma **ViajaMejor**, correspondiente al Caso 06.
  >
  > ViajaMejor es una agencia de viajes en línea (OTA) que integra vuelos, hoteles, arriendo de autos y paquetes turísticos.
  >
  > Como vemos en el **Diagrama de Contexto C4 Nivel 1**, el sistema interactúa con tres actores principales: el **Viajero**, los **Operadores Turísticos** locales y los **Administradores**. A su vez, se conecta con sistemas externos críticos: los proveedores globales **GDS como Amadeus o Sabre**, la **Pasarela de Pagos** para cobros seguros y servicios de mensajería para confirmaciones.
  >
  > Para este negocio identificamos 8 requisitos funcionales y 6 no funcionales clave:
  > - En **Escalabilidad (RNF-01)**, debemos absorber picos de hasta 40.000 búsquedas por minuto en temporadas de CyberTravel sin colapsar el núcleo transaccional.
  > - En **Disponibilidad (RNF-02)**, exigimos un 99.95% de uptime; la búsqueda y consulta de reservas no pueden caer aunque una aerolínea externa o la pasarela presente demoras.
  > - Y en **Consistencia (RNF-06)**, tenemos un invariante estricto: es inadmisible la sobreventa de asientos o habitaciones."

---

### Parte 2: Descomposición en Microservicios y Justificación Arquitectónica (1:15 – 2:45) — **Expone: Catalina**
* **Visual en pantalla:** Mostrar el diagrama `entrega/c4/C4-2-Contenedores.png`.
* **Guión Catalina:**
  > "Gracias Andrés. En el **Diagrama de Contenedores C4 Nivel 2** apreciamos la descomposición lógica del sistema basada en *Domain-Driven Design* y el Principio de Responsabilidad Única (SRP).
  >
  > Delimitamos **7 microservicios independientes** construidos en Java 21 con Spring Boot 3.3 sobre contenedores ECS Fargate:
  > 1. `ms-usuarios`: Gestión de perfiles y privacidad de datos.
  > 2. `ms-busqueda`: Agregación y consulta de catálogo optimizada para alta lectura.
  > 3. `ms-reservas`: El núcleo transaccional que gestiona el ciclo de vida y la saga de compra.
  > 4. `ms-pagos`: Aislado estrictamente por cumplimiento de la normativa PCI DSS.
  > 5. `ms-integraciones`: Adaptador hacia los protocolos externos de aerolíneas y hoteles.
  > 6. `ms-fidelizacion`: Reglas de negocio de acumulación y canje de puntos.
  > 7. `ms-notificaciones`: Servicio stateless para el despacho multicanal.
  >
  > **¿Por qué elegimos microservicios frente a un monolito? (IE3):**
  > Primero, por la **escalabilidad asimétrica**: en temporada alta las búsquedas se disparan 20 veces, pero los pagos y usuarios mantienen una tasa normal. En un monolito tendríamos que escalar toda la aplicación; con microservicios escalamos solo `ms-busqueda`, optimizando costos en un 70%.
  > Segundo, por **aislamiento de fallas y datos**: cada microservicio tiene su **propia base de datos relacional Aurora Serverless PostgreSQL**. No existen tablas compartidas ni acoplamiento por base de datos, garantizando despliegues 100% independientes."

---

### Parte 3: Flujo de Datos Crítico y Patrones de Diseño Cloud (2:45 – 4:15) — **Expone: Andrés**
* **Visual en pantalla:** Mostrar el diagrama `entrega/c4/C4-4-Dinamico.png` y luego zoom a `entrega/soloUnServicio/S4-Secuencia.png`.
* **Guión Andrés:**
  > "En el **Diagrama Dinámico C4 Nivel 4** representamos el flujo de datos crítico desde la búsqueda hasta la confirmación:
  >
  > 1. El viajero consulta opciones desde la app móvil. La petición entra por **Amazon API Gateway**, que valida el token JWT y aplica *rate limiting*.
  > 2. `ms-busqueda` consulta la caché en **Amazon ElastiCache Redis** con el patrón *Cache-Aside* para entregar respuestas en menos de 3 segundos (RNF-05).
  > 3. Al confirmar la compra, `ms-reservas` ejecuta un **bloqueo atómico temporal** en Redis mediante la instrucción `SETNX` con un TTL de 15 minutos. Esto garantiza el invariante de negocio: nadie más puede tomar ese cupo mientras dura el checkout.
  > 4. `ms-reservas` invoca síncronamente a `ms-pagos` mediante llamadas protegidas con el patrón **Circuit Breaker (Resilience4j)**. Si la pasarela responde OK, la reserva se actualiza a estado PAGADA en la base de datos local.
  > 5. Para no hacer esperar al usuario, aplicamos **Arquitectura Orientada a Eventos (EDA)**: `ms-reservas` encola un mensaje persistente en **Amazon SQS con Dead Letter Queue (DLQ)**.
  > 6. `ms-integraciones` consume de la cola y emite el boleto con el GDS externo. Al finalizar, publica en **Amazon EventBridge**, que realiza un *fan-out* automático hacia:
  >    - **AWS Lambda**, que genera el voucher en PDF y lo guarda en **Amazon S3**.
  >    - `ms-fidelizacion`, que acumula las millas del viaje.
  >    - `ms-notificaciones`, que despacha el correo vía **Amazon SES**."

---

### Parte 4: Infraestructura Cloud AWS, Seguridad y Monitoreo (4:15 – 5:30) — **Expone: Catalina**
* **Visual en pantalla:** Mostrar el diagrama `entrega/infraestructura/Infra-AWS.png` y `Infra-Red.png`.
* **Guión Catalina:**
  > "Pasando a la infraestructura cloud, nuestra solución se despliega en la región AWS `us-east-1` distribuida en **3 Zonas de Disponibilidad (Multi-AZ)** para alta tolerancia a fallos.
  >
  > Siguiendo la rúbrica de evaluación, codificamos los controles clave:
  >
  > - **Puntos de Seguridad en ROJO (IE7):**
  >   1. Autenticación perimetral con **Amazon Cognito** y validación JWT en API Gateway.
  >   2. Protección contra bots y DDoS en el Edge con **AWS WAF** y **AWS Shield**.
  >   3. Cifrado integral de datos en reposo (*at-rest*) administrado con llaves **AWS KMS** en bases de datos Aurora, buckets S3 y colas SQS.
  >   4. Gestión centralizada y rotación de credenciales y API keys mediante **AWS Secrets Manager**.
  >   5. Roles y políticas de menor privilegio con **AWS IAM** por cada tarea Fargate.
  >   6. Segmentación estricta de red mediante **Security Groups** donde las bases de datos solo admiten tráfico desde las subredes privadas de aplicación.
  >
  > - **Puntos de Monitoreo y Observabilidad en AZUL (IE8):**
  >   1. **Amazon CloudWatch** centraliza logs y métricas de latencia p95 que activan el Auto Scaling automático.
  >   2. **AWS X-Ray** permite la trazabilidad distribuida de punta a punta de cada solicitud de reserva.
  >   3. **AWS CloudTrail** provee pistas inmutables de auditoría para garantizar el no-repudio."

---

### Parte 5: Verificación de Código, Testing y Cierre (5:30 – 6:30) — **Exponen: Andrés y Catalina**
* **Visual en pantalla:** Mostrar estructura de repositorios en VS Code y el diagrama `Infra-CICD.png`.
* **Guión Andrés:**
  > "Cada uno de los 7 microservicios cuenta con su propio repositorio independiente en GitHub, con su código fuente, documentación OpenAPI/Swagger, Dockerfile y suite de pruebas automatizadas."
* **Guión Catalina:**
  > "Implementamos pruebas BDD con **Cucumber en español** que validan los contratos REST de cada dominio, y pruebas unitarias con JUnit 5 y Mockito que alcanzan el **100% de cobertura de líneas con JaCoCo**, integradas en un pipeline CI/CD con despliegue **Blue/Green** en CodeDeploy."
* **Guión Andrés:**
  > "En conclusión, la arquitectura propuesta para ViajaMejor no solo responde a los requerimientos funcionales, sino que asegura escalabilidad, alta disponibilidad, bajo acoplamiento y seguridad en cada capa. Muchas gracias por su atención."

---

## 3. Banco de Preguntas y Respuestas para la Defensa Oral con el Docente

Si la presentación se realiza en vivo o el docente efectúa preguntas de defensa, aquí están las respuestas técnicas exactas:

### P1: ¿Por qué separaron `ms-pagos` de `ms-reservas` y `ms-usuarios`? (IE9 / SRP / Seguridad)
> **Respuesta:**  
> "Se separó por dos razones fundamentales:  
> 1. **Cumplimiento de la normativa PCI DSS**: Al aislar `ms-pagos`, confinar la tokenización y no almacenar PAN (números de tarjeta), reducimos drásticamente el perímetro de auditoría y riesgo de seguridad.  
> 2. **Razón de cambio propia (SRP)**: Las reglas de procesamiento de pagos (cambio de pasarelas, comisiones o reembolsos) cambian con un ciclo distinto al del ciclo de vida de una reserva turística."

### P2: ¿Cómo evitan que dos personas compren el mismo asiento de avión al mismo tiempo? (RNF-06 / Invariante)
> **Respuesta:**  
> "Mediante un **bloqueo atómico distribuido en Amazon ElastiCache Redis** utilizando la operación `SETNX` (Set if Not Exists) con un tiempo de vida (TTL) de 15 minutos. El primer usuario en solicitar la confirmación adquiere la clave única del cupo de forma atómica en memoria. Si el pago es exitoso, la reserva se consolida; si el pago expira o falla, el TTL libera automáticamente el cupo para otros viajeros sin intervención manual."

### P3: ¿Qué ocurre si la API externa de una aerolínea o GDS (como Amadeus) se cae o responde con lentitud? (RNF-02 / Circuit Breaker)
> **Respuesta:**  
> "Aplicamos el patrón **Circuit Breaker con Resilience4j** en `ms-integraciones` y `ms-busqueda`. Si el proveedor externo supera el umbral de fallos o lentitud, el circuito se abre de inmediato, retornando un *fallback* controlado (como ofertas en caché o notificación de disponibilidad en espera) sin bloquear los hilos de ejecución de la plataforma. Además, la emisión definitiva se maneja de forma asíncrona mediante **Amazon SQS y Dead Letter Queues (DLQ)** para reintentos automáticos."

### P4: ¿Cómo garantizan que la arquitectura tenga bajo acoplamiento? (IE10)
> **Respuesta:**  
> "El bajo acoplamiento se evidencia en tres niveles:  
> 1. **Datos**: Cada microservicio posee su propia base de datos relacional Aurora Serverless; ningún servicio accede a tablas ajenas.  
> 2. **Comunicación**: La interacción síncrona solo se usa cuando es estrictamente indispensable para continuar el flujo (vía REST con Circuit Breaker), y para todo el procesamiento posterior (emisión, fidelización, emails) se utiliza mensajería asíncrona con **Amazon SQS y EventBridge**.  
> 3. **Despliegue**: Cada microservicio reside en su propio repositorio GitHub y puede compilarse y desplegarse independientemente mediante contenedores Docker en ECS Fargate."

### P5: ¿Qué representan las flechas rojas y azules en sus diagramas de infraestructura? (IE7 / IE8)
> **Respuesta:**  
> "Siguen la convención de la rúbrica EP01:  
> - **Flechas rojas (IE7)**: Representan los controles de **seguridad** (autenticación JWT en Cognito, firewall WAF, cifrado at-rest en KMS, Secrets Manager, roles IAM y Security Groups).  
> - **Flechas azules punteadas (IE8)**: Representan los puntos de **monitoreo y observabilidad** del flujo crítico (métricas y alarmas en CloudWatch, trazas distribuidas en AWS X-Ray y logs inmutables en CloudTrail y VPC Flow Logs)."
