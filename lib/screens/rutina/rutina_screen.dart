import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gymtrack_app/services/offline_service.dart';

/// Pantalla principal de la rutina actual del usuario.
/// - Si hay conexión, carga desde Firestore.
/// - Si falla o no hay conexión, usa la última versión guardada en Hive.
/// - Muestra un aviso visual si está en modo offline.
class RutinaScreen extends StatefulWidget {
  const RutinaScreen({super.key, required String rutinaId});

  @override
  State<RutinaScreen> createState() => _RutinaScreenState();
}

class _RutinaScreenState extends State<RutinaScreen> {
  Map<String, dynamic>? rutina;
  bool offlineMode = false;
  String? rutinaDocId;

  @override
  void initState() {
    super.initState();
    _cargarRutina();
  }

  Future<void> _cargarRutina() async {
    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    try {
      // 1️⃣ Buscar el ID de la rutina actual asociada al usuario
      final userDoc =
          await firestore.collection('usuarios').doc(currentUser.uid).get();

      if (!userDoc.exists ||
          !userDoc.data()!.containsKey('rutina_actual_id')) {
        setState(() {
          rutina = {};
          offlineMode = false;
        });
        return;
      }

      final rutinaId = userDoc['rutina_actual_id'];
      final rutinaDoc =
          await firestore.collection('rutinas').doc(rutinaId).get();

      // 2️⃣ Si encontramos la rutina en Firestore
      if (rutinaDoc.exists && rutinaDoc.data() != null) {
        setState(() {
          rutina = rutinaDoc.data()!;
          rutinaDocId = rutinaDoc.id;
          offlineMode = false;
        });

        // Guardar copia offline para uso sin conexión
        await OfflineService.saveRoutine(currentUser.uid, rutina!);
        return;
      }
    } catch (e) {
      debugPrint('❌ Error al cargar desde Firestore: $e');
    }

    // 3️⃣ Si falla Firestore (sin conexión o error)
    final offlineData = OfflineService.getRoutine(currentUser.uid);
    if (offlineData != null) {
      setState(() {
        rutina = offlineData['routine'];
        rutinaDocId = offlineData['id'];
        offlineMode = true;
      });
    } else {
      setState(() {
        rutina = {};
        rutinaDocId = null;
        offlineMode = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🕓 Estado de carga
    if (rutina == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dias = (rutina!['rutina'] ?? []) as List;

    // 📭 Sin ejercicios cargados
    if (dias.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Rutina'),
          backgroundColor: offlineMode ? Colors.orange : null,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              offlineMode
                  ? 'Mostrando última rutina guardada sin conexión.'
                  : 'No hay ejercicios cargados para esta rutina.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      );
    }

    // ✅ Rutina cargada correctamente
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Rutina'),
        backgroundColor: offlineMode ? Colors.orange : null,
      ),
      body: Column(
        children: [
          // 🔸 Aviso visual de modo offline
          if (offlineMode)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.all(8),
              child: const Text(
                "Modo offline: mostrando última rutina guardada",
                style: TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

          // 🏋️‍♂️ Listado de días y ejercicios
          Expanded(
            child: ListView.builder(
              itemCount: dias.length,
              itemBuilder: (context, index) {
                final dia = dias[index];
                if (dia is! Map) return const SizedBox.shrink();

                final nombreDia =
                    (dia['dia'] ?? 'Día sin nombre').toString().trim();
                final ejercicios = (dia['ejercicios'] ?? []) as List;

                return Card(
                  color: const Color(0xFF1A1A1A),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    collapsedIconColor: Colors.white70,
                    iconColor: Colors.white70,
                    title: Text(
                      nombreDia,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    children: ejercicios.map<Widget>((ej) {
                      if (ej is! Map) {
                        return const ListTile(
                          title: Text(
                            "Ejercicio no válido",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        );
                      }

                      final nombre = (ej['nombre'] ?? '').toString();
                      final series = ej['series']?.toString() ?? '';
                      final repeticiones =
                          (ej['repeticiones'] ?? '').toString();
                      final grupo =
                          (ej['grupo_muscular'] ?? '').toString().trim();
                      final descanso =
                          ej['descanso_segundos']?.toString() ?? '0';
                      final peso = ej['peso'];

                      final detalle = <String>[
                        if (series.isNotEmpty || repeticiones.isNotEmpty)
                          "Series: ${series.isEmpty ? '-' : series}  •  Reps: ${repeticiones.isEmpty ? '-' : repeticiones}",
                        if (peso != null &&
                            peso.toString().isNotEmpty &&
                            peso.toString() != "0")
                          "Peso: ${peso}kg",
                        if (descanso != '0') "Descanso: ${descanso}s",
                        if (grupo.isNotEmpty) "Grupo: $grupo",
                      ].join('\n');

                      return ListTile(
                        title: Text(
                          nombre.isNotEmpty ? nombre : 'Ejercicio sin nombre',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          detalle.isEmpty ? '—' : detalle,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}