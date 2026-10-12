# ViajaMejor — Plataforma de Microservicios Cloud Native (OTA)

> **Plataforma de Reservas y Gestión Turística Multimodal — ViajaMejor**  
> **Duoc UC — Carrera Ingeniería en Informática**  
> **Estudiante:** Andrés Osorio Escobar  
> **Docente:** Mauricio Andrés Velásquez Silva  

Este repositorio contiene la implementación de los **7 microservicios Spring Boot** que componen el ecosistema de la agencia de viajes en línea **ViajaMejor (Caso 06)**. Cada microservicio cuenta con arquitectura limpia en capas, persistencia relacional con **relaciones JPA (`@OneToMany` / `@ManyToOne`)**, perfiles duales de ejecución (**H2 en memoria y MySQL 8**), manejo global estandarizado de excepciones, suite de pruebas en **Postman**, empaquetado Maven y orquestación con **Docker Compose**.

---

## 1. Estructura del Repositorio

```text
caso06/
├── docker-compose.yml              # Orquestador: MySQL 8.0 + los 7 microservicios
├── README.md                       # Guía de ejecución y documentación principal
├── postman/
│   └── ViajaMejor-EP02.postman_collection.json  # 49 pruebas de endpoints (casos exitosos y de error)
├── scripts/
│   ├── build-all.ps1 / build-all.sh             # Compilación y empaquetado JAR de todos los servicios
│   └── test-all.ps1 / test-all.sh               # Ejecución de pruebas automatizadas y cobertura JaCoCo
├── entrega/                                     # Diagramas de Arquitectura C4 e Infraestructura AWS Multi-AZ
│   ├── c4/
│   └── infraestructura/
└── ms/
    ├── usuarios/                   # /api/usuarios       (Puerto 8081)
    ├── busqueda/                   # /api/busqueda       (Puerto 8082)
    ├── reservas/                   # /api/reservas       (Puerto 8083)
    ├── pagos/                      # /api/pagos          (Puerto 8084)
    ├── integraciones/              # /api/integraciones  (Puerto 8085)
    ├── fidelizacion/               # /api/fidelizacion   (Puerto 8086)
    └── notificaciones/             # /api/notificaciones (Puerto 8087)
```

---

## 2. Microservicios y Modelo de Datos JPA

Cada microservicio implementa una arquitectura en capas (`controller / service / repository / model / config`) con inyección de dependencias por constructor y relaciones bidireccionales JPA con integridad referencial:

| Microservicio | Puerto | Endpoint Base | Entidad Principal | Entidad Relacionada (`@OneToMany`) | Base de Datos |
|---|:---:|---|---|---|---|
| **`ms-usuarios`** | `8081` | `/api/usuarios` | `Usuario` | `Direccion` (`usuario_id`) | `usuariosdb` |
| **`ms-busqueda`** | `8082` | `/api/busqueda` | `ResultadoBusqueda` | `FiltroBusqueda` (`resultado_id`) | `busquedadb` |
| **`ms-reservas`** | `8083` | `/api/reservas` | `Reserva` | `ItemReserva` (`reserva_id`) | `reservasdb` |
| **`ms-pagos`** | `8084` | `/api/pagos` | `Pago` | `Transaccion` (`pago_id`) | `pagosdb` |
| **`ms-integraciones`** | `8085` | `/api/integraciones` | `Integracion` | `RegistroLlamada` (`integracion_id`) | `integracionesdb` |
| **`ms-fidelizacion`** | `8086` | `/api/fidelizacion` | `Punto` | `MovimientoPunto` (`punto_id`) | `fidelizaciondb` |
| **`ms-notificaciones`** | `8087` | `/api/notificaciones` | `Notificacion` | `EnvioNotificacion` (`notificacion_id`) | `notificacionesdb` |

---

## 3. Guía de Despliegue y Ejecución Local

### Prerrequisitos
- **Java 21 / 22 LTS**
- **Maven 3.9+**
- **Docker y Docker Compose**

---

### Opción A: Despliegue con Docker Compose (Recomendado)

