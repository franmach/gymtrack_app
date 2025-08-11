import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/main.dart';
import 'package:gymtrack_app/services/firestore_routine_service.dart';
import 'package:gymtrack_app/screens/session/day_selection_screen.dart';
import 'package:gymtrack_app/screens/session/timer_screen.dart';
import 'package:gymtrack_app/screens/nutricion/nutrition_plan_screen.dart'; // Nueva pantalla de Plan Alimenticio

/// DashboardScreen: Pantalla principal tras iniciar sesión
typedef DocSnapshot = DocumentSnapshot<Map<String, dynamic>>;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: FutureBuilder<DocSnapshot>(
          future: FirebaseFirestore.instance.collection('rutinas').doc(uid).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text(
                'Aún no tienes una rutina generada.',
                textAlign: TextAlign.center,
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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

                const SizedBox(height: 24),

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

                const SizedBox(height: 32),

                const Text(
                  'Bienvenido al Dashboard',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  child: const Text('Perfil'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  child: const Text('Configuraciones'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
