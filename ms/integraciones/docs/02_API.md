# Integraciones — Contrato de la API REST

## Base

- **Base path**: `/api/integraciones`
- **Formato**: JSON — **Puerto**: 8080 (configurable con `PORT`)

## Recursos

| Método | Ruta | Códigos de estado | Descripción |
|--------|------|-------------------|-------------|
| GET | `/api/integraciones` | 200 | Lista todos los recursos |
| GET | `/api/integraciones/{id}` | 200 / 404 | Obtiene un recurso por id |
| POST | `/api/integraciones` | 201 / 400 | Crea un recurso |
| PUT | `/api/integraciones/{id}` | 200 / 404 / 400 | Actualiza un recurso |
| DELETE | `/api/integraciones/{id}` | 204 / 404 | Elimina un recurso |

## Atributos de un recurso

| Campo | Tipo | Obligatorio | Descripción |
|-------|------|-------------|-------------|
| id | Long | - | Identificador autogenerado |
| nombre | String | Sí | Nombre del recurso |

| proveedor | String | No | Campo del dominio |
| estado | String | No | Campo del dominio |

## Ejemplos con curl

```bash
# Listar
curl http://localhost:8080/api/integraciones

# Crear
curl -X POST http://localhost:8080/api/integraciones \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Mi recurso"}'

# Obtener por id
curl http://localhost:8080/api/integraciones/1

# Actualizar
curl -X PUT http://localhost:8080/api/integraciones/1 \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Recurso actualizado"}'

# Eliminar
curl -X DELETE http://localhost:8080/api/integraciones/1
```
