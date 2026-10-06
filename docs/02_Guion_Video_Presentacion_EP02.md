# Guion Oficial del Video de Presentación — Evaluación Parcial N°2 (JVY0101)

**Asignatura:** Java: Diseño y Construcción de Soluciones Nativas en Nube (JVY0101)  
**Institución:** Duoc UC — Carrera Ingeniería en Informática  
**Caso:** 06 — ViajaMejor  
**Estudiante:** Andrés Osorio Escobar  
**Docente:** Mauricio Andrés Velásquez Silva  
**Duración Objetivo:** 5 a 6 minutos (Rango permitido: 3 a 8 minutos)  
**Formato de Entrega:** Archivo de video MP4 o enlace a video en AVA  

---

## Recomendaciones Previas de Grabación (IE12)
1. **Micrófono y Audio:** Grabar en un ambiente silencioso utilizando audífonos con micrófono. Hablar a volumen constante, pausado y con modulación clara.
2. **Resolución de Pantalla:** Grabar a 1080p (Full HD) con el tamaño de letra de VS Code / Postman aumentado (Zoom al 110% o 120%) para que los códigos y comandos sean perfectamente legibles.
3. **Ventanas Preparadas:**
   - Terminal / PowerShell.
   - VS Code con el proyecto abierto.
   - Postman con la colección `ViajaMejor EP02 — JVY0101` importada.
   - DBeaver o terminal conectada a MySQL en Docker (`docker exec -it viajamejor-mysql mysql -uroot -proot`).

---

## Estructura Cronológica del Video (IE11)

### Bloque 1: Introducción y Contexto del Proyecto (0:00 - 0:45) — IE11
* **Qué mostrar en pantalla:** La portada del proyecto en GitHub o el archivo `README.md` en el navegador/VS Code.
* **Qué decir:**
  > *"Estimado profesor Mauricio Velásquez y presentes. Mi nombre es Andrés Osorio Escobar, estudiante de Ingeniería en Informática de Duoc UC. A continuación presento la Evaluación Parcial N°2 de la asignatura Java: Diseño y Construcción de Soluciones Nativas en Nube.*  
  > *Nuestro caso asignado es ViajaMejor, una plataforma de agencia de viajes en línea (OTA). Para esta evaluación hemos implementado los 7 microservicios de la solución: Usuarios, Búsqueda, Reservas, Pagos, Integraciones, Fidelización y Notificaciones. Todos desarrollados bajo arquitectura en capas con Spring Boot, persistencia relacional en MySQL con relaciones JPA, empaquetado Maven y pruebas completas en Postman."*

---

### Bloque 2: Clonación y Despliegue Local con Docker Compose (0:45 - 2:00) — IE10
* **Qué mostrar en pantalla:** Terminal de comandos (PowerShell / Bash).
* **Acciones en vivo:**
  1. Mostrar el comando de clonación:
     ```bash
     git clone https://github.com/BadPek/viajamejor-ep02.git
     cd viajamejor-ep02
     ```
  2. Levantar el ecosistema completo con Docker Compose:
     ```bash
     docker compose up -d --build
     ```
  3. Ejecutar `docker ps` para mostrar los contenedores arriba:
     - `viajamejor-mysql` (puerto 3306, estado healthy).
     - Los 7 microservicios en sus respectivos puertos (`8081` a `8087`).
* **Qué decir:**
  > *"Como se especifica en nuestro README.md, el proyecto cuenta con un archivo docker-compose.yml que orquesta tanto la base de datos relacional MySQL 8 como los 7 microservicios. Con solo ejecutar docker compose up --build, se construyen las imágenes multi-etapa y se levantan los servicios en los puertos 8081 al 8087, garantizando que cualquier evaluador pueda reproducir el entorno en minutos."*

---

### Bloque 3: Demostración en Postman y Manejo Global de Errores (2:00 - 3:45) — IE3, IE1
* **Qué mostrar en pantalla:** Postman con la colección `ViajaMejor EP02 — JVY0101`.
* **Acciones en vivo:**
  1. **Microservicio ms-reservas (puerto 8083):**
     - Ejecutar `POST /api/reservas` (Crear con items hijos): Mostrar respuesta **201 Created** con el ID generado y el array `items` persistido.
     - Ejecutar `GET /api/reservas/{id}`: Mostrar respuesta **200 OK** con los datos y sus relaciones.
     - Ejecutar `PUT /api/reservas/{id}`: Actualizar la reserva agregando un nuevo item (ej. Seguro de Viaje) y mostrar **200 OK**.
  2. **Demostración de Casos de Error:**
     - Ejecutar `POST /api/reservas` con `"nombre": ""`: Mostrar respuesta **400 Bad Request** con el JSON de error homogéneo emitido por `GlobalExceptionHandler` (timestamp, status, error, mensaje y detalle del campo con error).
     - Ejecutar `GET /api/reservas/9999`: Mostrar respuesta **404 Not Found**.
  3. Ejecutar una prueba rápida en otro servicio, por ejemplo `ms-usuarios` (`GET /api/usuarios` y `POST /api/usuarios` con dirección).
