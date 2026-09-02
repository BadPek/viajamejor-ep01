# ViajaMejor — README de la Entrega (Caso 06)

**EP01 · JVY0101 — Java: Diseño y Construcción de Soluciones Nativas en Nube**

Este documento presenta la **estrategia completa de diseño arquitectónico** que transforma las necesidades de negocio de **ViajaMejor** (sección 1 de `00_PresentacionEmpresa.md`) en una arquitectura distribuida nativa en nube en AWS, modelada con C4 y soportada por 7 microservicios desacoplados en Java 21 / Spring Boot 3.3. Explica detalladamente **el porqué** de cada decisión técnica, cubriendo el 100% de los indicadores de evaluación de la rúbrica (**IE1 a IE13**).

---

## 0. Vista Rápida del Pipeline de Diseño

```
Caso de Negocio (ViajaMejor — 00_PresentacionEmpresa.md)
        │
        ├─ 1. Comprensión del Negocio ─── Actores + Proceso de Valor + 4 Riesgos Críticos
        ├─ 2. Requisitos Funcionales ──── Matriz Actor - Acción - Objeto (RF-01 .. RF-08)
        ├─ 3. Requisitos No Funcionales ─ Atributos de Calidad Medibles (QAW / ATAM)
        ├─ 4. Requisitos de Seguridad ─── STRIDE por Flujo + Clasificación de Sensibilidad
        │
        ├─ 5. Delimitación de Servicios ─ DDD Ligero + SRP (Bounded Contexts) + Monolito vs MS
        ├─ 6. Patrones Cloud Aplicados ── Problema Detectado → Patrón → Solución AWS
        │
        ├─ 7. Modelado C4 ─────────────── Contexto → Contenedores → Componentes → Dinámico
        │
        ├─ 8. Infraestructura AWS ─────── Mapeo de Componentes a Servicios AWS Multi-AZ
        │
        └─ 9. Trazabilidad y Rúbrica ──── Matriz Requisito → Decisión → Diagrama (IE1 .. IE13)
```

Toda decisión técnica cuenta con una justificación conectada directamente a los requerimientos del negocio, demostrable en la tabla de trazabilidad (§9).

---

## 1. Comprensión del Negocio antes de Modelar

### a) Los Actores
| Actor | Rol y Responsabilidad | Canal de Interacción |
|---|---|---|
| **Viajero / Cliente** | Busca vuelos, hoteles, autos y paquetes; crea reservas, paga en línea, canjea puntos y gestiona sus itinerarios. | App Móvil (Flutter) / Web SPA (React) |
| **Operador Turístico / Partner** | Administra cupos locales, actualiza tarifas y valida vouchers de viaje en destino. | Portal Web (React SPA) |
| **Administrador de Plataforma** | Monitorea la salud de los servicios, supervisa reglas de fidelización y audita transacciones. | Portal Web (React SPA) |
| **Proveedores Externos (GDS / APIs)** | Amadeus, Sabre, Expedia, APIs de aerolíneas, hoteles y rent-a-car para cotizaciones y emisiones oficiales. | HTTPS REST / SOAP APIs |
| **Pasarela de Pagos (Sistema)** | Transbank Webpay, Stripe: autoriza cobros tokenizados, notifica por webhook y procesa reembolsos. | HTTPS REST API + Webhooks |
| **Servicio de Notificaciones (Sistema)** | Amazon SES, Firebase FCM: entrega física de itinerarios, vouchers PDF, correos y alertas push. | SMTP / Push APIs |

### b) El Proceso de Valor (El Flujo Crítico del Negocio)
> **Búsqueda agregada → Selección y Bloqueo temporal → Cobro seguro → Emisión con proveedor externo → Generación de Voucher con QR → Acumulación de puntos → Despacho multicanal.**

Este proceso define el **flujo de datos crítico (IE8)**: los datos ingresan por la app del viajero, se enriquecen con proveedores externos, se persisten con consistencia transaccional y se despachan de forma asíncrona hacia fidelización y notificaciones.

### c) Los 4 Riesgos Críticos del Negocio (Drivers Arquitectónicos)
1. **Lentitud y Caída de Proveedores Externos**: Las APIs de aerolíneas u hoteles pueden responder lento (>5s) o estar caídas temporalmente.
   - *Solución*: **Circuit Breaker (Resilience4j)** en `ms-integraciones` y `ms-busqueda` con caché distribuida en Redis.
