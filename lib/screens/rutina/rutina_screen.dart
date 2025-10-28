import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// 🔹 Importamos OfflineService
import 'package:gymtrack_app/services/offline_service.dart';

class RutinaScreen extends StatefulWidget {
  final String rutinaId;

  const RutinaScreen({super.key, required this.rutinaId});

  @override
  State<RutinaScreen> createState() => _RutinaScreenState();
}

class _RutinaScreenState extends State<RutinaScreen> {
  Map<String, dynamic>? rutina;
  bool offlineMode = false; // 🔹 Para mostrar aviso si se usó offline

  @override
  void initState() {
    super.initState();
    _cargarRutina();
  }

  TextEditingController pesoController = TextEditingController();

  Future<void> _cargarRutina() async {
    try {
      // 🔹 Intentamos primero desde Firestore
      final doc = await FirebaseFirestore.instance
          .collection('rutinas')
          .doc(widget.rutinaId)
          .get();

      if (doc.exists) {
        setState(() {
          rutina = doc.data();
          offlineMode = false;
        });

        // 🔹 Guardamos offline para tener copia actualizada
        final uid = FirebaseAuth.instance.currentUser!.uid;
        await OfflineService.saveRoutine(uid, rutina!);
        return;
      }
    } catch (e) {
      print('❌ Error Firestore (¿sin conexión?): $e');
    }

    // 🔹 Si falla Firestore, intentamos cargar de Hive
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final offlineData = OfflineService.getRoutine(uid);
      if (offlineData != null) {
        setState(() {
          rutina = offlineData['routine'];
          offlineMode = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (rutina == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dias = rutina!['rutina'] as List;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Rutina'),
        backgroundColor: offlineMode ? Colors.orange : null, // 🔹 Aviso visual
      ),
      body: Column(
        children: [
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
          Expanded(
            child: ListView.builder(
              itemCount: dias.length,
              itemBuilder: (context, index) {
                final dia = dias[index];
                final ejercicios = (dia['ejercicios'] as List<dynamic>);


                return ExpansionTile(
                  title: Text(
                    dia['dia'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  children: ejercicios.map<Widget>((ej) {
  if (ej is Map<String, dynamic>) {
    return ListTile(
      title: Text(ej['nombre'] ?? ''),
      subtitle: Text(
        "Series ${ej['series']} X ${ej['repeticiones']} repeticiones - Peso: ${ej['peso'] ?? 'N/A'} kg",
      ),
    );
  } else if (ej is String) {
    return ListTile(
      title: Text(
        ej,
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      ),
    );
  } else {
    return const ListTile(
      title: Text("Ejercicio no válido"),
    );
  }
}).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
