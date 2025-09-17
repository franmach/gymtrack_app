import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gymtrack_app/screens/main_tabbed_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

import 'gymtrack_theme.dart';
import 'package:gymtrack_app/services/ai_service.dart';
import 'package:gymtrack_app/services/nutrition_ai_service.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/perfil/perfil_screen.dart';

// ------------------ MAIN ------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/Montevideo'));

  await Hive.initFlutter();
  await Hive.openBox('gt_reminders');
  await Hive.openBox('gt_prefs');

  AwesomeNotifications().initialize(
    null,
    [
      NotificationChannel(
        channelKey: 'gymtrack_channel',
        channelName: 'Notificaciones GymTrack',
        channelDescription:
            'Canal de notificaciones personalizadas de GymTrack',
        defaultColor: Colors.blue,
        ledColor: Colors.white,
        importance: NotificationImportance.Max,
      )
    ],
    debug: true,
  );

  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) {
    await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<AiService>(create: (_) => AiService()),
        Provider<NutritionAIService>(create: (ctx) => NutritionAIService()),
      ],
      child: const GymTrackApp(),
    ),
  );
}

// ------------------ APP ------------------
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
              Image.asset('assets/images/logo.png', width: 300, height: 300),
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