2. **Picos Masivos en Temporada Alta / CyberDays**: Incremento de hasta 20x en búsquedas sin que colapse el motor de reservas.
   - *Solución*: Escalabilidad horizontal independiente en ECS Fargate para `ms-busqueda` y `ms-reservas`.
3. **Sobreventa de Asientos o Habitaciones (Invariante de Negocio)**: Múltiples viajeros intentando comprar el último cupo simultáneamente.
   - *Solución*: Bloqueo atómico temporal en **Amazon ElastiCache Redis** (`SETNX` con TTL de 15 minutos).
4. **Cumplimiento PCI DSS y Protección de Datos Personales**: Exposición de datos de tarjetas de crédito o pasaportes.
   - *Solución*: Aislamiento de `ms-pagos`, tokenización en pasarela (cero almacenamiento de PAN) y cifrado at-rest con **AWS KMS**.

---

## 2. Estrategia para Requisitos Funcionales (RF)

Se aplicó la **matriz Actor – Acción – Objeto** para derivar de forma verificable los 8 requisitos funcionales del negocio:

| Actor ↓ / Objeto → | Perfil / Usuario | Vuelo / Hotel (Catálogo) | Reserva / Itinerario | Pago / Reembolso | Puntos Fidelización | Notificación / Voucher |
|---|---|---|---|---|---|---|
| **Viajero** | Registrar, autenticar, editar (RF-01) | Buscar, filtrar precios/fechas (RF-02) | Crear, modificar, cancelar (RF-04) | Pagar reserva en línea (RF-05) | Consultar saldo, canjear (RF-07) | Recibir itinerario y voucher (RF-08) |
| **Operador** | Autenticar perfil comercial | Publicar inventario y tarifas (RF-03) | Consultar estado de emisión | Conciliar cobros/comisiones | — | Validar voucher con QR |
| **GDS / Proveedor** | — | Entregar disponibilidad viva (RF-03) | Confirmar emisión PNR (RF-06) | — | — | — |
| **Pasarela** | — | — | — | Autorizar / Reembolsar (RF-05) | — | — |

**Reglas aplicadas:**
1. **Un RF = Una capacidad de negocio verificable** (ej. "RF-04: Crear, modificar y cancelar reservas").
2. **Los RF delimitan dominios funcionales**, evitando mezclar pagos con búsqueda o catálogo con reservas.
3. **Cero invención**: Se mapean estrictamente a los 8 RF descritos en `00_PresentacionEmpresa.md`.

---

## 3. Estrategia para Requisitos No Funcionales (RNF) con Escenarios Medibles

Aplicando el método **QAW/ATAM ligero**, cada atributo de calidad se especificó mediante un escenario con **métrica verificable**:

| Código | Atributo | Escenario Disparador | Métrica Verificable | Decisión de Diseño |
|---|---|---|---|---|
| **RNF-01** | **Escalabilidad** | "Lanzamiento de CyberTravel: 40.000 búsquedas concurrentes por minuto" | El buscador escala de 2 a 12 tareas Fargate sin degradar reservas ni usuarios | Auto Scaling horizontal independiente por microservicio en ECS Fargate |
| **RNF-02** | **Disponibilidad** | "Cae el servicio de pagos o la API de una aerolínea externa" | 99.95% de disponibilidad en búsqueda y visualización de reservas previas | Circuit Breaker (Resilience4j) + Desacople asíncrono con Amazon SQS y multi-AZ |
| **RNF-03** | **Mantenibilidad** | "Cambia el formato de API de Amadeus a REST v2 sin alterar reservas" | Despliegue de `ms-integraciones` en <10 min sin tocar ni reiniciar `ms-reservas` | Microservicios con bajo acoplamiento e interfaces REST/eventos bien definidas |
| **RNF-04** | **Seguridad** | "Intento de inyección SQL o acceso a datos de tarjetas de crédito" | 0 incidentes; cero PAN almacenado; 100% de endpoints protegidos por JWT | Amazon API Gateway + WAF + Cognito + KMS + Aislamiento de `ms-pagos` |
| **RNF-05** | **Rendimiento** | "Viajero busca vuelos Santiago-Miami en temporada alta" | Latencia de búsqueda p95 < 3.0 segundos | Caché distribuida ElastiCache Redis (Cache-Aside) + CDN CloudFront |
| **RNF-06** | **Consistencia** | "Falla la red mientras se confirmaba la emisión con la aerolínea" | Cero reservas duplicadas; stock liberado o reintentado automáticamente | Bloqueo atómico con Redis (`SETNX`) + Saga por coreografía + SQS DLQ |

