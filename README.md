# ViajaMejor — Evaluación Parcial N°2 (JVY0101)

> **Evaluación Parcial N°2 (EP02) — Asignatura: Java: Diseño y Construcción de Soluciones Nativas en Nube (JVY0101)**  
> **Duoc UC — Carrera Ingeniería en Informática**  
> **Caso 06: ViajaMejor**  
> **Estudiante:** Andrés Osorio Escobar  
> **Docente:** Mauricio Andrés Velásquez Silva  

Este repositorio contiene la implementación completa de los **7 microservicios Spring Boot** de la plataforma de viajes **ViajaMejor (Caso 06)** para la Evaluación Parcial N°2. Cada microservicio cuenta con arquitectura en capas, persistencia relacional con **relaciones JPA (`@OneToMany` / `@ManyToOne`)**, perfiles duales **H2 / MySQL**, manejo global homogéneo de excepciones, colección de pruebas en **Postman**, empaquetado Maven y orquestación con **Docker Compose**.

---

## 1. Estructura del Repositorio

```text
caso06/
├── docker-compose.yml              # Orquestador: MySQL 8.0 + los 7 microservicios
├── README.md                       # Guía de ejecución y documentación principal
├── postman/
│   └── ViajaMejor-EP02.postman_collection.json  # 49 peticiones (casos felices y de error)
├── docs/
│   ├── 01_Cumplimiento_Rubrica_EP02.md          # Mapeo indicador por indicador (IE1 a IE12)
│   └── 02_Guion_Video_Presentacion_EP02.md      # Guion paso a paso para el video (3-8 min)
├── scripts/
│   ├── build-all.ps1 / build-all.sh             # Compilación y empaquetado JAR de todos los servicios
│   └── test-all.ps1 / test-all.sh               # Ejecución de pruebas y validación JaCoCo
├── entrega/                                     # Diagramas de Arquitectura C4 e Infraestructura AWS (EP01)
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

## 2. Microservicios y Mapeo Relacional JPA (IE1, IE2, IE6)

Cada microservicio implementa una arquitectura en capas (`controller / service / repository / model` + `config`) con inyección de dependencias por constructor y relaciones bidireccionales JPA:

| Microservicio | Puerto | Endpoint Base | Entidad Padre | Entidad Hija (`@OneToMany`) | Base de Datos |
|---|:---:|---|---|---|---|
| **`ms-usuarios`** | `8081` | `/api/usuarios` | `Usuario` | `Direccion` (`usuario_id`) | `usuariosdb` |
| **`ms-busqueda`** | `8082` | `/api/busqueda` | `ResultadoBusqueda` | `FiltroBusqueda` (`resultado_id`) | `busquedadb` |
| **`ms-reservas`** | `8083` | `/api/reservas` | `Reserva` | `ItemReserva` (`reserva_id`) | `reservasdb` |
| **`ms-pagos`** | `8084` | `/api/pagos` | `Pago` | `Transaccion` (`pago_id`) | `pagosdb` |
| **`ms-integraciones`** | `8085` | `/api/integraciones` | `Integracion` | `RegistroLlamada` (`integracion_id`) | `integracionesdb` |
| **`ms-fidelizacion`** | `8086` | `/api/fidelizacion` | `Punto` | `MovimientoPunto` (`punto_id`) | `fidelizaciondb` |
| **`ms-notificaciones`** | `8087` | `/api/notificaciones` | `Notificacion` | `EnvioNotificacion` (`notificacion_id`) | `notificacionesdb` |

---

## 3. Guía de Ejecución Rápida (IE10)

### Prerrequisitos
- **Java 21 / 22 LTS**.
- **Maven 3.9+**.
- **Docker y Docker Compose**.

---

### Opción A: Despliegue con Docker Compose (Recomendado)

Levanta MySQL 8.0 y los 7 microservicios con un solo comando:

```bash
docker compose up -d --build
```

Esto compilará las imágenes de cada servicio, inicializará el contenedor MySQL con healthcheck y creará las bases de datos de forma automática.

#### Verificación de Contenedores:
```bash
docker ps
```

#### Documentación Swagger / OpenAPI:
Cada microservicio expone su interfaz Swagger en:
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
*(Para borrar datos y reiniciar el volumen de MySQL: `docker compose down -v`)*

---

### Opción B: Ejecución Local por Microservicio

#### 1. Modo H2 en Memoria (Perfil por Defecto, sin dependencias externas):
```bash
cd ms/reservas
mvn spring-boot:run
```
Acceso a la consola H2: `http://localhost:8080/h2-console` (JDBC URL: `jdbc:h2:mem:reservasdb`, Usuario: `sa`, Contraseña vacía).

#### 2. Modo MySQL Local:
```bash
cd ms/reservas
SPRING_PROFILES_ACTIVE=mysql DB_HOST=localhost DB_NAME=reservasdb mvn spring-boot:run
```

---

## 4. Pruebas de Endpoints con Postman (IE3)

Se incluye una colección completa en [`postman/ViajaMejor-EP02.postman_collection.json`](postman/ViajaMejor-EP02.postman_collection.json) con **49 solicitudes** que cubren:
1. **Casos Exitosos (200 / 201 / 204):**
   - Listar todos los registros (`GET /api/<recurso>`).
   - Crear registro con entidades hijas en cascada (`POST /api/<recurso>`).
   - Consultar por ID (`GET /api/<recurso>/{id}`).
   - Actualizar registro y reemplazar elementos hijos (`PUT /api/<recurso>/{id}`).
   - Eliminar por ID (`DELETE /api/<recurso>/{id}`).
2. **Casos de Error Controlados (400 / 404):**
   - Error de validación con campos obligatorios vacíos (`POST` con nombre vacío -> `400 Bad Request` con detalle del campo).
   - Error por consulta de ID inexistente (`GET /api/<recurso>/9999` -> `404 Not Found`).

Todas las respuestas de error son estandarizadas por `@RestControllerAdvice` (`GlobalExceptionHandler.java`):
```json
{
  "timestamp": "2026-10-06T20:00:00Z",
  "status": 400,
  "error": "Bad Request",
  "message": "Error de validación",
  "details": {
    "nombre": "El nombre es obligatorio"
  }
}
```

---

## 5. Ciclo de Vida y Empaquetado Maven (IE7, IE8)

### Generación del Artefacto JAR:
Para compilar y empaquetar un microservicio generando el fat-jar ejecutable:
```bash
cd ms/reservas
mvn clean package -DskipTests
```
El archivo JAR ejecutable se generará en:
```text
ms/reservas/target/reservas-svc-1.0.0.jar
```

### Ejecutar el Archivo JAR Directamente:
```bash
java -jar target/reservas-svc-1.0.0.jar
```

### Ejecución de Pruebas y Cobertura JaCoCo:
```bash
mvn test
```
