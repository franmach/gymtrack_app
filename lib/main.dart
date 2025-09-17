import 'package:flutter/material.dart';
import 'gymtrack_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:gymtrack_app/services/ai_service.dart';
import 'package:gymtrack_app/services/nutrition_ai_service.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/perfil/perfil_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/main_tabbed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        // Servicio genérico de AI usando Gemini 1.5 Flash
        Provider<AiService>(
          create: (_) => AiService(),
        ),
        // Servicio de nutrición que reusa AiService
        Provider<NutritionAIService>(
          create: (ctx) => NutritionAIService(),
        ),
        // Provider<UserRepository> eliminado — no se inyecta globalmente ahora
      ],
      child: const GymTrackApp(),
    ),
  );
}

class GymTrackApp extends StatelessWidget {
  const GymTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymTrack',
      debugShowCheckedModeBanner: false,
      theme: gymTrackTheme,
      home: const AuthGate(),
      routes: {
        '/profile': (context) => const PerfilScreen(),
        // Agrega aquí más rutas si las necesitas
      },
    );
  }
}

// Widget que muestra login si no hay usuario autenticado
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          // No hay usuario: abrir pantalla de login
          return const LoginScreen();
        }

        // Usuario logueado: mostrar la interfaz principal
        return const MainTabbedScreen();
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                '/images/logo.png',
                width: 300,
                height: 300,
              ),

              // Botón de registro
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegisterScreen()),
                    );
                  },
                  child: const Text('Registrarse'),
                ),
              ),
              const SizedBox(height: 16),

              // Botón de login
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                    );
                  },
                  child: const Text('Iniciar Sesión'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
