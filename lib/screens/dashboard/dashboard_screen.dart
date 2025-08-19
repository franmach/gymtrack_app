import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymtrack_app/screens/historial/historial_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/main.dart';
import 'package:gymtrack_app/services/rutinas/firestore_routine_service.dart';
import 'package:gymtrack_app/screens/session/day_selection_screen.dart';
import 'package:gymtrack_app/screens/session/timer_screen.dart';
import 'package:gymtrack_app/screens/admin/gimnasio_screen.dart';
import 'package:gymtrack_app/screens/nutricion/nutrition_plan_screen.dart';

// 👇 nuevos
import 'package:gymtrack_app/screens/chatbot/chatbot_screen.dart';
import 'package:gymtrack_app/services/chatbot/firestore_faq_service.dart';
import 'package:gymtrack_app/services/chatbot/hybrid_chat_service.dart';
import 'package:gymtrack_app/services/chatbot/gemini_chat_service.dart';

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
                const Text(
                  'Bienvenido al Dashboard',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistorialScreen()),
                    );
                  },
                  child: const Text('Historial'),
                ),
                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TimerScreen()),
                    );
                  },
                  icon: const Icon(Icons.timer),
                  label: const Text('Temporizador'),
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NutritionPlanScreen()),
                    );
                  },
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Plan Alimenticio'),
                ),
                const SizedBox(height: 12),

                // 👇 NUEVO: Chatbot Interactivo
                ElevatedButton.icon(
  onPressed: () {
    final chatService = HybridChatService(
      local: FirestoreFaqService(),
      fallback: GeminiChatService(),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatbotScreen(chat: chatService),
      ),
    );
  },
  icon: const Icon(Icons.chat_bubble_outline),
  label: const Text('Chatbot Interactivo'),
),

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
                      MaterialPageRoute(builder: (context) => const GimnasioScreen()),
                    );
                  },
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