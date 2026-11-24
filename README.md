# ViajaMejor — Plataforma de Microservicios Cloud Native (OTA)

> **Integracion y Despliegue de Soluciones Cloud — Caso 06: ViajaMejor**  
> **Duoc UC — Carrera Ingenieria en Informatica (JVY0101)**  
> **Integrantes:** Andres Ignacio Osorio Escobar · Matias Padilla Gutierrez  
> **Docente:** Mauricio Andres Velasquez Silva  

Ecosistema completo de **7 microservicios Spring Boot 3 (Java 21)** contenerizados con Docker multi-stage optimizado, orquestados en un **cluster Docker Swarm (Manager + Workers)**, automatizados mediante **pipeline CI/CD en GitHub Actions** con provision de infraestructura en **AWS** (**Amazon RDS MySQL**, **Amazon SQS + DLQ**, **Amazon S3**, **AWS Lambda** y **Amazon API Gateway**).

---

## 1. Arquitectura Integrada en la Nube

```text
Cliente / Postman
   │  HTTPS + Header x-api-key (403 sin credencial / 200 con credencial)
   ▼
Amazon API Gateway (viajamejor-api-gw / stage prod)
   ├── /reservas, /usuarios, /busqueda, /pagos, /notificaciones
   │        ▼
   │   Cluster Docker Swarm (Manager + Workers · Red Overlay)
   │     ├── ms-reservas (replicas distribuidas · productor SQS)
   │     ├── ms-usuarios, ms-busqueda, ms-pagos, ms-integraciones, ms-fidelizacion
   │     └── ms-notificaciones (consumidor SQS)
   │        │
   │        ├── Persistencia relacional ──▶ Amazon RDS MySQL 8.0 / MySQL Swarm
   │        └── Evento RESERVA_CONFIRMADA ──▶ Amazon SQS (viajamejor-reservas-queue + DLQ)
   │                                              │ Trigger automatico
   │                                              ▼
   └── /voucher ─────────────────────────▶ AWS Lambda (viajamejor-voucher-generator)
                                              ├── Guarda Voucher JSON + HTML/QR en Amazon S3
                                              └── Publica VOUCHER_GENERADO ──▶ SQS Notificaciones
                                                                                  └──▶ ms-notificaciones
```

---

## 2. Estructura del Repositorio

```text
caso06/
├── .github/workflows/
│   └── ci-cd.yml                       # Pipeline CI/CD completo: build -> test -> push -> provision cloud -> deploy Swarm
├── docker-compose.yml                  # Orquestacion local (sin secretos hardcodeados, usa .env)
├── docker-compose.swarm.yml            # Stack de produccion para Docker Swarm (deploy, replicas, overlay, secrets)
├── .env.example                        # Plantilla de variables de entorno (copiar a .env para local)
├── swarm/                              # Scripts de inicializacion, despliegue, escalado y README del cluster
│   ├── init-manager.sh
│   ├── join-worker.sh
│   ├── deploy-stack.sh
│   ├── scale-demo.sh
│   └── README.md
├── infra/                              # Scripts idempotentes de provision cloud en AWS
│   ├── 01-provision-storage-and-queues.sh
│   ├── 02-provision-database.sh
│   ├── 03-deploy-serverless.sh
│   ├── 04-provision-api-gateway.sh
│   ├── 05-provision-swarm-ec2.sh
│   ├── provision-all.sh
│   └── README.md
├── serverless/voucher-generator/       # Funcion FaaS AWS Lambda + pruebas + SAM template + deploy
│   ├── handler.py
│   ├── test_handler.py
│   ├── event-sample.json
│   ├── template.yaml
│   ├── deploy.sh
│   └── README.md
├── postman/
│   ├── ViajaMejor-EP02.postman_collection.json
│   └── ViajaMejor-EP03-E2E.postman_collection.json
├── scripts/                            # build-all / test-all (PowerShell y Bash)
├── entrega/                            # Diagramas de arquitectura C4 e Infraestructura AWS
└── ms/                                 # 7 microservicios Spring Boot con Dockerfile multi-stage + .dockerignore
    ├── usuarios/                       # :8081  /api/usuarios
    ├── busqueda/                       # :8082  /api/busqueda
    ├── reservas/                       # :8083  /api/reservas       (Productor SQS)
    ├── pagos/                          # :8084  /api/pagos
    ├── integraciones/                  # :8085  /api/integraciones
    ├── fidelizacion/                   # :8086  /api/fidelizacion
    └── notificaciones/                 # :8087  /api/notificaciones (Consumidor SQS)
```

