# InnSight

![CI](https://github.com/arthurgtp/InnSight/actions/workflows/ios-ci.yml/badge.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![Python](https://img.shields.io/badge/Python-3.11-blue?logo=python)
![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Minikube-326CE5?logo=kubernetes)
![Helm](https://img.shields.io/badge/Helm-v4-0F1689?logo=helm)
![Platform](https://img.shields.io/badge/Platform-iOS-black?logo=apple)

InnSight es una aplicación móvil desarrollada en SwiftUI que permite la gestión y reservación de hoteles. Diseñada para dos tipos de usuarios: **clientes** y **administradores**.

---

## Tabla de contenidos

1. [Funcionalidades](#funcionalidades)
2. [Tecnologías](#tecnologías)
3. [Arquitectura del proyecto](#arquitectura-del-proyecto)
4. [Pipeline DevOps](#pipeline-devops)
5. [Estrategia de ramas (Git Flow)](#estrategia-de-ramas-git-flow)
6. [Backend API REST (Flask)](#backend-api-rest-flask)
7. [Docker](#docker)
8. [Kubernetes](#kubernetes)
9. [Helm](#helm)
10. [Base de datos](#base-de-datos)
11. [Instalación](#instalación)
12. [Autor](#autor)

---

## Funcionalidades

### Cliente
- Ver lista de hoteles disponibles
- Visualizar habitaciones disponibles por hotel
- Ver imágenes 360° de habitaciones
- Reservar habitaciones
- Consultar reservas activas, canceladas y completadas

### Administrador
- Agregar y editar hoteles y habitaciones
- Eliminar habitaciones
- Visualizar métricas, análisis y estadísticas del sistema

---

## Tecnologías

| Categoría | Tecnología |
|-----------|------------|
| UI | SwiftUI |
| Arquitectura | MVVM |
| Backend móvil | Supabase (PostgreSQL + Auth + Storage + Realtime) |
| Backend API | Python / Flask |
| Paquetes iOS | Swift Package Manager (SPM) |
| Control de versiones | Git + GitHub |
| CI/CD | GitHub Actions |
| Contenerización | Docker |
| Orquestación | Kubernetes (Minikube) |
| Gestión de despliegue | Helm |

---

## Arquitectura del proyecto

```
InnSight/
├── InnSight/               → App iOS (SwiftUI)
│   ├── Views/              → Interfaces construidas en SwiftUI
│   ├── ViewModels/         → Lógica de negocio y estado
│   ├── Models/             → Modelos de datos
│   ├── Services/           → Conexión y operaciones con Supabase
│   └── Utils/              → Funciones auxiliares y extensiones
├── backend/                → API REST en Flask (Python)
│   ├── app.py              → Endpoints REST
│   ├── requirements.txt    → Dependencias Python
│   ├── Dockerfile          → Imagen Docker del backend
│   └── tests/
│       └── test_app.py     → 22 pruebas unitarias
├── k8s/                    → Manifiestos de Kubernetes
│   ├── deployment.yaml     → Deployment (2 réplicas)
│   └── service.yaml        → NodePort
├── helm/                   → Helm chart
│   └── innsight/
│       ├── Chart.yaml      → Metadata del chart
│       ├── values.yaml     → Configuración centralizada
│       └── templates/      → Templates de deployment y service
├── .github/
│   └── workflows/
│       └── ios-ci.yml      → Pipeline CI (3 jobs)
└── docker-compose.yml      → Orquestación local
```

---

## Pipeline DevOps

Cada `push` o `pull request` a `main`, `develop` o `feature/**` dispara automáticamente el pipeline con **3 jobs**:

```
Push / PR
    │
    ├── Job 1: Backend Tests ──── pytest (22 pruebas) ── Ubuntu
    │
    ├── Job 2: Docker Build ───── build imagen ────────── Ubuntu
    │         (requiere que Job 1 pase)
    │
    └── Job 3: iOS Build ──────── xcodebuild ─────────── macOS
```

Ver configuración completa: [`.github/workflows/ios-ci.yml`](.github/workflows/ios-ci.yml)

---

## Estrategia de ramas (Git Flow)

```
main           ← Producción estable. Solo recibe merges desde develop.
│
develop        ← Integración. Aquí convergen todas las features.
│
├── feature/backend-flask    ← Backend API REST
├── feature/docker           ← Contenerización
├── feature/kubernetes       ← Despliegue en Kubernetes
└── feature/helm             ← Helm chart
```

### Flujo de trabajo

```bash
# 1. Crear rama desde develop
git checkout develop
git pull origin develop
git checkout -b feature/nombre-feature

# 2. Desarrollar y hacer commits
git commit -m "feat: descripcion del cambio"

# 3. Push y abrir Pull Request hacia develop
git push origin feature/nombre-feature

# 4. El CI corre automáticamente — debe pasar antes del merge

# 5. Cuando develop está listo → PR de develop a main
```

### Convención de commits

| Prefijo | Uso |
|---------|-----|
| `feat:` | Nueva funcionalidad |
| `fix:` | Corrección de bug |
| `refactor:` | Reestructuración de código |
| `docs:` | Cambios en documentación |
| `test:` | Añadir o modificar pruebas |
| `chore:` | Configuración, CI, dependencias |

---

## Backend API REST (Flask)

API REST en Python/Flask que expone los recursos principales de InnSight.

### Endpoints

| Método | Ruta | Descripción |
|--------|------|-------------|
| GET | `/api/health` | Health check del servicio |
| GET | `/api/hotels` | Listar todos los hoteles |
| GET | `/api/hotels/<id>` | Obtener hotel por ID |
| POST | `/api/hotels` | Crear hotel |
| GET | `/api/hotels/<id>/rooms` | Listar habitaciones del hotel |
| GET | `/api/rooms/<id>` | Obtener habitación por ID |
| POST | `/api/rooms` | Crear habitación |
| GET | `/api/reservations` | Listar reservaciones |
| GET | `/api/reservations/<id>` | Obtener reservación |
| POST | `/api/reservations` | Crear reservación |
| PATCH | `/api/reservations/<id>/status` | Actualizar estado |

### Correr localmente

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

python app.py
# → API disponible en http://localhost:5000
```

### Correr pruebas

```bash
cd backend
python -m pytest tests/ -v
# → 22 pruebas unitarias
```

---

## Docker

El backend está contenerizado con una imagen **multi-stage** para mantenerla ligera.

### Correr con Docker Compose (recomendado)

```bash
docker-compose up --build
# → API disponible en http://localhost:5000/api/health
```

### Correr manualmente

```bash
# Construir imagen
docker build -t innsight-backend ./backend

# Correr contenedor
docker run -p 5001:5000 innsight-backend

# Detener
docker stop <container_id>
```

---

## Kubernetes

Despliegue orquestado con Kubernetes usando **Minikube** como cluster local.

### Requisitos

- [Docker](https://www.docker.com/)
- [Minikube](https://minikube.sigs.k8s.io/)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

### Desplegar

```bash
# 1. Iniciar cluster
minikube start --driver=docker

# 2. Cargar imagen local en Minikube
minikube image load innsight-backend:latest

# 3. Aplicar manifiestos
kubectl apply -f k8s/

# 4. Verificar pods y servicios
kubectl get pods
kubectl get services

# 5. Obtener URL de acceso
minikube service innsight-backend --url
```

### Comandos útiles

```bash
kubectl logs <nombre-del-pod>        # ver logs de un pod
kubectl describe pod <nombre-pod>    # detalle de un pod
kubectl rollout status deployment/innsight-backend  # estado del rollout
minikube stop                        # apagar cluster
```

---

## Helm

Helm permite gestionar el despliegue completo con un solo comando y configuración centralizada.

### Estructura del chart

```
helm/innsight/
├── Chart.yaml       → Metadata (nombre, versión)
├── values.yaml      → Configuración centralizada
└── templates/
    ├── deployment.yaml
    └── service.yaml
```

### Comandos

```bash
# Instalar
helm install innsight helm/innsight/

# Ver releases activos
helm list

# Actualizar configuración (sin editar archivos)
helm upgrade innsight helm/innsight/ --set replicaCount=3

# Ver historial de versiones
helm history innsight

# Desinstalar
helm uninstall innsight
```

### Configuración disponible en `values.yaml`

| Parámetro | Valor por defecto | Descripción |
|-----------|------------------|-------------|
| `replicaCount` | `2` | Número de réplicas |
| `image.tag` | `latest` | Tag de la imagen Docker |
| `service.nodePort` | `30080` | Puerto expuesto en el nodo |
| `env.FLASK_ENV` | `production` | Entorno de Flask |

---

## Base de datos

Principales entidades en Supabase (PostgreSQL):

| Entidad | Relación |
|---------|----------|
| `profiles` | Un usuario tiene múltiples reservaciones |
| `hotels` | Un hotel tiene múltiples habitaciones |
| `rooms` | Una habitación pertenece a un hotel |
| `reservations` | Pertenece a un usuario y una habitación |

---

## Instalación

### App iOS

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/arthurgtp/InnSight.git
   cd InnSight
   git checkout develop
   ```

2. Abrir `InnSight.xcodeproj` en Xcode.

3. Configurar credenciales de Supabase en `InnSight/Services/Supabase.swift`:

   > ⚠️ **Nunca subas credenciales reales al repositorio.**

   ```swift
   let supabase = SupabaseClient(
     supabaseURL: URL(string: "TU_SUPABASE_URL")!,
     supabaseKey: "TU_SUPABASE_ANON_KEY"
   )
   ```

4. Ejecutar en simulador con ▶ en Xcode.

### Backend + pipeline completo

```bash
# Backend local
cd backend && python3 -m venv venv && source venv/bin/activate
pip install -r requirements.txt && python app.py

# Con Docker
docker-compose up --build

# Con Kubernetes + Helm
minikube start --driver=docker
minikube image load innsight-backend:latest
helm install innsight helm/innsight/
minikube service innsight-backend --url
```

---

## Autor

**Arturo Gutierrez**
Ingeniería en Desarrollo de Software
