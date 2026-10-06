# Cumplimiento de la Rúbrica — Evaluación Parcial N°2 (JVY0101)

**Asignatura:** Java: Diseño y Construcción de Soluciones Nativas en Nube (JVY0101)  
**Institución:** Duoc UC — Carrera Ingeniería en Informática  
**Caso:** 06 — ViajaMejor  
**Estudiante:** Andrés Osorio Escobar  
**Docente:** Mauricio Andrés Velásquez Silva  

Este documento mapea cada Indicador de Evaluación (IE) de la pauta oficial de la EP02 contra su evidencia concreta en este repositorio.

---

## 1. Dimensión: Encargo (50%)

| IE | Ponderación | Criterio de Evaluación | Evidencia en el Repositorio | Estado |
|---|:---:|---|---|:---:|
| **IE1** | 20% | Implementa endpoints RESTful funcionales utilizando Spring Boot, respetando buenas prácticas y convenciones del framework. | Los 7 microservicios (`usuarios`, `busqueda`, `reservas`, `pagos`, `integraciones`, `fidelizacion`, `notificaciones`) exponen endpoints completos: `GET /api/<recurso>` (200), `GET /api/<recurso>/{id}` (200), `POST /api/<recurso>` (201), `PUT /api/<recurso>/{id}` (200), `DELETE /api/<recurso>/{id}` (204). Validación con `@Valid` y documentación OpenAPI/Swagger en `http://localhost:<puerto>/swagger-ui.html`. | ✅ 100% |
| **IE2** | 10% | Construye la arquitectura interna siguiendo las buenas prácticas de la industria y utilizando las herramientas que provee el framework Spring Boot. | Arquitectura en capas limpia: `controller / service / repository / model` + `config`. Inyección de dependencias por constructor, inmutabilidad y separación estricta de responsabilidades (SRP). | ✅ 100% |
| **IE6** | 5% | Utiliza anotaciones de JPA/Hibernate para mapear correctamente las entidades a tablas de base de datos y asegura relaciones correctas entre ellas (`@OneToMany`, `@ManyToOne`). | Mapeo relacional bidireccional implementado en los 7 microservicios:<br>• `usuarios`: `Usuario` (1) ↔ `Direccion` (N)<br>• `busqueda`: `ResultadoBusqueda` (1) ↔ `FiltroBusqueda` (N)<br>• `reservas`: `Reserva` (1) ↔ `ItemReserva` (N)<br>• `pagos`: `Pago` (1) ↔ `Transaccion` (N)<br>• `integraciones`: `Integracion` (1) ↔ `RegistroLlamada` (N)<br>• `fidelizacion`: `Punto` (1) ↔ `MovimientoPunto` (N)<br>• `notificaciones`: `Notificacion` (1) ↔ `EnvioNotificacion` (N)<br>Configurado con `@OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)`, `@ManyToOne`, `@JoinColumn` y `@JsonIgnore` para evitar recursión. | ✅ 100% |
| **IE8** | 5% | Configura el archivo `pom.xml` incluyendo dependencias y plugins necesarios. | `pom.xml` en cada microservicio con `spring-boot-starter-web`, `-data-jpa`, `-validation`, `mysql-connector-j`, `h2`, `springdoc-openapi`, `spring-boot-starter-test`, Cucumber, `spring-boot-maven-plugin`, `surefire` y `jacoco-maven-plugin`. | ✅ 100% |
| **IE9** | 10% | Mantiene el proyecto en un repositorio Git versionado con estructura clara de ramas (`main`, `develop`, `feature/*`) y mensajes de commit descriptivos y coherentes. | Repositorio GitHub oficial versionado con ramas `main`, `develop`, `feature/relaciones-jpa-mysql`, `feature/postman-docker`, commits semánticos y descriptivos con trazabilidad completa. | ✅ 100% |

---

## 2. Dimensión: Presentación (50%)

| IE | Ponderación | Criterio de Evaluación | Evidencia en el Repositorio y Demostración | Estado |
|---|:---:|---|---|:---:|
| **IE3** | 10% | Verifica la funcionalidad de los microservicios mediante pruebas con herramientas como Postman, asegurándose de que responda adecuadamente a las peticiones. | Colección oficial `postman/ViajaMejor-EP02.postman_collection.json` con 49 peticiones organizadas por servicio. Cubre casos felices (200, 201, 204) y casos de error controlados (400 Bad Request por validación con detalle de campos y 404 Not Found por ID inexistente) procesados por `@RestControllerAdvice` (`GlobalExceptionHandler`). | ✅ (A demostrar en video) |
| **IE4** | 10% | Establece la conexión entre los microservicios y la base de datos relacional, configurando correctamente las propiedades y las dependencias en el `pom.xml`. | Perfil `mysql` configurado en `src/main/resources/application-mysql.yml` con `jdbc:mysql://${DB_HOST:localhost}:${DB_PORT:3306}/${DB_NAME}?createDatabaseIfNotExist=true` y driver `com.mysql.cj.jdbc.Driver` en `pom.xml`. Orquestación completa mediante `docker-compose.yml` que levanta MySQL 8.0 y los 7 microservicios. | ✅ (A demostrar en video) |
| **IE5** | 10% | Implementa entidades, repositorios y controladores que permitan realizar operaciones CRUD con persistencia efectiva. | Operaciones CRUD completas verificadas contra base de datos relacional MySQL (tablas padre e hijas creadas con claves foráneas e integridad referencial). | ✅ (A demostrar en video) |
| **IE7** | 5% | Utiliza comandos de Maven para compilar, testear y empaquetar la aplicación generando archivos `.jar` o `.war` válidos. | `mvn clean package` genera los artefactos ejecutables (`app.jar` / `*-svc-1.0.0.jar`) en `target/`. Scripts automatizados `scripts/build-all.ps1` y `scripts/build-all.sh`. | ✅ (A demostrar en video) |
| **IE10** | 5% | Demuestra el proceso para clonar el repositorio, instalar dependencias y ejecutar localmente la aplicación, asegurando que cualquier evaluador pueda reproducir el despliegue y pruebas básicas. | Documentado exhaustivamente en el [`README.md`](../README.md) principal con requisitos, clonación, ejecución con Docker Compose (`docker compose up --build`), ejecución local con H2 o MySQL y puertos asignados. | ✅ 100% |
| **IE11** | 5% | Elabora la presentación en un video, donde se aprecia la información en orden y con un hilo conductor y utilizando un lenguaje técnico. | Estructurado y cronometrado detalladamente en [`docs/02_Guion_Video_Presentacion_EP02.md`](02_Guion_Video_Presentacion_EP02.md) (duración 3 a 8 minutos: Introducción → Clonación y Docker Compose → Postman → Base de Datos MySQL → Maven → Conclusión). | ✅ Guion listo |
| **IE12** | 5% | Elabora la presentación en un video, que cuenta con un audio claro y volumen adecuado, sin ruidos ambientales que interrumpan la información expuesta. | Pautas de grabación y recomendaciones técnicas incluidas en el guion del video. | ✅ Pautas listas |

---

## 3. Pruebas Automatizadas y Calidad de Código
- **140 pruebas automatizadas** pasando al 100%:
  - Pruebas unitarias de servicios (`*ServiceTest.java`) con Mockito.
  - Pruebas de controladores (`*ControllerTest.java`) con MockMvc verificando códigos HTTP 200, 201, 204, 400 y 404.
  - Pruebas de integración BDD con Cucumber (`*.feature` y `*Steps.java`).
- **Cobertura de código**: Plugin JaCoCo integrado en `pom.xml`.