---

## 3. Microservicios, Dockerfiles Optimizados y Modelo de Datos

Todos los microservicios incluyen un **`Dockerfile` multi-stage optimizado** y un **`.dockerignore`** dedicado:
- **Etapa 1 (`build`):** `maven:3.9-eclipse-temurin-21-alpine` copia `pom.xml` y resuelve dependencias (`mvn dependency:go-offline`) antes de copiar `src/`, maximizando el uso de cache de capas.
- **Etapa 2 (`runtime`):** `eclipse-temurin:21-jre-alpine` (imagen liviana ~215 MB), crea un **usuario sin privilegios (`appuser`)**, expone el puerto `8080`, configura flags JVM de contenedor (`-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0`) y un `HEALTHCHECK` nativo sobre `/actuator/health`.
- **Seguridad:** cero credenciales dentro de los Dockerfiles, imagenes o archivos Compose; toda configuracion sensible se inyecta por variables de entorno, Docker Secrets o GitHub Secrets.

| Microservicio | Puerto | Endpoint Base | Entidades JPA (`@OneToMany`) | Rol en Flujo Cloud |
|---|:---:|---|---|---|
| **`ms-usuarios`** | `8081` | `/api/usuarios` | `Usuario` ↔ `Direccion` | Gestion de viajeros |
| **`ms-busqueda`** | `8082` | `/api/busqueda` | `ResultadoBusqueda` ↔ `FiltroBusqueda` | Busqueda de ofertas |
| **`ms-reservas`** | `8083` | `/api/reservas` | `Reserva` ↔ `ItemReserva` | **Productor SQS** (`RESERVA_CONFIRMADA`) + `X-Instance-Host` |
| **`ms-pagos`** | `8084` | `/api/pagos` | `Pago` ↔ `Transaccion` | Procesamiento de pagos |
| **`ms-integraciones`** | `8085` | `/api/integraciones` | `Integracion` ↔ `RegistroLlamada` | Conectores GDS |
| **`ms-fidelizacion`** | `8086` | `/api/fidelizacion` | `Punto` ↔ `MovimientoPunto` | Programa de puntos |
| **`ms-notificaciones`** | `8087` | `/api/notificaciones` | `Notificacion` ↔ `EnvioNotificacion` | **Consumidor SQS** (`VOUCHER_GENERADO`) |

---

## 4. Ejecucion Local con Contenedores

### 4.1 Compilar y Ejecutar un Microservicio Individual en Docker
```bash
docker build -t viajamejor/reservas:v1 ./ms/reservas
docker images viajamejor/reservas:v1
docker run -d --name reservas-local -p 8083:8080 viajamejor/reservas:v1

# Verificar salud y endpoint
curl -i http://localhost:8083/actuator/health
curl -i http://localhost:8083/api/reservas
```

### 4.2 Levantar el Stack Completo con Docker Compose (Local)
```bash
cp .env.example .env
# Editar .env definiendo MYSQL_ROOT_PASSWORD y DB_PASSWORD
docker compose up -d --build
docker ps
```
Documentacion OpenAPI Swagger disponible en `http://localhost:<8081..8087>/swagger-ui.html`.

Detener entorno:
```bash
docker compose down
```

---

## 5. Cluster Docker Swarm (Manager + Workers)

La configuracion completa de alta disponibilidad (`docker-compose.swarm.yml`), scripts de inicializacion y guia de escalado se documentan en **[`swarm/README.md`](swarm/README.md)**.

Comandos principales en el nodo Manager:
```bash
export DB_PASSWORD="<clave-segura>"
bash swarm/init-manager.sh <IP_PRIVADA_MANAGER>
# En los nodos Worker: bash swarm/join-worker.sh <TOKEN> <IP_PRIVADA_MANAGER>

docker node ls
bash swarm/deploy-stack.sh
docker stack services viajamejor
docker service ps viajamejor_reservas

# Escalado dinamico verificando continuidad y balanceo
docker service scale viajamejor_reservas=4
docker service scale viajamejor_reservas=2
```

