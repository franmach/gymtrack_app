import 'package:flutter/material.dart';
import 'package:gymtrack_app/models/ejercicioAsignado.dart';
import 'package:gymtrack_app/services/routine_service.dart';
import 'session_screen.dart';

class DaySelectionScreen extends StatefulWidget {
  final RoutineService service;
  final String userId;
  const DaySelectionScreen({
    Key? key,
    required this.service,
    required this.userId,
  }) : super(key: key);

  @override
  _DaySelectionScreenState createState() => _DaySelectionScreenState();
}

class _DaySelectionScreenState extends State<DaySelectionScreen> {
  late Future<List<String>> _daysFuture;

  @override
  void initState() {
    super.initState();
    _daysFuture = widget.service.fetchRoutineDays(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elige día de tu rutina')),
      body: FutureBuilder<List<String>>(
        future: _daysFuture,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final days = snap.data ?? [];
          if (days.isEmpty) {
            return const Center(child: Text('No hay días de rutina disponibles.'));
          }
          return ListView.builder(
            itemCount: days.length,
            itemBuilder: (ctx, i) {
              final day = days[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(day),
                  subtitle: FutureBuilder<List<EjercicioAsignado>>(
                    future: widget.service.fetchExercisesForDay(widget.userId, day),
                    builder: (ctx2, snap2) {
                      if (snap2.connectionState != ConnectionState.done) {
                        return const Text('Cargando...');
                      }
                      final list = snap2.data ?? [];
                      if (list.isEmpty) return const Text('Sin ejercicios');
                      // muestra solo los nombres, separados por comas
                      final names = list.map((e) => e.nombre).join(', ');
                      return Text(names, maxLines: 1, overflow: TextOverflow.ellipsis);
                    },
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SesionScreen(
                          service: widget.service,
                          userId: widget.userId,
                          day: day,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}