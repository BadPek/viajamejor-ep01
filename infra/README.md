# Provision Automatizada de Infraestructura Cloud (AWS) — ViajaMejor

Scripts idempotentes ejecutados automaticamente por el pipeline CI/CD (`.github/workflows/ci-cd.yml`) para provisionar todos los recursos cloud requeridos por la arquitectura de **ViajaMejor (Caso 06)**.

---

## 1. Etapas de Provision

| Etapa | Script | Recursos Provisionados | Justificacion de Negocio |
|---|---|---|---|
| **1. Almacenamiento y Colas** | `01-provision-storage-and-queues.sh` | **Amazon S3** (`viajamejor-vouchers-<account>` con versionado y bloqueo publico), **SQS DLQ** (`viajamejor-reservas-dlq`, retencion 14 dias), **SQS Reservas** (`viajamejor-reservas-queue`, `RedrivePolicy` max 3 reintentos, retencion 4 dias), **SQS Notificaciones** (`viajamejor-notificaciones-queue`). | Desacopla la confirmacion de reservas de la emision de vouchers y notificaciones; soporta picos de trafico y garantiza cero perdida de mensajes mediante DLQ. |
| **2. Base de Datos Relacional** | `02-provision-database.sh` | **Amazon RDS MySQL 8.0** (`viajamejor-mysql-db`, `db.t3.micro`) + Security Group TCP 3306. | Persistencia relacional administrada en la nube para las entidades JPA de los microservicios. |
| **3. Funcion Serverless** | `03-deploy-serverless.sh` | **AWS Lambda** (`viajamejor-voucher-generator`, Python 3.12) + **Event Source Mapping** SQS → Lambda con `ReportBatchItemFailures`. | Emision puntual y elastica de comprobantes/QR bajo demanda sin consumir recursos fijos de computo. |
| **4. API Gateway** | `04-provision-api-gateway.sh` | **Amazon API Gateway (REST API)** `viajamejor-api-gw`, stage `prod`, rutas protegidas (`/voucher`, `/reservas`, `/notificaciones`, `/usuarios`, `/busqueda`, `/pagos`), **API Key** y **Usage Plan** (50 req/s, burst 100). | Puerta de entrada unica con control de acceso obligatorio (`x-api-key`) y proteccion de tasa contra abusos. |
| **5. Nodos EC2 Swarm** | `05-provision-swarm-ec2.sh` | 2 instancias **Amazon EC2 Ubuntu 22.04** (`viajamejor-swarm-manager` y `viajamejor-swarm-worker-1`) con Docker CE preinstalado y Security Group para puertos Swarm (`2377`, `7946`, `4789`, `8081-8087`). | Infraestructura multi-nodo para ejecutar el cluster Docker Swarm con replicas distribuidas. |

---

## 2. Ejecucion Manual (Local o AWS CloudShell)

```bash
export AWS_REGION=us-east-1
export DB_USER=admin
export DB_PASSWORD="<clave-segura-mysql>"
# Opcional si el cluster Swarm ya tiene IP publica:
export SWARM_MANAGER_HOST="<IP_PUBLICA_MANAGER>"

bash infra/provision-all.sh
```

> **Compatibilidad con AWS Academy Learner Lab:** los scripts detectan automaticamente el rol `arn:aws:iam::<ACCOUNT_ID>:role/LabRole` y aceptan credenciales temporales con `AWS_SESSION_TOKEN` sin intentar crear roles IAM restringidos.
