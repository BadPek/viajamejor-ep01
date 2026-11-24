# Cluster Docker Swarm — ViajaMejor

Documentacion tecnica y scripts de operacion del cluster **Docker Swarm** (arquitectura **Manager + Workers**) para el despliegue de los 7 microservicios de ViajaMejor con alta disponibilidad, balanceo de carga interno (Routing Mesh) y actualizaciones sin tiempo de inactividad.

---

## 1. Arquitectura del Cluster

```text
                       ┌───────────────────────────────────────┐
  Trafico Externo ────▶│  Swarm Ingress Routing Mesh           │
  (API Gateway / HTTP) │  Puertos publicados: 8081 - 8087      │
                       └──────────┬──────────────────┬─────────┘
                                  │                  │
                    ┌─────────────▼─────────┐  ┌─────▼─────────────────┐
                    │   Nodo MANAGER        │  │   Nodo(s) WORKER      │
                    │  (Control Plane +     │  │  (Data Plane)         │
                    │   MySQL + Replicas)   │  │                       │
                    │  - mysql (1 replica)  │  │  - reservas (rep #2)  │
                    │  - reservas (rep #1)  │  │  - busqueda (rep #2)  │
                    │  - busqueda (rep #1)  │  │  - usuarios (rep #2)  │
                    │  - usuarios (rep #1)  │  │  - notificaciones(#2) │
                    │  - notificaciones(#1) │  │  - pagos / otros      │
                    └─────────────┬─────────┘  └─────┬─────────────────┘
                                  └────────┬─────────┘
                                           ▼
                            Red Overlay: viajamejor-overlay
```

### Decisiones de Diseno (Conectadas a Requisitos de ViajaMejor)
- **Escalabilidad (picos de busquedas y CyberDays):** los servicios criticos (`usuarios`, `busqueda`, `reservas`, `notificaciones`) operan en modo `replicated` con `placement.preferences: spread: node.id`, distribuyendo las replicas equitativamente entre nodos Manager y Worker, y permitiendo escalar al vuelo con `docker service scale`.
- **Disponibilidad:** politica `restart_policy: on-failure`, healthchecks HTTP contra `/actuator/health`, y `update_config` con estrategia `order: start-first` y `failure_action: rollback` automatico ante despliegues fallidos.
- **Seguridad y Mantenibilidad:** cero credenciales en `docker-compose.swarm.yml`; gestion mediante Docker Secrets (`db_root_password`) y variables de entorno inyectadas desde el pipeline CI/CD.

---

## 2. Puertos Requeridos entre Nodos (Security Group / Firewall)

| Puerto | Protocolo | Proposito |
|---|---|---|
| `22` | TCP | Administracion SSH y despliegue automatico desde GitHub Actions |
| `2377` | TCP | Comunicacion de gestion del cluster Swarm (Manager) |
| `7946` | TCP / UDP | Descubrimiento y comunicacion entre nodos (Gossip) |
| `4789` | UDP | Trafico de red Overlay (VXLAN) |
| `8081 - 8087` | TCP | Puertos publicados de los microservicios via Ingress Routing Mesh |

---

## 3. Inicializacion Paso a Paso

### Paso 1: Inicializar el Nodo Manager
```bash
export DB_PASSWORD="<clave-segura-mysql>"
bash swarm/init-manager.sh <IP_PRIVADA_MANAGER>
```
El script inicializa Swarm, crea el Docker Secret `db_root_password` e imprime el comando `docker swarm join` con el token de Worker.

### Paso 2: Unir Uno o Mas Nodos Worker
En cada nodo Worker (instancia EC2 o VM con Docker instalado):
```bash
bash swarm/join-worker.sh <SWARM_WORKER_TOKEN> <IP_PRIVADA_MANAGER>
```

### Paso 3: Verificar los Nodos del Cluster
En el nodo Manager:
```bash
docker node ls
```
Debe mostrar al menos 1 nodo `Leader` (Manager) y 1 o mas nodos en estado `Ready / Active` (Worker).

### Paso 4: Desplegar el Stack Completo
```bash
export DB_PASSWORD="<clave-segura-mysql>"
export DOCKER_REGISTRY="ghcr.io/badpek"
export IMAGE_TAG="latest"
# Opcional: conectar a Amazon RDS y colas SQS
# export DB_HOST="<endpoint-rds>"
# export SQS_RESERVAS_QUEUE_URL="<url-cola-reservas>"
# export SQS_NOTIFICACIONES_QUEUE_URL="<url-cola-notificaciones>"

bash swarm/deploy-stack.sh
```

---

## 4. Verificacion Multi-Nodo y Escalado Dinamico

### Ver servicios desplegados y sus replicas
```bash
docker stack services viajamejor
```

### Confirmar que las replicas corren en distintos nodos
```bash
docker service ps viajamejor_reservas
```

### Escalar dinamicamente y validar disponibilidad + balanceo
```bash
# Escalado manual
docker service scale viajamejor_reservas=4
docker service ps viajamejor_reservas

# Verificar respuesta y header X-Instance-Host rotando entre replicas
curl -i http://<MANAGER_IP>:8083/api/reservas

# Reducir replicas sin perder disponibilidad
docker service scale viajamejor_reservas=2
```
Tambien puede ejecutarse la demostracion automatizada completa:
```bash
TARGET_HOST=<MANAGER_IP> bash swarm/scale-demo.sh
```

### Remover el stack
```bash
docker stack rm viajamejor
```
