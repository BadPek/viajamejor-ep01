# Guía de Creación y Subida de Repositorios en GitHub — ViajaMejor

Esta guía explica paso a paso cómo estructurar y subir los **7 microservicios** de **ViajaMejor (caso06)** a GitHub en **repositorios independientes**, cumpliendo estrictamente con las instrucciones de la evaluación EP01:

> *"Varios enlaces significa múltiples repositorios. Esto es coherente con la filosofía de microservicios. Idealmente, deben tener un repositorio por microservicio, de manera que cada uno pueda ser desarrollado, mantenido y desplegado de forma independiente."*

---

## 1. Estructura de Repositorios Sugerida

Para la entrega en AVA y correo al docente, se recomienda crear los siguientes 8 repositorios en GitHub:

| # | Nombre del Repositorio en GitHub | Carpeta Local | Descripción |
|---|---|---|---|
| 1 | `viajamejor-ms-usuarios` | `ms/usuarios` | Microservicio de gestión de perfiles e identidad |
| 2 | `viajamejor-ms-busqueda` | `ms/busqueda` | Microservicio agregador de búsquedas y tarifas |
| 3 | `viajamejor-ms-reservas` | `ms/reservas` | Microservicio transaccional del ciclo de vida de reservas |
| 4 | `viajamejor-ms-pagos` | `ms/pagos` | Microservicio de procesamiento seguro de pagos |
| 5 | `viajamejor-ms-integraciones` | `ms/integraciones` | Microservicio adaptador a proveedores externos (GDS) |
| 6 | `viajamejor-ms-fidelizacion` | `ms/fidelizacion` | Microservicio de administración y canje de puntos |
| 7 | `viajamejor-ms-notificaciones` | `ms/notificaciones` | Microservicio stateless de despacho de notificaciones |
| **8** | `viajamejor-arquitectura-entrega` | `caso06/caso06` | Repositorio central con diagramas C4/AWS, README maestro y guiones |

---

## 2. Opción Rápida: Script Automatizado en PowerShell

Hemos preparado un script PowerShell (`subir_repositorios.ps1`) en la raíz de `caso06/caso06`.

### Pasos para ejecutarlo:
1. Crea los repositorios vacíos en tu cuenta de GitHub (ej. `https://github.com/TU_USUARIO/viajamejor-ms-usuarios.git`, etc.).
2. Abre una terminal de PowerShell en `caso06/caso06`.
3. Ejecuta el script indicando tu usuario de GitHub:
   ```powershell
   .\subir_repositorios.ps1 -GithubUser "TU_USUARIO_GITHUB"
   ```
El script inicializará `git init`, agregará todos los archivos, creará el commit inicial en la rama `main` y configurará el origen remoto para cada microservicio automáticamente.

---

## 3. Opción Manual: Paso a Paso por Microservicio

Si prefieres hacerlo manualmente para cada microservicio:

### Ejemplo con `ms-reservas`:
```bash
# 1. Entrar a la carpeta del microservicio
cd "caso06/caso06/ms/reservas"

# 2. Inicializar repositorio Git local
git init
git branch -M main

# 3. Agregar archivos y hacer el primer commit
git add .
git commit -m "feat: inicializacion de ms-reservas (Java 21, Spring Boot 3.3, JPA, OpenAPI, BDD Cucumber y Docker)"

# 4. Vincular con tu repositorio de GitHub (reemplaza TU_USUARIO)
git remote add origin https://github.com/TU_USUARIO/viajamejor-ms-reservas.git

# 5. Subir a GitHub
git push -u origin main
```

*(Repetir este procedimiento para `usuarios`, `busqueda`, `pagos`, `integraciones`, `fidelizacion` y `notificaciones`).*

---

## 4. Subida del Repositorio de Arquitectura y Documentación General

Para el repositorio maestro de entrega (`viajamejor-arquitectura-entrega`):

```bash
cd "caso06/caso06"
git init
git branch -M main
git add .
git commit -m "docs: entrega EP01 ViajaMejor - diagramas C4, arquitectura AWS multi-AZ, justificacion y guion"
git remote add origin https://github.com/TU_USUARIO/viajamejor-arquitectura-entrega.git
git push -u origin main
```

---

## 5. Formato de Entrega para AVA y Correo al Docente

Al momento de entregar en la plataforma AVA y enviar copia al correo del docente, copia y pega la siguiente plantilla:

```text
Estimado/a Docente:

Adjuntamos la entrega de la Evaluación Parcial N°1 (EP01) correspondiente al Caso 06: ViajaMejor.

Integrantes:
- Andrés [Apellido]
- Catalina [Apellido]

1. Repositorio Central de Arquitectura y Diagramas:
   - https://github.com/TU_USUARIO/viajamejor-arquitectura-entrega

2. Repositorios de Código Fuente de los 7 Microservicios (Bajo Acoplamiento):
   - ms-usuarios:       https://github.com/TU_USUARIO/viajamejor-ms-usuarios
   - ms-busqueda:       https://github.com/TU_USUARIO/viajamejor-ms-busqueda
   - ms-reservas:       https://github.com/TU_USUARIO/viajamejor-ms-reservas
   - ms-pagos:          https://github.com/TU_USUARIO/viajamejor-ms-pagos
   - ms-integraciones:  https://github.com/TU_USUARIO/viajamejor-ms-integraciones
   - ms-fidelizacion:   https://github.com/TU_USUARIO/viajamejor-ms-fidelizacion
   - ms-notificaciones: https://github.com/TU_USUARIO/viajamejor-ms-notificaciones

3. Diagramas de Arquitectura (Imágenes exportadas adjuntas):
   - C4 Nivel 1: Contexto del Sistema
   - C4 Nivel 2: Contenedores y Microservicios
   - C4 Nivel 3: Componentes de ms-reservas
   - C4 Nivel 4: Flujo Dinámico Crítico
   - Infraestructura Cloud AWS (Multi-AZ, Seguridad IE7 y Monitoreo IE8)
   - Topología de Red VPC Segmentada por Capas
   - Pipeline CI/CD con Despliegue Blue/Green

4. Enlace al Video de Presentación (si aplica):
   - [Enlace a YouTube / OneDrive / Drive]

Saludos cordiales,
Andrés y Catalina
```
