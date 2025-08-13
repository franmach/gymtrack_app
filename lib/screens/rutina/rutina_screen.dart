import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RutinaScreen extends StatefulWidget {
  final String rutinaId;

  const RutinaScreen({super.key, required this.rutinaId});

  @override
  State<RutinaScreen> createState() => _RutinaScreenState();
}

class _RutinaScreenState extends State<RutinaScreen> {
  Map<String, dynamic>? rutina;

  @override
  void initState() {
    super.initState();
    _cargarRutina();
  }

  Future<void> _cargarRutina() async {
    final doc = await FirebaseFirestore.instance
        .collection('rutinas')
        .doc(widget.rutinaId)
        .get();

    if (doc.exists) {
      setState(() {
        rutina = doc.data();
      });
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
      appBar: AppBar(title: const Text('Mi Rutina')),
      body: ListView.builder(
        itemCount: dias.length,
        itemBuilder: (context, index) {
          final dia = dias[index];
          final ejercicios = dia['ejercicios'] as List;

          return ExpansionTile(
            title: Text(
              dia['dia'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            children: ejercicios.map<Widget>((ej) {
              return ListTile(
                title: Text(ej['nombre']),
                subtitle: Text(
                    '${ej['grupo_muscular'] ?? ej['grupoMuscular'] ?? ''} — Series:  ${ej['series']} — Repeticiones: ${ej['repeticiones']}'),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
