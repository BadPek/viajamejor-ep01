# ✈️ ViajaMejor — Plataforma Cloud Native de Reservas de Viajes (OTA)

> **Evaluación Parcial N°1 (EP01) — Asignatura: Java: Diseño y Construcción de Soluciones Nativas en Nube (JVY0101)**  
> **Duoc UC — Escuela de Informática y Telecomunicaciones**  
> **Caso 06: ViajaMejor**

---

## 📌 1. Descripción del Caso de Negocio

**ViajaMejor** es una plataforma de agencia de viajes en línea (**OTA — Online Travel Agency**) diseñada para consolidar la búsqueda, reserva, pago, emisión y fidelización de itinerarios turísticos multimodales (vuelos, hoteles y arriendo de vehículos).

La solución aborda desafíos de alta concurrencia, picos de tráfico estacionales (CyberDays, temporada de vacaciones), integración con proveedores globales heterogéneos (GDS como Amadeus/Sabre) y cumplimiento normativo estricto (**PCI DSS** para procesamiento seguro de pagos).

---

## 🏛️ 2. Arquitectura de Microservicios

La solución implementa una **Arquitectura Cloud Native desacoplada** con el principio de **Database-per-Service** (cada microservicio posee su propia base de datos relacional aislada para garantizar bajo acoplamiento e independencia de despliegue).

| Microservicio | Puerto | Base de Datos Dedicada | Responsabilidad y Dominio Funcional | Stack Tecnológico |
|---|---|---|---|---|
| **`ms-usuarios`** | `8081` | `db_usuarios` (PostgreSQL) | Gestión de perfiles de viajeros y operadores, autenticación y datos personales. | Java 21 · Spring Boot 3.3 · JPA · OpenAPI |
| **`ms-busqueda`** | `8082` | `db_busqueda` + Redis | Agregador y buscador de tarifas de vuelos, hoteles y autos en tiempo real. Caché de alta lectura. | Java 21 · Spring Boot 3.3 · JPA · Redis |
| **`ms-reservas`** | `8083` | `db_reservas` + Redis | Núcleo transaccional: orquesta el ciclo de vida de la reserva y coordina el bloqueo temporal atómico de cupos (`SETNX`). | Java 21 · Spring Boot 3.3 · JPA · Redis · SQS |
| **`ms-pagos`** | `8084` | `db_pagos` (PostgreSQL) | Procesamiento seguro de cobros, tokenización de tarjetas de crédito y conciliación (normativa PCI DSS). | Java 21 · Spring Boot 3.3 · JPA · OpenAPI |
| **`ms-integraciones`** | `8085` | `db_integraciones` (PostgreSQL) | Conectores a APIs de proveedores externos (GDS, aerolíneas, hoteles) con resiliencia (**Circuit Breaker**). | Java 21 · Spring Boot 3.3 · JPA · Resilience4j |
| **`ms-fidelizacion`** | `8086` | `db_fidelizacion` (PostgreSQL) | Administración de puntos y millas de viajero frecuente, categorías de socio (Silver, Gold, Platinum) y canjes. | Java 21 · Spring Boot 3.3 · JPA · EventBridge |
| **`ms-notificaciones`** | `8087` | Stateless | Despacho multicanal de confirmaciones de compra, vouchers PDF con código QR e itinerarios de viaje por correo y push. | Java 21 · Spring Boot 3.3 · SES / SNS |

---

## 🗺️ 3. Diagramas de Arquitectura y Especificación Cloud

Todos los diagramas oficiales de arquitectura se encuentran documentados y versionados en la carpeta **[`entrega/`](entrega/README.md)**:

