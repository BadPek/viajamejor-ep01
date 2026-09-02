# ViajaMejor — Entrega EP01: Diagramas de Arquitectura (C4 + Infraestructura AWS)

Esta carpeta contiene los diagramas oficiales de arquitectura para la **Evaluación Parcial N°1 (EP01)** del caso **ViajaMejor (Caso 06)**. Cada archivo `.puml` es el **código fuente** (diagrama como código versionable en Git) y su archivo `.png` es la imagen renderizada en alta resolución.

---

## 1. Índice de Diagramas de Arquitectura

| Diagrama | Tipo / Nivel | Qué muestra | Indicadores de Evaluación |
|---|---|---|---|
| [`c4/C4-1-Contexto`](c4/C4-1-Contexto.png) | C4 Nivel 1 (Contexto) | Sistema ViajaMejor, sus actores (Viajero, Operador Turístico, Administrador) y los sistemas externos (GDS Proveedores, Pasarela de Pagos, Correo/Push). | **IE1, IE2** |
| [`c4/C4-2-Contenedores`](c4/C4-2-Contenedores.png) | C4 Nivel 2 (Contenedores) | Clientes (Web SPA, App Móvil), Amazon API Gateway, Cognito, los **7 microservicios independientes**, **una BD Aurora dedicada por dominio**, caché Redis, colas SQS, bus EventBridge y Lambda. | **IE4, IE5, IE6, IE9, IE10** |
| [`c4/C4-3-Componentes`](c4/C4-3-Componentes.png) | C4 Nivel 3 (Componentes) | Zoom interno al núcleo transaccional **ms-reservas**: controller, service, bloqueo atómico de cupos en Redis, Circuit Breakers (Resilience4j) y publicador SQS. | **IE9, IE10, IE11** |
| [`c4/C4-4-Dinamico`](c4/C4-4-Dinamico.png) | C4 Dinámico (Flujo Crítico) | Flujo de datos crítico numerado (16 pasos): búsqueda → bloqueo atómico → cobro → persistencia → emisión asíncrona GDS → voucher PDF → fidelización → correo. | **IE6, IE8** |
| [`infraestructura/Infra-AWS`](infraestructura/Infra-AWS.png) | Infraestructura Cloud AWS | Despliegue en AWS us-east-1 multi-AZ con iconos oficiales: Edge (Route 53, CloudFront, WAF, Shield), VPC privada, ECS Fargate, Aurora Serverless, Redis, S3, SQS, EventBridge, Lambda, **Seguridad en rojo (IE7)** y **Monitoreo en azul (IE8)**. | **IE4, IE5, IE7, IE8** |
| [`infraestructura/Infra-Red`](infraestructura/Infra-Red.png) | Topología de Red VPC | Segmentación de red en 3 Zonas de Disponibilidad (AZs): Subredes públicas (ALB), privadas de aplicación (Fargate), privadas de datos (Aurora/Redis), NAT Gateways, VPC Endpoints y Security Groups. | **IE5, IE7, IE8** |
| [`infraestructura/Infra-CICD`](infraestructura/Infra-CICD.png) | Pipeline CI/CD | Pipeline automatizado: GitHub → AWS CodePipeline → CodeBuild (Java 21, Maven, Cucumber, JaCoCo 100% LINE) → ECR → CodeDeploy Blue/Green en ECS Fargate con auto-rollback. | **IE8, RNF-02** |

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

## 3. Visualización y Regeneración

Los diagramas están construidos en **PlantUML estándar**.

Para regenerar las imágenes PNG:
```bash
java -jar plantuml.jar -tpng c4/*.puml infraestructura/*.puml
```