* **Qué decir:**
  > *"En Postman contamos con una colección con casos felices y de error para cada uno de los microservicios. Vemos aquí en ms-reservas cómo al enviar un POST creamos la reserva junto a su lista de items asociados, respondiendo HTTP 201 Created. Al consultar por ID obtenemos HTTP 200 OK. Y al enviar un campo obligatorio vacío, nuestro controlador global intercepta la excepción con @RestControllerAdvice y retorna un HTTP 400 Bad Request estandarizado con el detalle del campo inválido, cumpliendo las buenas prácticas RESTful."*

---

### Bloque 4: Base de Datos Relacional y Relaciones JPA (3:45 - 4:45) — IE4, IE5, IE6
* **Qué mostrar en pantalla:**
  1. En VS Code: Abrir `application-mysql.yml` y `pom.xml` de `ms-reservas` mostrando la URL de conexión JDBC y la dependencia `mysql-connector-j`.
  2. En VS Code: Abrir `Reserva.java` mostrando `@OneToMany` con `CascadeType.ALL` y `ItemReserva.java` con `@ManyToOne`.
  3. En consola o gestor de base de datos: Mostrar las tablas creadas en MySQL:
     ```sql
     SHOW DATABASES;
     USE reservasdb;
     SHOW TABLES;
     SELECT * FROM reservas;
     SELECT * FROM items_reserva;
     ```
* **Qué decir:**
  > *"En el código podemos evidenciar la configuración de persistencia: cada microservicio cuenta con un perfil application-mysql.yml que define la conexión JDBC y su driver en el pom.xml. A nivel de entidades JPA, implementamos relaciones bidireccionales OneToMany y ManyToOne con cascada completa y claves foráneas. Al consultar MySQL directamente, podemos verificar que los registros creados desde Postman se persistieron efectivamente en sus tablas padre e hijas con integridad referencial."*

---

### Bloque 5: Maven Build y Artefacto Ejecutable JAR (4:45 - 5:20) — IE7
* **Qué mostrar en pantalla:** Terminal de comandos dentro de la carpeta de un microservicio (ej. `ms/reservas`).
* **Acciones en vivo:**
  1. Ejecutar el comando Maven:
     ```bash
     mvn clean package -DskipTests
     ```
  2. Mostrar en pantalla la carpeta `target/` y el archivo generado:
     ```bash
     ls target/*.jar
     ```
  3. Ejecutar el jar generado directamente:
     ```bash
     java -jar target/reservas-svc-1.0.0.jar
     ```
* **Qué decir:**
  > *"Para el ciclo de vida y empaquetado, utilizamos Maven. Al ejecutar mvn clean package, el plugin spring-boot-maven-plugin genera el fat jar ejecutable en la carpeta target. Como demostramos en pantalla, este archivo .jar es totalmente autónomo y funcional para su despliegue en entornos productivos o contenedores."*

---

### Bloque 6: Control de Versiones Git y Conclusión (5:20 - 5:50) — IE9, IE11
* **Qué mostrar en pantalla:** Repositorio en GitHub mostrando las ramas (`main`, `develop`, `feature/*`) y el historial de commits.
* **Qué decir:**
  > *"Finalmente, el código se encuentra versionado en GitHub manteniendo un flujo de trabajo estructurado con ramas main, develop y ramas de características, respaldado por commits descriptivos. Con esto damos por cumplidos todos los requerimientos de la Evaluación Parcial N°2 para el caso ViajaMejor. Muchas gracias por su atención."*

---

## Resumen de Tiempos
- **Bloque 1:** Introducción (0:30 - 0:45)
- **Bloque 2:** Docker Compose y Clonación (1:15)
- **Bloque 3:** Pruebas Postman y Errores (1:45)
- **Bloque 4:** Base de Datos MySQL y JPA (1:00)
- **Bloque 5:** Maven y JAR (0:35)
- **Bloque 6:** Git y Cierre (0:30)
- **Tiempo Total Estimado:** ~5 minutos y 45 segundos.