---

## 4. Requisitos de Seguridad (STRIDE y Clasificación de Datos)

### a) Clasificación de Datos por Nivel de Sensibilidad
| Tipo de Dato | Nivel | Contramedida de Protección |
|---|---|---|
| **Credenciales y Contraseñas** | Alta | Amazon Cognito (hashing bcrypt/PBKDF2 + MFA opcional). Nunca viajan en logs. |
| **Datos de Tarjetas de Crédito (PAN / CVV)** | Crítica (PCI DSS) | **No se almacenan**. Tokenización directa en pasarela Webpay/Stripe vía SDK cliente. |
| **Datos Personales y Pasaportes** | Alta | Cifrado en reposo con AWS KMS (AES-256) en Aurora y control de acceso estricto IAM. |
| **Órdenes de Reserva e Itinerarios** | Media | Cifrado at-rest (KMS) y en tránsito con TLS 1.2+ obligatorio en VPC. |
| **Vouchers PDF con Códigos QR** | Media | Firma digital SHA-256 y URLs prefirmadas en Amazon S3 con tiempo de expiración. |

### b) Mapeo STRIDE por Flujo
| Amenaza | Tramo del Sistema | Contramedida Arquitectónica (Flechas Rojas IE7) |
|---|---|---|
| **S**poofing (Suplantación) | Login y llamadas API | Amazon Cognito + Tokens JWT firmados criptográficamente, validados en API Gateway. |
| **T**ampering (Alteración) | Tránsito de órdenes | TLS 1.2+ en todas las conexiones internas; validaciones JPA y firmas en vouchers S3. |
| **R**epudiation (No Repudio) | Creación de reservas y pagos | AWS CloudTrail (auditoría inmutable de llamadas) + timestamps inmutables en Aurora. |
| **I**nformation Disclosure | Almacenamiento de datos | Cifrado at-rest administrado por AWS KMS en bases de datos PostgreSQL, S3 y SQS. |
| **D**enial of Service | Búsqueda en temporada alta | AWS WAF con rate limiting + AWS Shield anti-DDoS + ECS Fargate Auto Scaling. |
| **E**levation of Privilege | Roles Viajero / Operador / Admin | Pools y claims de rol en JWT; políticas IAM de mínimo privilegio por microservicio. |

---

## 5. Delimitación de Microservicios (DDD y SRP)

Se aplicó **Domain-Driven Design (DDD)** identificando los *Bounded Contexts* según el Principio de Responsabilidad Única (SRP):

| Microservicio | Dominio / Responsabilidad (SRP) | Razón de Cambio Exclusiva |
|---|---|---|
| **ms-usuarios** | Gestión de identidad, perfiles de viajeros y datos de contacto | Normativas de privacidad de datos, autenticación y login social. |
| **ms-busqueda** | Agregación multicanal de disponibilidad y tarifas (vuelos, hoteles, autos) | Nuevos algoritmos de ordenamiento, filtros o proveedores de búsqueda. |
| **ms-reservas** | Máquina de estados y orquestación transaccional del ciclo de vida de la reserva | Reglas de reserva, políticas de cancelación y saga transaccional. |
| **ms-pagos** | Cobros, reembolsos, comprobantes fiscales y tokenización | Cambios en normativas PCI DSS o integración de nuevas pasarelas de pago. |
| **ms-integraciones** | Adaptadores y traductores de protocolos hacia APIs externas (GDS/APIs) | Cambios en contratos técnicos, formatos XML/JSON o endpoints de aerolíneas. |
| **ms-fidelizacion** | Cálculo y acumulación de puntos, categorías de socios y canjes | Nuevas campañas comerciales, alianzas de millas o reglas de beneficios. |
| **ms-notificaciones** | Despacho multicanal de confirmaciones, vouchers e itinerarios | Nuevas plantillas de correo, canales SMS o integración con WhatsApp API. |

