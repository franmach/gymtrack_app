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

  TextEditingController pesoController = TextEditingController();

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
              final peso = ej['peso'];
              return Card(
                color: Colors.black,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ej['nombre'],
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.fitness_center,
                              color: Theme.of(context).primaryColor, size: 22),
                          const SizedBox(width: 6),
                          Text(
                            ej['grupo_muscular'] ?? ej['grupoMuscular'] ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.format_list_numbered,
                              color: Theme.of(context).primaryColor, size: 22),
                          const SizedBox(width: 6),
                          Text('Series: ${ej['series']}',
                              style: TextStyle(color: Colors.white)),
                          const SizedBox(width: 16),
                          Icon(Icons.repeat,
                              color: Theme.of(context).primaryColor, size: 22),
                          const SizedBox(width: 6),
                          Text('Reps: ${ej['repeticiones']}',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      if (peso != null && (peso as num) > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.fitness_center,
                                color: Theme.of(context).primaryColor,
                                size: 22),
                            const SizedBox(width: 6),
                            Text(
                                'Peso recomendado: ${peso.toStringAsFixed(2)} kg',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
