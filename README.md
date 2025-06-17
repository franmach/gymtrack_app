# GymTrack App

Aplicación móvil desarrollada en Flutter, conectada con Firebase, diseñada para la gestión personalizada de rutinas, nutrición, progreso físico y asistencia en gimnasios. Incluye un panel de administración para gestión completa.

## Estructura del proyecto

- `lib/app/`: Configuración general de la app, incluyendo rutas y temas globales.
- `lib/models/`: Modelos de datos.
- `lib/services/`: Conexiones a Firebase y otros servicios.
- `lib/providers/`: Gestión de estado.
- `lib/screens/`: Vistas de usuario (auth, rutina, progreso, admin...).
- `lib/widgets/`: Componentes reutilizables.
- `lib/utils/`: Funciones auxiliares.
- `test/`: Tests unitarios y de widgets.

## Setup

1. Clona el repo
2. Agrega un `.env` con tus claves
3. Ejecuta `flutter pub get`
4. Corre la app con `flutter run`