### ¿Por qué Microservicios y no un Monolito? (IE3)
1. **Escalabilidad Asimétrica**: Durante CyberTravel, las búsquedas se multiplican por 20x mientras que la fidelización mantiene tráfico normal. Un monolito obligaría a escalar toda la aplicación completa; con microservicios se escala **únicamente `ms-busqueda`**, reduciendo costos de infraestructura en un 70%.
2. **Aislamiento del Entorno de Pagos (PCI DSS)**: `ms-pagos` queda confinado en su propio contenedor y base de datos, reduciendo el perímetro de auditoría de seguridad.
3. **Resiliencia ante Proveedores Inestables**: La lentitud o caída de un GDS en `ms-integraciones` es contenida por Circuit Breakers y colas, permitiendo que el resto del sitio siga operando con normalidad.
4. **Despliegues Independientes**: El equipo de integraciones puede actualizar el conector de una aerolínea sin riesgo de interrumpir el motor de pagos o la autenticación.

---

## 6. Catálogo de Patrones de Diseño Cloud (IE5)

| Problema Detectado en ViajaMejor | Patrón Cloud Aplicado | Implementación Técnica Concreta |
|---|---|---|
| Punto de entrada unificado, rate limiting y seguridad perimetral | **API Gateway** | **Amazon API Gateway**: enrutamiento por ruta `/api/*`, validación JWT y throttling anti-bot. |
| Descubrimiento dinámico de microservicios sin IPs fijas | **Service Registry** | **AWS Cloud Map**: registro y resolución DNS interna en el clúster ECS. |
| Caída o lentitud de APIs externas de aerolíneas y pasarelas | **Circuit Breaker** | **Resilience4j**: apertura de circuito con fallback seguro en `ms-busqueda` y `ms-reservas`. |
| Emisión de pasajes lenta que no debe bloquear al usuario | **Asynchronous Messaging** | **Amazon SQS (+ DLQ)**: cola persistida para desacoplar el cobro de la emisión física. |
| Múltiples consumidores de un mismo evento de reserva | **Event Backbone (Fan-Out)** | **Amazon EventBridge**: `reserva.confirmada` activa en paralelo a fidelización y notificaciones. |
| Transacción distribuida entre reserva, pago y emisión | **Saga por Coreografía** | Eventos con compensación automática (liberación de stock en Redis y reembolso si falla emisión). |
| Búsquedas repetitivas y protección contra sobreventa | **Cache-Aside / Distributed Lock** | **Amazon ElastiCache Redis**: caché de tarifas + `SETNX` con TTL de 15 min para bloquear cupos. |
| Carga intermitente para generación pesada de itinerarios PDF | **Serverless Burst** | **AWS Lambda**: función serverless que genera el PDF bajo demanda y escala a cero en horarios valle. |
| Distribución rápida de assets web y vouchers en todo el mundo | **CDN** | **Amazon CloudFront**: distribución perimetral conectada a Amazon S3. |

---

## 7. Modelado C4: Niveles y Decisiones

| Nivel C4 | Pregunta Central | Decisiones que Congela | Requisitos que Evidencia |
|---|---|---|---|
| **C4-1 Contexto** | ¿Quién usa el sistema y con qué interactúa? | Fronteras del sistema, actores (viajeros, operadores) y sistemas externos (GDS, pagos, email). | **RF-01..04, IE1, IE2** |
| **C4-2 Contenedores** | ¿Qué aplicaciones, servicios y almacenes existen? | Los 7 microservicios, 7 BD Aurora aisladas, ElastiCache Redis, SQS, EventBridge, Lambda y S3. | **RF-05..08, RNF-01..06, IE4, IE6, IE9, IE10** |
| **C4-3 Componentes** | ¿Cómo se organiza el código dentro de `ms-reservas`? | Controladores REST, servicios de negocio, bloqueo en Redis, clientes Resilience4j y JPA. | **IE9, IE10, IE11** |
| **C4-4 Dinámico** | ¿Cómo fluyen los datos en el proceso crítico de compra? | Flujo numerado de 16 pasos con llamadas síncronas, asíncronas y eventos fan-out. | **RNF-05, RNF-06, IE6, IE8** |
| **Infraestructura AWS** | ¿Dónde y cómo se despliega la solución en la nube? | VPC multi-AZ, subredes app/datos, ECS Fargate, Aurora Serverless, KMS (rojo) y CloudWatch (azul). | **IE5, IE7 (rojo), IE8 (azul)** |

