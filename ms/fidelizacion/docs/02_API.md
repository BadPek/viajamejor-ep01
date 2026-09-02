# Fidelización — Contrato de la API REST

## Base

- **Base path**: `/api/puntos`
- **Formato**: JSON — **Puerto**: 8080 (configurable con `PORT`)

## Recursos

| Método | Ruta | Códigos de estado | Descripción |
|--------|------|-------------------|-------------|
| GET | `/api/puntos` | 200 | Lista todos los recursos |
| GET | `/api/puntos/{id}` | 200 / 404 | Obtiene un recurso por id |
| POST | `/api/puntos` | 201 / 400 | Crea un recurso |
| PUT | `/api/puntos/{id}` | 200 / 404 / 400 | Actualiza un recurso |
| DELETE | `/api/puntos/{id}` | 204 / 404 | Elimina un recurso |

## Atributos de un recurso

| Campo | Tipo | Obligatorio | Descripción |
|-------|------|-------------|-------------|
| id | Long | - | Identificador autogenerado |
| nombre | String | Sí | Nombre del recurso |

| viajero | String | No | Campo del dominio |
| puntos | BigDecimal | No | Campo del dominio |

## Ejemplos con curl

```bash
# Listar
curl http://localhost:8080/api/puntos

# Crear
curl -X POST http://localhost:8080/api/puntos \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Mi recurso"}'

# Obtener por id
curl http://localhost:8080/api/puntos/1

# Actualizar
curl -X PUT http://localhost:8080/api/puntos/1 \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Recurso actualizado"}'

# Eliminar
curl -X DELETE http://localhost:8080/api/puntos/1
```
