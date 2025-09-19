// ==========================
// lib/screens/dashboard_screen.dart (ACTUALIZADO – sin verificación de admin)
// ==========================
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymtrack_app/screens/historial/historial_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/main.dart';
import 'package:gymtrack_app/services/rutinas/firestore_routine_service.dart';
import 'package:gymtrack_app/screens/session/day_selection_screen.dart';
import 'package:gymtrack_app/screens/session/timer_screen.dart';
import 'package:gymtrack_app/screens/admin/gimnasio_screen.dart';
import 'package:gymtrack_app/models/usuario.dart';
import 'package:gymtrack_app/services/ajuste_rutina_service.dart';
import 'package:gymtrack_app/services/ai_service.dart';
import 'package:gymtrack_app/screens/nutricion/nutrition_plan_screen.dart';

// 👇 nuevos
import 'package:gymtrack_app/screens/chatbot/chatbot_screen.dart';
import 'package:gymtrack_app/services/chatbot/firestore_faq_service.dart';
import 'package:gymtrack_app/services/chatbot/hybrid_chat_service.dart';
import 'package:gymtrack_app/services/chatbot/gemini_chat_service.dart';

// 👇 NUEVO: acceso al panel (lo implementamos en el siguiente paso)
import 'package:gymtrack_app/screens/admin/admin_hub_screen.dart';

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
            /*
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Text(
                'Aún no tienes una rutina generada.',
                textAlign: TextAlign.center,
              );
            }
            */

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Bienvenido al Dashboard',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Iniciar entrenamiento
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

                  // Ajuste automático (TEST)
                  ElevatedButton(
                    onPressed: () async {
                      // Logs de diagnóstico
                      // ignore: avoid_print
                      print('▶ BOTÓN PRESIONADO');

                      final firestore = FirebaseFirestore.instance;
                      final ai = AiService();

                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      // ignore: avoid_print
                      print('▶ UID del usuario: $uid');

                      if (uid == null) {
                        // ignore: avoid_print
                        print('❌ UID nulo, el usuario no está logueado.');
                        return;
                      }

                      final userDoc = await firestore.collection('usuarios').doc(uid).get();
                      // ignore: avoid_print
                      print('▶ Documento de usuario existe: ${userDoc.exists}');

                      if (!userDoc.exists) {
                        // ignore: avoid_print
                        print('❌ El documento del usuario no existe en Firestore.');
                        return;
                      }

                      final usuario = Usuario.fromMap(userDoc.data()!, uid);

                      final ajusteService = AjusteRutinaService(
                        firestore: firestore,
                        aiService: ai,
                      );

                      try {
                        // ignore: avoid_print
                        print('▶ Ejecutando ajuste...');
                        await ajusteService.ajustarRutinaMensual(usuario);
                        // ignore: avoid_print
                        print('✅ Ajuste completado con éxito.');
                      } catch (e, stack) {
                        // ignore: avoid_print
                        print('❌ Error al ejecutar ajuste automático: $e');
                        // ignore: avoid_print
                        print(stack);
                      }
                    },
                    child: const Text('Ajustar rutina automáticamente (TEST)'),
                  ),

                  // Historial
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistorialScreen(),
                        ),
                      );
                    },
                    child: const Text('Historial'),
                  ),

                  // Temporizador
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

                  // Plan alimenticio
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const NutritionPlanScreen()),
                      );
                    },
                    icon: const Icon(Icons.restaurant_menu),
                    label: const Text('Plan Alimenticio'),
                  ),

                  // Chatbot interactivo
                  const SizedBox(height: 12),
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

                  // Perfil
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/profile'),
                    child: const Text('Perfil'),
                  ),

                  // Gimnasio
                  const SizedBox(height: 12),
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

                  // =============================
                  // NUEVO: Botón ADMINISTRADOR (visible para todos)
                  // =============================
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('ADMINISTRADOR'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AdminHubScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Cerrar sesión
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      // ignora rutas previas
                      // ignore: use_build_context_synchronously
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    child: const Text('Cerrar Sesión'),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
