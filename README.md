# GymTrack
### Sistema inteligente para gestión de gimnasios

**Proyecto de tesis – Analista Programador**  
**Universidad CLAEH (CEI) – 2025**

---

## Descripción General

GymTrack es una aplicación móvil diseñada para la gestión integral de gimnasios. Permite administrar usuarios, generar rutinas de entrenamiento personalizadas y gestionar información del gimnasio desde un entorno digital centralizado.

El sistema incorpora servicios de inteligencia artificial para generar rutinas adaptadas a las características de cada usuario, considerando factores como objetivos de entrenamiento, nivel de experiencia y disponibilidad semanal.

Este proyecto fue desarrollado como **tesis final de la carrera Analista Programador**, con el objetivo de aplicar conocimientos de desarrollo móvil, backend serverless e integración de APIs externas.

---

## Tecnologías Utilizadas

### Lenguajes
- Dart
- JavaScript

### Frameworks y Tecnologías
- Flutter
- Firebase Authentication
- Firebase Firestore
- Firebase Storage
- Firebase Cloud Functions

### Inteligencia Artificial
- Gemini API (Google Generative AI)

### Bases de Datos
- Firestore (NoSQL)

### Herramientas
- Git
- Firebase Console

---

## Características Principales

### Gestión de Usuarios
Sistema de registro y autenticación de usuarios utilizando **Firebase Authentication**, permitiendo la creación y administración segura de cuentas.

### Generación de Rutinas con Inteligencia Artificial
El sistema permite generar rutinas de entrenamiento personalizadas utilizando inteligencia artificial en función de:

- objetivo del usuario
- disponibilidad semanal
- nivel de experiencia

### Gestión de Perfiles
Los usuarios pueden completar su perfil con información relevante para personalizar las rutinas y mejorar la experiencia de entrenamiento.

### Sistema de Roles
Control de acceso que diferencia entre:

- usuarios del gimnasio
- administradores del sistema

### Panel Administrativo
Permite gestionar usuarios y supervisar información relevante del sistema.

### Arquitectura basada en servicios
Uso de una arquitectura **serverless** mediante Firebase para separar la lógica de negocio de la aplicación móvil.

---

## Arquitectura del Sistema

La aplicación utiliza Firebase como backend serverless.

### Componentes principales

**Flutter App**  
Aplicación móvil utilizada por los usuarios.

**Firebase Authentication**  
Gestión de autenticación y sesiones.

**Firestore**  
Base de datos NoSQL para almacenar usuarios y rutinas.

**Cloud Functions**  
Funciones backend para lógica de negocio.

**Gemini API**  
Servicio de inteligencia artificial para generación de rutinas.

---

## Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/tuusuario/gymtrack.git
```

### 2. Acceder al proyecto

```bash
cd gymtrack
```

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Configurar Firebase

1. Crear un proyecto en **Firebase Console**
2. Habilitar **Authentication y Firestore**
3. Descargar el archivo de configuración
4. Integrarlo en el proyecto Flutter

### 5. Ejecutar la aplicación

```bash
flutter run
```
---
## Uso

### Usuarios

Los usuarios de la aplicación pueden:

- Registrarse en la aplicación mediante autenticación segura.
- Completar su perfil indicando objetivos y disponibilidad de entrenamiento.
- Generar rutinas personalizadas utilizando inteligencia artificial.
- Consultar y seguir su plan de entrenamiento.

### Administradores

Los administradores del sistema pueden:

- Gestionar usuarios registrados.
- Supervisar información general del sistema.
- Administrar rutinas y datos asociados al gimnasio.

---
## Capturas de Pantalla
<img width="373" height="667" alt="0 (1)" src="https://github.com/user-attachments/assets/29008e9c-9797-4260-89c2-6f1dd6c93527" />
<img width="375" height="666" alt="0 (2)" src="https://github.com/user-attachments/assets/d651579c-0ee1-4669-bfd0-d71daef9bb5c" />
<img width="390" height="847" alt="0 (3)" src="https://github.com/user-attachments/assets/a4453fa7-ab03-4f02-97c2-94ace42debd5" />
<img width="390" height="788" alt="0" src="https://github.com/user-attachments/assets/36a4f8a8-79d2-4232-ba5c-2132170e5936" />

<img width="391" height="850" alt="0 (4)" src="https://github.com/user-attachments/assets/d7e78316-0967-43fb-9d70-807db951fc33" />

<img width="391" height="851" alt="0 (5)" src="https://github.com/user-attachments/assets/1270dd3e-4564-49a6-ac35-c6749fe6908d" />
<img width="392" height="852" alt="0 (6)" src="https://github.com/user-attachments/assets/5c110ea3-e0ab-4114-b88c-0a59e7f5cd95" />
<img width="392" height="847" alt="0 (7)" src="https://github.com/user-attachments/assets/d2b539c8-5866-4adf-9d45-cc34ca192c59" />
<img width="390" height="847" alt="0 (8)" src="https://github.com/user-attachments/assets/960b9df6-0267-4fd4-b6b2-4ff6a4c1e222" />