Levanta la base de datos MySQL 8.0 y los 7 microservicios de forma orquestada:

```bash
docker compose up -d --build
```

Esto compilará las imágenes multi-etapa de cada servicio, inicializará el contenedor MySQL con verificación de salud (`healthcheck`) y creará las bases de datos automáticamente.

#### Verificación de Contenedores:
```bash
docker ps
```

#### Documentación Swagger / OpenAPI:
Cada microservicio expone su interfaz Swagger UI para exploración interactiva:
- `http://localhost:8081/swagger-ui.html` (Usuarios)
- `http://localhost:8082/swagger-ui.html` (Búsqueda)
- `http://localhost:8083/swagger-ui.html` (Reservas)
- `http://localhost:8084/swagger-ui.html` (Pagos)
- `http://localhost:8085/swagger-ui.html` (Integraciones)
- `http://localhost:8086/swagger-ui.html` (Fidelización)
- `http://localhost:8087/swagger-ui.html` (Notificaciones)

#### Detener el Entorno:
```bash
docker compose down
```
*(Para reiniciar el volumen persistente de base de datos: `docker compose down -v`)*

---

### Opción B: Ejecución Local por Microservicio

#### 1. Modo H2 en Memoria (Perfil por Defecto):
```bash
cd ms/reservas
mvn spring-boot:run
```
Acceso a la consola H2: `http://localhost:8080/h2-console` (JDBC URL: `jdbc:h2:mem:reservasdb`, Usuario: `sa`).

#### 2. Modo MySQL Local:
```bash
cd ms/reservas
SPRING_PROFILES_ACTIVE=mysql DB_HOST=localhost DB_NAME=reservasdb mvn spring-boot:run
```

---

## 4. Pruebas de Endpoints con Postman

Se incluye la colección oficial en [`postman/ViajaMejor-EP02.postman_collection.json`](postman/ViajaMejor-EP02.postman_collection.json) con **49 solicitudes** organizadas por dominio funcional:

1. **Casos Exitosos (200 / 201 / 204):**
   - Listar todos los registros (`GET /api/<recurso>`).
   - Crear registro con entidades hijas en cascada (`POST /api/<recurso>`).
   - Consultar por ID (`GET /api/<recurso>/{id}`).
   - Actualizar registro y reemplazar elementos hijos (`PUT /api/<recurso>/{id}`).
   - Eliminar por ID (`DELETE /api/<recurso>/{id}`).
2. **Casos de Error Controlados (400 / 404):**
   - Error de validación al enviar campos requeridos vacíos (`POST` -> `400 Bad Request` con detalle del campo).
   - Error al consultar recursos inexistentes (`GET /api/<recurso>/9999` -> `404 Not Found`).

Todas las respuestas de error son procesadas de manera uniforme mediante `@RestControllerAdvice` (`GlobalExceptionHandler.java`):
```json
{
  "timestamp": "2026-10-12T12:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Error de validación",
  "details": {
    "nombre": "El nombre es obligatorio"
  }
}
```

---

## 5. Ciclo de Vida y Empaquetado Maven

### Generación del Artefacto JAR:
Para compilar y empaquetar un microservicio generando el archivo JAR ejecutable:
```bash
cd ms/reservas
mvn clean package -DskipTests
```
El archivo JAR ejecutable se genera en:
```text
ms/reservas/target/reservas-svc-1.0.0.jar
```

### Ejecución Directa del Artefacto JAR:
```bash
java -jar target/reservas-svc-1.0.0.jar
```

### Ejecución de Pruebas y Cobertura:
```bash
mvn test
```
*(140 pruebas automáticas unitarias, MockMvc y BDD Cucumber pasan al 100%)*.

---

## 6. Arquitectura del Sistema

Los diagramas de arquitectura C4 (Contexto, Contenedores, Componentes y Flujo Dinámico) y la topología de nube AWS Multi-AZ se encuentran detallados en:
- **[Documentación y Diagramas de Arquitectura (C4 e Infra-AWS)](entrega/README.md)**
