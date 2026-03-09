GymTrack

GymTrack es una aplicación móvil diseñada para la gestión integral de gimnasios. Permite administrar usuarios, generar rutinas personalizadas, realizar seguimiento del entrenamiento y gestionar la información del gimnasio desde un panel administrativo.
El sistema integra servicios de inteligencia artificial para generar rutinas de entrenamiento adaptadas a los objetivos y disponibilidad del usuario.

Tabla de Contenidos

Descripción General
Tecnologías Utilizadas
Características
Arquitectura del Sistema
Instalación
Uso
Capturas de Pantalla
Autor

Descripción General

GymTrack fue desarrollado como proyecto final de la carrera Analista Programador en la Universidad CLAEH (CEI).

El objetivo del proyecto es ofrecer una plataforma digital que permita a gimnasios gestionar de forma eficiente la información de sus socios, generar rutinas personalizadas y mejorar la experiencia de entrenamiento mediante el uso de inteligencia artificial.

La aplicación permite a los usuarios crear su perfil, registrar sus objetivos y disponibilidad de entrenamiento, y obtener rutinas generadas automáticamente utilizando modelos de IA. Además, incluye funcionalidades administrativas para gestionar usuarios y supervisar la actividad dentro del gimnasio.

Tecnologías Utilizadas
Lenguajes

Dart
JavaScript

Frameworks y Tecnologías

Flutter
Firebase Authentication
Firebase Firestore
Firebase Storage
Firebase Cloud Functions

Inteligencia Artificial

Gemini API (Google Generative AI)

Bases de Datos

Firestore (NoSQL)

Herramientas

Git
Firebase Console

Características
Gestión de usuarios

Registro y autenticación de usuarios mediante Firebase Authentication.

Generación de rutinas con IA

Sistema que genera rutinas de entrenamiento personalizadas utilizando inteligencia artificial en función de:

objetivo del usuario

disponibilidad semanal

nivel de experiencia

Gestión de perfiles

Los usuarios pueden completar su perfil con información relevante para la generación de rutinas.

Sistema de roles

Control de acceso para diferenciar entre usuarios y administradores.

Panel administrativo

Permite gestionar usuarios y supervisar información relevante del sistema.

Arquitectura basada en servicios

Uso de Firebase y Cloud Functions para separar lógica de negocio y gestión de datos.

Arquitectura del Sistema

La aplicación sigue una arquitectura basada en servicios utilizando Firebase como backend serverless.

Componentes principales:

Flutter App → interfaz móvil para usuarios.

Firebase Authentication → gestión de autenticación y sesiones.

Firestore → almacenamiento de datos de usuarios y rutinas.

Cloud Functions → lógica de negocio y generación de rutinas.

Gemini API → generación de contenido mediante inteligencia artificial.

Instalación

Clonar el repositorio:

git clone https://github.com/tuusuario/gymtrack.git

Acceder al proyecto:

cd gymtrack

Instalar dependencias:

flutter pub get

Configurar Firebase:

Crear un proyecto en Firebase.

Habilitar Authentication y Firestore.

Descargar el archivo de configuración de Firebase.

Integrarlo en el proyecto Flutter.

Ejecutar la aplicación:

flutter run
Uso
Usuarios

Registrarse en la aplicación.

Completar su perfil con objetivos y disponibilidad.

Generar rutinas personalizadas utilizando inteligencia artificial.

Consultar su plan de entrenamiento.

Administradores

Gestionar usuarios registrados.

Supervisar información del sistema.

Administrar datos relacionados con rutinas.

Capturas de Pantalla

image image image image image

Autor

Francisco Machado
Analista Programador – Universidad CLAEH

Email: franmach20@outlook.com

LinkedIn:
https://www.linkedin.com/in/francisco-machado-almandos-a1a826230

GitHub:
https://github.com/franmach
