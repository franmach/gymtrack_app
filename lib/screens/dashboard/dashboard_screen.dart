import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymtrack_app/screens/historial/historial_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/main.dart';
import 'package:gymtrack_app/services/firestore_routine_service.dart';
import 'package:gymtrack_app/screens/session/day_selection_screen.dart';
import 'package:gymtrack_app/screens/session/timer_screen.dart';
import 'package:gymtrack_app/screens/admin/gimnasio_screen.dart';
import 'package:gymtrack_app/models/usuario.dart';
import 'package:gymtrack_app/services/ajuste_rutina_service.dart';
import 'package:gymtrack_app/services/ai_service.dart';
import 'package:gymtrack_app/screens/nutricion/nutrition_plan_screen.dart'; // Nueva pantalla de Plan Alimenticio

/// DashboardScreen: Pantalla principal tras iniciar sesión
typedef DocSnapshot = DocumentSnapshot<Map<String, dynamic>>;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _ajustarRutinaSiCorresponde();
  }

  Future<void> _ajustarRutinaSiCorresponde() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final firestore = FirebaseFirestore.instance;
    final userDoc = await firestore.collection('usuarios').doc(uid).get();
    if (!userDoc.exists) return;

    final usuario = Usuario.fromMap(userDoc.data()!, uid);
    final ajusteService = AjusteRutinaService(
      firestore: firestore,
      aiService: AiService(),
    );
    try {
      await ajusteService.ajustarRutinaMensual(usuario);
    } catch (e,stack) {
      print('❌ Error en ajuste automático: $e');
        print('STACKTRACE: $stack');

    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: FutureBuilder<DocSnapshot>(
          future:
              FirebaseFirestore.instance.collection('rutinas').doc(uid).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bienvenido al Dashboard',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Botón de iniciar entrenamiento
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DaySelectionScreen(
                          service: FirestoreRoutineService(),
                          userId: uid,
                        ),
                      ),
                    );
                  },
                  child: const Text('Iniciar entrenamiento'),
                ),
                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: () async {
                    print('▶ BOTÓN PRESIONADO');

                    final firestore = FirebaseFirestore.instance;
                    final ai = AiService();

                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    print('▶ UID del usuario: $uid');

                    if (uid == null) {
                      print('❌ UID nulo, el usuario no está logueado.');
                      return;
                    }

                    final userDoc =
                        await firestore.collection('usuarios').doc(uid).get();
                    print('▶ Documento de usuario existe: ${userDoc.exists}');

                    if (!userDoc.exists) {
                      print(
                          '❌ El documento del usuario no existe en Firestore.');
                      return;
                    }

                    final usuario = Usuario.fromMap(userDoc.data()!, uid);

                    final ajusteService = AjusteRutinaService(
                      firestore: firestore,
                      aiService: ai,
                    );

                    try {
                      print('▶ Ejecutando ajuste...');
                      await ajusteService.ajustarRutinaMensual(usuario);
                      print('✅ Ajuste completado con éxito.');
                    } catch (e, stack) {
                      print('❌ Error al ejecutar ajuste automático: $e');
                      print(stack);
                    }
                  },
                  child: const Text('Ajustar rutina automáticamente (TEST)'),
                ),

                const SizedBox(height: 12),

                // Botón para acceder al historial de entrenamientos
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HistorialScreen(),
                      ),
                    );
                  },
                  child: const Text('Historial'),
                ),
                const SizedBox(height: 12),

                // Botón para acceder al temporizador
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TimerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.timer),
                  label: const Text('Temporizador'),
                ),

                const SizedBox(height: 24),

                // Botón para acceder al Plan Alimenticio
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NutritionPlanScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Plan Alimenticio'),
                ),
                const SizedBox(height: 12),

                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  child: const Text('Perfil'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.fitness_center),
                  label: const Text('Gimnasio'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const GimnasioScreen()),
                    );
                  },
                ),

                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('Cerrar Sesión'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