### 📐 Modelo C4
- **[C4 Nivel 1: Contexto del Sistema](entrega/c4/C4-1-Contexto.png)** (`entrega/c4/C4-1-Contexto.puml`) — Actores, límites del sistema y dependencias externas.
- **[C4 Nivel 2: Contenedores](entrega/c4/C4-2-Contenedores.png)** (`entrega/c4/C4-2-Contenedores.puml`) — Los 7 microservicios, bases de datos aisladas, colas SQS, bus EventBridge y cachés.
- **[C4 Nivel 3: Componentes ms-reservas](entrega/c4/C4-3-Componentes.png)** (`entrega/c4/C4-3-Componentes.puml`) — Arquitectura interna del microservicio transaccional.
- **[C4 Nivel 4: Flujo Dinámico Crítico](entrega/c4/C4-4-Dinamico.png)** (`entrega/c4/C4-4-Dinamico.puml`) — Flujo numerado paso a paso desde la búsqueda hasta la emisión final.

### ☁️ Infraestructura Cloud AWS
- **[Infraestructura AWS Multi-AZ](entrega/infraestructura/Infra-AWS.png)** (`entrega/infraestructura/Infra-AWS.puml`) — Despliegue en AWS (us-east-1), ECS Fargate, Aurora Serverless, Redis, SQS, EventBridge, Lambda, **Seguridad en rojo (IE7)** y **Monitoreo en azul (IE8)**.
- **[Topología de Red VPC](entrega/infraestructura/Infra-Red.png)** (`entrega/infraestructura/Infra-Red.puml`) — Segmentación en 3 Zonas de Disponibilidad (AZs), subredes públicas y privadas, NAT Gateways y VPC Endpoints.
- **[Pipeline CI/CD Blue/Green](entrega/infraestructura/Infra-CICD.png)** (`entrega/infraestructura/Infra-CICD.puml`) — Integración y despliegue continuo con Quality Gates y despliegue Zero-Downtime en ECS Fargate.

---

## 🛠️ 4. Requisitos y Ejecución Local

### Prerrequisitos
- **Java 21** (OpenJDK 21 / 25 LTS).
- **Maven 3.9+**.
- **Docker** y **Docker Compose**.

### Compilación y Pruebas
Para compilar y ejecutar las pruebas unitarias y BDD (Cucumber) de cualquier microservicio:

```bash
cd ms/reservas
mvn clean verify
```

### Ejecución Local con Docker Compose
Cada microservicio incluye su propio `docker-compose.yml` para levantar la aplicación junto a su base de datos PostgreSQL dedicada:

```bash
cd ms/reservas
docker compose up -d --build
```

---

## 📊 5. Matriz de Cumplimiento de Rúbrica (Duoc UC — EP01)

| Indicador | Descripción | Implementación en ViajaMejor |
|---|---|---|
| **IE1 & IE2** | Requisitos Funcionales y No Funcionales | 8 RF y 6 RNF medibles (Escalabilidad, Disponibilidad 99.95%, Latencia p95 < 2s, Integridad). |
| **IE3** | Microservicios vs Monolito | Justificado por escalabilidad asimétrica de búsquedas (20x) y aislamiento PCI DSS en pagos. |
| **IE4, IE5, IE6** | Diagramas de Arquitectura y Patrones | Modelo C4 completo + Patrones Cloud (API Gateway, Circuit Breaker, SQS DLQ, EventBridge, Redis Cache-Aside). |
| **IE7** | Políticas de Seguridad | Señalado en **ROJO** en diagramas: Cognito JWT, AWS WAF anti-bot, cifrado at-rest KMS y Secrets Manager. |
| **IE8** | Flujo Crítico y Monitoreo | Señalado en **AZUL** en diagramas: Trazas distribuidas AWS X-Ray, métricas CloudWatch y auditoría CloudTrail. |
| **IE9, IE10, IE11** | Delimitación de Servicios y Bajo Acoplamiento | 7 microservicios desacoplados con bases de datos independientes (Database-per-Service) y comunicación asíncrona. |

---

## 👥 6. Identificación del Proyecto
- **Estudiante**: Andrés
- **Asignatura**: Java: Diseño y Construcción de Soluciones Nativas en Nube (JVY0101)
- **Docente**: Mauricio Andrés Velásquez Silva
- **Institución**: Duoc UC
