# InnSight

![iOS CI](https://github.com/arthurgtp/InnSight/actions/workflows/ios-ci.yml/badge.svg)
![Swift](https://img.shields.io/badge/Swift-5.9-orange?logo=swift)
![Platform](https://img.shields.io/badge/Platform-iOS-blue?logo=apple)
![License](https://img.shields.io/badge/License-MIT-green)

InnSight es una aplicación móvil desarrollada en SwiftUI que permite la gestión y reservación de hoteles. Diseñada para dos tipos de usuarios: **clientes** y **administradores**.

---

## Funcionalidades

### Cliente
- Ver lista de hoteles disponibles
- Visualizar habitaciones disponibles por hotel
- Ver imágenes 360° (si están disponibles)
- Reservar habitaciones
- Consultar reservas activas, canceladas y completadas

### Administrador
- Agregar y editar hoteles y habitaciones
- Eliminar habitaciones
- Visualizar métricas, análisis y estadísticas del sistema

---

## Tecnologías Utilizadas

| Categoría        | Tecnología                          |
|------------------|-------------------------------------|
| UI               | SwiftUI                             |
| Arquitectura     | MVVM                                |
| Backend          | Supabase (PostgreSQL + Auth + Storage + Realtime) |
| Paquetes         | Swift Package Manager (SPM)         |
| Control de versiones | Git + GitHub                    |
| CI/CD            | GitHub Actions                      |

---

## Arquitectura del Proyecto

```
InnSight/
├── Views/          → Interfaces construidas en SwiftUI
├── ViewModels/     → Lógica de negocio y estado
├── Models/         → Modelos de datos
├── Services/       → Conexión y operaciones con Supabase
└── Utils/          → Funciones auxiliares y extensiones
```

---

## Pipeline DevOps

### CI con GitHub Actions

Cada `push` o `pull request` a `main` o `develop` dispara automáticamente:
1. Resolución de dependencias (SPM)
2. Compilación de la app para simulador iOS
3. Ejecución de pruebas unitarias

Ver configuración: [`.github/workflows/ios-ci.yml`](.github/workflows/ios-ci.yml)

---

## Estrategia de Ramas (Git Flow)

```
main         ← Producción estable. Solo recibe merges desde develop o hotfix.
│
develop      ← Integración. Aquí convergen todas las features antes de llegar a main.
│
├── feature/nombre-feature   ← Una rama por funcionalidad nueva
├── fix/descripcion-bug       ← Correcciones de errores
├── hotfix/descripcion        ← Correcciones urgentes desde main
└── release/vX.Y.Z            ← Preparación de versiones
```

### Flujo de trabajo

1. Crear rama desde `develop`:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/nombre-de-la-feature
   ```

2. Desarrollar y hacer commits descriptivos:
   ```bash
   git commit -m "feat: agregar vista de calendario de disponibilidad"
   ```

3. Abrir Pull Request hacia `develop` (nunca directo a `main`)

4. El CI corre automáticamente — debe pasar antes de hacer merge

5. Cuando `develop` está listo para producción → PR de `develop` a `main`

### Convención de commits

| Prefijo    | Uso                              |
|------------|----------------------------------|
| `feat:`    | Nueva funcionalidad              |
| `fix:`     | Corrección de bug                |
| `refactor:`| Reestructuración de código       |
| `docs:`    | Cambios en documentación         |
| `test:`    | Añadir o modificar pruebas       |
| `chore:`   | Configuración, CI, dependencias  |

---

## Base de Datos

Principales entidades:

| Entidad       | Relación                             |
|---------------|--------------------------------------|
| Users         | Tiene múltiples Reservations         |
| Hotels        | Tiene múltiples Rooms                |
| Rooms         | Pertenece a un Hotel                 |
| Reservations  | Pertenece a User y Room              |

---

## Instalación

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/tu-usuario/InnSight.git
   cd InnSight
   git checkout develop
   ```

2. Abrir `InnSight.xcodeproj` en Xcode.

3. Configurar credenciales de Supabase:

   > ⚠️ **Nunca subas credenciales reales al repositorio.** Crea un archivo local `Secrets.xcconfig` (ya incluido en `.gitignore`) o configúralas directamente en `Supabase.swift` solo en tu entorno local.

   ```swift
   let supabase = SupabaseClient(
     supabaseURL: URL(string: "TU_SUPABASE_URL")!,
     supabaseKey: "TU_SUPABASE_ANON_KEY"
   )
   ```

4. Ejecutar en simulador o dispositivo físico con ▶ en Xcode.

---

## Autor

**Arturo Gutierrez**
Ingeniería en Desarrollo de Software