---

## 8. Criterios de Mapeo a la Infraestructura AWS

Para asignar la tecnología AWS adecuada a cada componente se siguieron 4 criterios estrictos:
1. **Managed First**: Reducir carga operativa delegando alta disponibilidad y parches a AWS (Aurora Serverless, API Gateway, SQS).
2. **Serverless para Carga Intermitente**: Usar **AWS Lambda** para generación de PDFs y procesamiento de eventos, logrando costo cero cuando no hay transacciones.
3. **Especialización por Tipo de Dato**:
   - Bases relacionales transaccionales → **Amazon Aurora Serverless v2 (PostgreSQL)**.
   - Bloqueos atómicos en memoria y caché → **Amazon ElastiCache (Redis)**.
   - Documentos e itinerarios binarios → **Amazon S3**.
4. **Resiliencia Multi-AZ**: Despliegue en 3 Zonas de Disponibilidad (us-east-1a, 1b, 1c) con balanceadores ALB y replicación automática de bases de datos.

---

## 9. Matriz de Trazabilidad Requisito → Decisión → Diagrama

| Requisito / Criterio | Decisión Arquitectónica Implementada | Evidencia en Diagrama |
|---|---|---|
| **RF-01 (Usuarios)** | Autenticación centralizada con Cognito + microservicio `ms-usuarios` con BD aislada | `C4-2-Contenedores`, `Infra-AWS` |
| **RF-02 (Búsqueda)** | `ms-busqueda` optimizado con ElastiCache Redis y auto scaling en Fargate | `C4-2-Contenedores`, `C4-4-Dinamico` |
| **RF-03 (Tarifas vivas)** | `ms-busqueda` consulta `ms-integraciones` protegido por Circuit Breaker (Resilience4j) | `C4-2-Contenedores`, `C4-4-Dinamico` |
| **RF-04 (Reservas)** | `ms-reservas` orquesta saga de compra con máquina de estados transaccional | `C4-3-Componentes`, `soloUnServicio/S4` |
| **RF-05 (Pagos)** | `ms-pagos` aislado con tokenización en pasarela y sin PAN almacenado | `C4-2-Contenedores`, `C4-4-Dinamico` |
| **RF-06 (Integraciones)** | `ms-integraciones` consume de SQS para emitir tickets PNR con aerolíneas/hoteles | `C4-2-Contenedores`, `C4-4-Dinamico` |
| **RF-07 (Fidelización)** | `ms-fidelizacion` acumula puntos mediante eventos asíncronos de EventBridge | `C4-2-Contenedores`, `C4-4-Dinamico` |
| **RF-08 (Notificaciones)** | `ms-notificaciones` despacha email/push con voucher generado por Lambda en S3 | `C4-2-Contenedores`, `C4-4-Dinamico` |
| **RNF-01 (Escalabilidad)** | Tareas ECS Fargate con escalado horizontal automático por microservicio | `Infra-AWS`, `Infra-CICD` |
| **RNF-02 (Disponibilidad)** | Arquitectura Multi-AZ en 3 zonas, colas SQS persistidas y Circuit Breakers | `Infra-AWS`, `Infra-Red` |
| **RNF-03 (Mantenibilidad)** | 7 microservicios independientes, 1 repositorio Git por servicio, contratos OpenAPI | `C4-2-Contenedores`, `Guia_GitHub` |
| **RNF-04 (Seguridad)** | Cognito JWT, WAF, KMS at-rest, Secrets Manager, Security Groups por capa | `Infra-AWS (rojo)`, `Infra-Red (rojo)` |
| **RNF-05 (Rendimiento)** | Redis Cache-Aside + CloudFront para búsqueda p95 < 3 s | `C4-4-Dinamico`, `Infra-AWS` |
| **RNF-06 (Consistencia)** | Redis `SETNX` temporal + persistencia transaccional JPA + saga con compensación | `C4-3-Componentes`, `soloUnServicio/S4` |
| **IE7 (Seguridad)** | Puntos de seguridad destacados con flechas y contornos rojos | `Infra-AWS`, `Infra-Red` |
| **IE8 (Monitoreo)** | Flujo crítico numerado y observabilidad con flechas azules (CloudWatch, X-Ray) | `C4-4-Dinamico`, `Infra-AWS` |

