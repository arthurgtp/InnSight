# InnSight

InnSight es una aplicación móvil desarrollada en SwiftUI que permite la gestión y reservación de hoteles. La aplicación está diseñada para ofrecer funcionalidades tanto a clientes como a administradores dentro de una misma plataforma.

---

## Descripción

InnSight permite a los usuarios explorar hoteles, visualizar habitaciones disponibles, realizar reservaciones y consultar el estado de sus reservas. Por otro lado, los administradores pueden gestionar hoteles, habitaciones y visualizar métricas del sistema.

---

## Funcionalidades

### Cliente

- Ver lista de hoteles disponibles  
- Visualizar habitaciones disponibles por hotel  
- Ver imágenes 360° (si están disponibles)  
- Reservar habitaciones  
- Consultar reservas activas, canceladas y completadas  

### Administrador

- Agregar hoteles  
- Editar hoteles  
- Agregar habitaciones  
- Editar habitaciones  
- Eliminar habitaciones  
- Visualizar métricas y análisis  

---

## Tecnologías Utilizadas

- SwiftUI  
- Supabase  
  - PostgreSQL  
  - Autenticación  
  - Storage para imágenes  
- Arquitectura basada en consumo de backend remoto  
- Git y GitHub para control de versiones  

---

## Arquitectura del Proyecto

El proyecto sigue una estructura modular organizada en:

- Views → Interfaces construidas en SwiftUI  
- Models → Modelos de datos  
- ViewModels → Lógica de negocio  
- Services → Conexión y operaciones con Supabase  
- Utils → Funciones auxiliares  

---

## Autenticación

La aplicación utiliza Supabase para:

- Registro de usuario  
- Inicio de sesión  
- Manejo de sesión activa  
- Control de roles (Cliente / Administrador)  

---

## Base de Datos

Las principales entidades del sistema son:

- Users  
- Hotels  
- Rooms  
- Reservations  

Relaciones principales:

- Un hotel tiene múltiples habitaciones  
- Un usuario puede tener múltiples reservaciones  
- Una reservación pertenece a una habitación  

---

## Instalación

1. Clonar el repositorio:
```bash
git clone https://github.com/tu-usuario/InnSight.git
```
2. Abrir el proyecto en Xcode.
3. Configurar las credenciales de Supabase en el archivo correspondiente:
```swift
SupabaseClient(
  supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
  supabaseKey: "YOUR_SUPABASE_ANON_KEY"
)
```
4. Ejecutar el proyecto en simulador o dispositivo físico.

---

## Autor

Arturo Gutierrez  
Ingeniería en Desarrollo de Software

