# ViajaMejor — Entrega EP01: Diagramas de Arquitectura (C4 + Infraestructura AWS)

Esta carpeta contiene los diagramas oficiales de arquitectura para la **Evaluación Parcial N°1 (EP01)** del caso **ViajaMejor (caso06)**. Cada archivo `.puml` es el **código fuente** (diagrama como código versionable en Git) y su archivo `.png` es la imagen renderizada en alta resolución.

---

## 1. Índice de Diagramas de Arquitectura

| Diagrama | Tipo / Nivel | Qué muestra | Indicadores de Evaluación |
|---|---|---|---|
| [`c4/C4-1-Contexto`](c4/C4-1-Contexto.png) | C4 Nivel 1 (Contexto) | Sistema ViajaMejor, sus actores (Viajero, Operador Turístico, Administrador) y los sistemas externos (GDS Proveedores, Pasarela de Pagos, Correo/Push). | **IE1, IE2** |
| [`c4/C4-2-Contenedores`](c4/C4-2-Contenedores.png) | C4 Nivel 2 (Contenedores) | Clientes (Web SPA, App Móvil), Amazon API Gateway, Cognito, los **7 microservicios independientes**, **una BD Aurora dedicada por dominio**, caché Redis, colas SQS, bus EventBridge y Lambda. | **IE4, IE5, IE6, IE9, IE10** |
| [`c4/C4-3-Componentes`](c4/C4-3-Componentes.png) | C4 Nivel 3 (Componentes) | Zoom interno al núcleo transaccional **ms-reservas**: dónde residen el controller, service, bloqueo atómico de cupos en Redis, Circuit Breakers (Resilience4j) y publicador SQS. | **IE9, IE10, IE11** |
| [`c4/C4-4-Dinamico`](c4/C4-4-Dinamico.png) | C4 Dinámico (Flujo Crítico) | El flujo de datos crítico numerado (16 pasos): búsqueda → bloqueo atómico → cobro con pasarela → persistencia → emisión asíncrona en GDS → generación de voucher PDF → puntos de fidelización → despacho de correo. | **IE6, IE8** |
| [`infraestructura/Infra-AWS`](infraestructura/Infra-AWS.png) | Infraestructura Cloud AWS | Despliegue en AWS us-east-1 multi-AZ con iconos oficiales: Edge (Route 53, CloudFront, WAF, Shield), VPC privada, ECS Fargate, Aurora Serverless, Redis, S3, SQS, EventBridge, Lambda, **Seguridad en rojo (IE7)** y **Monitoreo en azul (IE8)**. | **IE5, IE7, IE8** |
| [`infraestructura/Infra-Red`](infraestructura/Infra-Red.png) | Topología de Red VPC | Segmentación de red en 3 Zonas de Disponibilidad (AZs): Subredes públicas (ALB), privadas de aplicación (Fargate), privadas de datos (Aurora/Redis), NAT Gateways, VPC Endpoints y Security Groups. | **IE5, IE7, IE8** |
| [`infraestructura/Infra-CICD`](infraestructura/Infra-CICD.png) | Pipeline CI/CD | Pipeline automatizado: GitHub → AWS CodePipeline → CodeBuild (Java 21, Maven, Cucumber, JaCoCo 100% LINE) → ECR → CodeDeploy Blue/Green en ECS Fargate con auto-rollback. | **IE8, RNF-02** |
| [`soloUnServicio/`](soloUnServicio/README.md) | Zoom Progresivo a ms-reservas | Zoom progresivo a **ms-reservas** (Contexto → Contenedor → Componentes → Secuencia UML de la saga → Infraestructura dedicada). | **IE9, IE10, IE11** |

---

## 2. Convención de Colores en los Diagramas de Infraestructura

- **Flechas y Contornos Rojos (`#B71C1C`)**: Puntos de **SEGURIDAD (IE7)**:
  1. Autenticación con tokens JWT y User Pools en Amazon Cognito.
  2. Filtrado perimetral anti-bot y rate limiting en AWS WAF.
  3. Protección perimetral contra DDoS con AWS Shield en CloudFront.
  4. Cifrado de datos en reposo (at-rest) con llaves administradas en AWS KMS (Aurora, S3, SQS).
  5. Inyección segura de credenciales y API keys mediante AWS Secrets Manager.
  6. Control de acceso granular por tarea con roles y políticas mínimas en AWS IAM.
  7. Aislamiento de red mediante Security Groups entre capas (ALB → Fargate → Aurora).
- **Flechas y Elementos Azules Punteados (`#1565C0`)**: Puntos de **MONITOREO Y OBSERVABILIDAD (IE8)**:
  1. Métricas de tráfico, latencia y alarmas para Auto Scaling en Amazon CloudWatch.
  2. Trazabilidad distribuida de punta a punta de las solicitudes de reserva con AWS X-Ray.
  3. Registro inmutable de auditoría para no-repudio de operaciones en AWS CloudTrail.
  4. Auditoría de tráfico y paquetes con VPC Flow Logs.

---

## 3. Cómo Visualizar y Regenerar las Imágenes PNG

Los diagramas están construidos en **PlantUML estándar** (utilizando las librerías oficiales C4 y AWS Icons).

Para visualizarlos o editarlos:
1. **Visual Studio Code**: Abrir cualquier archivo `.puml`, presionar `Alt + D` (con la extensión PlantUML instalada) para ver la vista previa en tiempo real.
2. **Draw.io / Lucidchart**: Se pueden importar las imágenes `.png` generadas directamente como diagrama de arquitectura final.
3. **Consola / CLI**:
   ```bash
   plantuml -tpng c4/*.puml infraestructura/*.puml soloUnServicio/*.puml
   ```

---

## 4. Guía Rápida para la Presentación / Video

El orden recomendado de narración técnica es:
1. **Contexto (C4-1)**: Explicar quiénes usan ViajaMejor (viajeros, operadores) y con qué proveedores externos se coordina.
2. **Contenedores (C4-2)**: Mostrar los 7 microservicios, el aislamiento estricto de base de datos por dominio y la comunicación asíncrona por colas/eventos.
3. **Flujo Dinámico (C4-4)**: Detallar el flujo crítico numerado, enfatizando cómo el bloqueo atómico en Redis (`SETNX`) previene la sobreventa y cómo la saga desacopla la emisión externa.
4. **Infraestructura Cloud AWS (Infra-AWS / Infra-Red)**: Mostrar el despliegue multi-AZ, las flechas rojas de seguridad (**IE7**) y las flechas azules de monitoreo (**IE8**).
5. **Zoom a ms-reservas (soloUnServicio)**: Demostrar bajo acoplamiento, alta cohesión y resiliencia con Circuit Breaker ante proveedores lentos.