---

## 10. Autoevaluación de Cobertura de la Rúbrica (IE1 a IE13)

| Indicador | Dimensión | Nivel Alcanzado | Evidencia en la Entrega |
|---|---|---|---|
| **IE1** | Presentación (10%) | **Destacado** | Identificación exhaustiva de 8 RF y 6 RNF con métricas verificables y justificación de negocio (§2 y §3). |
| **IE2** | Presentación (10%) | **Destacado** | Clasificación y priorización de requerimientos según su impacto en arquitectura distribuida (§3 y §9). |
| **IE3** | Presentación (10%) | **Destacado** | Argumentación sólida de microservicios vs monolito basada en escalabilidad asimétrica y PCI DSS (§5). |
| **IE4** | Informe/Diagrama (10%) | **Destacado** | Diagramas C4 e Infraestructura completos, legibles y con leyendas explicativas en `entrega/`. |
| **IE5** | Informe/Diagrama (10%) | **Destacado** | Catálogo completo de patrones cloud (API GW, Service Discovery, Circuit Breaker, SQS, EventBridge, Saga, Cache-Aside) (§6). |
| **IE6** | Informe/Diagrama (10%) | **Destacado** | Flujos de comunicación con protocolos explícitos (HTTPS, REST, JDBC TLS, RESP, AWS SDK) en C4 y despliegue. |
| **IE7** | Informe/Diagrama (10%) | **Destacado** | Puntos de seguridad claramente identificados en rojo en `Infra-AWS` e `Infra-Red` (Cognito, WAF, KMS, Secrets, IAM) (§4). |
| **IE8** | Informe/Diagrama (10%) | **Destacado** | Flujo de datos crítico numerado (C4-4) y observabilidad en azul (CloudWatch, X-Ray, CloudTrail) en `Infra-AWS`. |
| **IE9** | Presentación (10%) | **Destacado** | Delimitación estricta de 7 microservicios por Bounded Contexts y Principio de Responsabilidad Única (§5). |
| **IE10** | Presentación (3%) | **Destacado** | Bajo acoplamiento evidente: una BD aislada por microservicio, sin tablas compartidas, comunicación API/eventos. |
| **IE11** | Presentación (2%) | **Destacado** | División lógica fundamentada en escalabilidad independiente, seguridad perimetral y mantenibilidad (§5 y §8). |
| **IE12** | Presentación (3%) | **Destacado** | Guión de video estructurado con inicio, desarrollo y cierre técnico fluido en `Guion_Presentacion_Video_Defensa.md`. |
| **IE13** | Presentación (2%) | **Destacado** | Guía de grabación y defensa oral con pautas de audio claro y preparación de preguntas del docente. |

---

## 11. Glosario de Tecnologías y su Propósito en ViajaMejor