---

## 6. Pipeline CI/CD y Provision Cloud (GitHub Actions)

El flujo automatizado en [`.github/workflows/ci-cd.yml`](.github/workflows/ci-cd.yml) se dispara automaticamente en cada `push` a `main`/`develop` y en `pull_request`:

| Job | Descripcion |
|---|---|
| **`build-and-test`** | Matriz paralela sobre los 7 microservicios ejecutando `mvn -B clean verify` (compilacion Java 21, JUnit, MockMvc, Cucumber BDD y cobertura JaCoCo 100%). |
| **`test-serverless`** | Ejecuta `python3 -m unittest` sobre la funcion Lambda `serverless/voucher-generator`. |
| **`build-and-push-images`** | Construye las 7 imagenes multi-stage Alpine con Buildx y las publica en GitHub Container Registry (`ghcr.io/badpek/viajamejor-<svc>:latest` y `:<sha>`). |
| **`provision-cloud`** | Ejecuta los scripts de [`infra/`](infra/README.md) para provisionar de forma idempotente **Amazon S3**, **Amazon SQS + DLQ**, **Amazon RDS MySQL 8.0**, **AWS Lambda (+ trigger SQS)** y **Amazon API Gateway (+ API Key)**. |
| **`deploy-swarm`** | Despliega automaticamente el stack actualizado en el nodo Manager del cluster Docker Swarm via SSH (`docker stack deploy --with-registry-auth`) y ejecuta smoke tests contra `/actuator/health`. |

### Secrets requeridos en GitHub (`Settings -> Secrets and variables -> Actions`)

| Secret | Uso |
|---|---|
| `AWS_ACCESS_KEY_ID` | Credencial AWS para provision cloud (S3, SQS, RDS, Lambda, API Gateway) |
| `AWS_SECRET_ACCESS_KEY` | Clave secreta AWS |
| `AWS_SESSION_TOKEN` | Token de sesion temporal (requerido en AWS Academy Learner Lab; opcional en cuenta estandar) |
| `DB_USER` / `DB_PASSWORD` | Credenciales para Amazon RDS MySQL y Docker Secret del cluster Swarm |
| `SWARM_MANAGER_HOST` | IP publica o DNS del nodo Manager de Docker Swarm |
| `SWARM_SSH_USER` | Usuario SSH del Manager (por defecto `ubuntu`) |
| `SWARM_SSH_KEY` | Clave privada PEM para conexion SSH al nodo Manager |
| `LAMBDA_ROLE_ARN` | *(Opcional)* ARN de rol IAM; si se omite usa `arn:aws:iam::<ACCOUNT_ID>:role/LabRole` |

---

## 7. Funcion Serverless, Colas SQS y API Gateway

- **Funcion Serverless:** documentada en **[`serverless/voucher-generator/README.md`](serverless/voucher-generator/README.md)**. Genera vouchers oficiales con hash QR SHA-256 al recibir eventos `RESERVA_CONFIRMADA` desde SQS, almacena JSON y HTML en Amazon S3 y notifica a la cola de `ms-notificaciones`.
- **Provision Cloud (S3, SQS + DLQ, RDS, API Gateway):** documentada en **[`infra/README.md`](infra/README.md)**.
- **Pruebas Postman End-to-End:** importar [`postman/ViajaMejor-EP03-E2E.postman_collection.json`](postman/ViajaMejor-EP03-E2E.postman_collection.json) para validar:
  1. Rechazo `403 Forbidden` sin cabecera `x-api-key` en API Gateway.
  2. Respuesta `200/201` autenticada con `x-api-key`.
  3. Flujo asincrono completo: `API Gateway -> ms-reservas -> MySQL -> SQS -> Lambda -> S3 -> SQS Notificaciones -> ms-notificaciones`.

---

## 8. Verificacion de Pruebas Locales

```bash
# Todos los microservicios (Java 21 + Maven)
bash scripts/test-all.sh

# Funcion serverless (Python 3.12)
python3 -m unittest discover -s serverless/voucher-generator -v
```