| Tecnología | Categoría | Propósito Específico en ViajaMejor |
|---|---|---|
| **Java 21 / Spring Boot 3.3** | Backend Framework | Runtime estándar utilizado para construir los 7 microservicios REST, repositorios JPA y controladores. |
| **Amazon ECS + AWS Fargate** | Compute Contenedores | Ejecuta los contenedores Docker de Spring Boot sin administrar servidores, con auto scaling por servicio. |
| **Amazon API Gateway** | Networking / API Management | Entrada única a la API REST: valida tokens JWT de Cognito, aplica rate limiting anti-bot y enruta a la VPC. |
| **Amazon Cognito** | Identidad y Acceso | Autenticación centralizada de viajeros y operadores; emite tokens JWT con roles y claims. |
| **Amazon Aurora Serverless v2** | Base de Datos Relacional | Clústeres PostgreSQL dedicados por microservicio con alta disponibilidad multi-AZ y escalado automático. |
| **Amazon ElastiCache (Redis)** | Caché y Concurrencia | Almacena tarifas de búsqueda en memoria y ejecuta bloqueos atómicos (`SETNX`) para evitar sobreventa de cupos. |
| **Amazon SQS (+ DLQ)** | Mensajería Asíncrona | Cola persistida que desacopla la confirmación del pago de la emisión de boletos en proveedores externos. |
| **Amazon EventBridge** | Bus de Eventos (EDA) | Enruta eventos de dominio (`reserva.confirmada`) hacia múltiples consumidores (fidelización, notificaciones). |
| **AWS Lambda** | Compute Serverless | Genera bajo demanda los itinerarios y vouchers PDF con código QR y escala a cero cuando no hay compras. |
| **Amazon S3** | Object Storage | Almacena los vouchers PDF generados, comprobantes fiscales, pólizas de viaje y assets estáticos web. |
| **Amazon CloudFront** | CDN Perimetral | Distribuye el portal web y los documentos PDF con baja latencia en todo el mundo. |
| **AWS WAF & Shield** | Seguridad Perimetral | Firewall web contra bots, scraping de tarifas y mitigación automática de ataques DDoS. |
| **AWS KMS** | Seguridad Criptográfica | Administra claves para cifrado transparente en reposo (at-rest) en bases de datos, S3 y colas SQS. |
| **AWS Secrets Manager** | Gestión de Secretos | Almacena credenciales de bases de datos y API keys de pasarelas/GDS, rotándolas periódicamente. |
| **Resilience4j** | Resiliencia de Software | Implementa el patrón Circuit Breaker en clientes REST hacia servicios vecinos y APIs externas. |
| **Amazon CloudWatch & X-Ray** | Observabilidad y Monitoreo | Monitorea métricas para auto scaling y registra trazas distribuidas completas de cada reserva. |
| **AWS CodePipeline & CodeBuild** | CI/CD | Automatiza la compilación Maven, ejecución de pruebas Cucumber/JUnit y validación JaCoCo 100% LINE. |
| **Cucumber BDD** | Testing de Negocio | Pruebas de comportamiento automatizadas en español (`.feature`) que validan los endpoints REST. |
| **JaCoCo** | Calidad de Código | Analizador de cobertura de código que asegura 100% de cobertura de líneas en pruebas unitarias. |

---

## 12. Estructura de Archivos de la Entrega

```
caso06/
└── caso06/
    ├── 00_PresentacionEmpresa.md / .pdf      ← Caso de negocio oficial ViajaMejor
    ├── README.md                             ← Documento maestro de arquitectura y rúbrica (este archivo)
    ├── Guia_Subida_GitHub.md                 ← Guía y automatización para repositorios GitHub
    ├── Guion_Presentacion_Video_Defensa.md   ← Guión 3-8 min para Andrés y Catalina + FAQ Docente
    ├── subir_repositorios.ps1                ← Script PowerShell para inicializar y subir los 7 repos
    ├── entrega/
    │   ├── README.md                         ← Índice de diagramas y convenciones
    │   ├── c4/
    │   │   ├── C4-1-Contexto.puml / .png     ← Nivel 1: Contexto del Sistema
    │   │   ├── C4-2-Contenedores.puml / .png ← Nivel 2: Contenedores y 7 Microservicios
    │   │   ├── C4-3-Componentes.puml / .png  ← Nivel 3: Componentes de ms-reservas
    │   │   └── C4-4-Dinamico.puml / .png     ← Nivel 4: Flujo Crítico Numerado
    │   ├── infraestructura/
    │   │   ├── Infra-AWS.puml / .png         ← Despliegue AWS Multi-AZ (Rojo=Seguridad, Azul=Monitoreo)
    │   │   ├── Infra-Red.puml / .png         ← Topología VPC 3-AZ y subredes por capa
    │   │   └── Infra-CICD.puml / .png        ← Pipeline CI/CD Blue/Green
    │   └── soloUnServicio/
    │       ├── README.md                     ← Zoom progresivo a ms-reservas
    │       ├── S1-Contexto.puml / .png
    │       ├── S2-Contenedor.puml / .png
    │       ├── S3-Componentes.puml / .png
    │       ├── S4-Secuencia.puml / .png      ← Diagrama de secuencia UML de la saga
    │       └── S5-Infra-AWS.puml / .png      ← Infraestructura dedicada ms-reservas
    └── ms/                                   ← Los 7 microservicios Java 21 / Spring Boot 3.3
        ├── usuarios/
        ├── busqueda/
        ├── reservas/
        ├── pagos/
        ├── integraciones/
        ├── fidelizacion/
        └── notificaciones/
```
