import 'package:flutter/material.dart';
import '../../models/gamification.dart';
import '../../models/logro.dart';
import '../../services/gamification_repository.dart';
import '../../services/gamification_service.dart';

class AchievementsScreen extends StatefulWidget {
  final String uid;
  final GamificationRepository repo;
  final GamificationService service;

  const AchievementsScreen({
    super.key,
    required this.uid,
    required this.repo,
    required this.service,
  });

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  int asistenciasSemana = 0;
  int asistenciasMes = 0;
  int objetivoSemanal = 3;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    objetivoSemanal = await widget.service.obtenerObjetivoSemanal(widget.uid);
    asistenciasSemana = await widget.service.contarAsistenciasSemana(widget.uid, DateTime.now());
    asistenciasMes = await widget.service.contarAsistenciasMes(widget.uid, DateTime.now());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logros y Progreso')),
      body: StreamBuilder<GamificationStats?>(
        stream: widget.repo.statsStream(widget.uid),
        builder: (context, snapshot) {
          final stats = snapshot.data;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (stats != null) ...[
                Text('Puntos totales: ${stats.puntos}', style: Theme.of(context).textTheme.headlineSmall),
                Text('Racha actual: ${stats.rachaActual}'),
                Text('Récord de racha: ${stats.rachaRecord}'),
                const SizedBox(height: 16),
              ],
              Text('Progreso semanal: $asistenciasSemana / $objetivoSemanal'),
              LinearProgressIndicator(
                value: asistenciasSemana / objetivoSemanal,
                minHeight: 8,
              ),
              const SizedBox(height: 16),
              Text('Progreso mensual: $asistenciasMes / ${objetivoSemanal * 4}'),
              LinearProgressIndicator(
                value: asistenciasMes / (objetivoSemanal * 4),
                minHeight: 8,
              ),
              const SizedBox(height: 24),
              Text('Logros recientes:', style: Theme.of(context).textTheme.titleMedium),
              StreamBuilder<List<Logro>>(
                stream: widget.repo.logrosRecientesStream(widget.uid),
                builder: (context, snap) {
                  final logros = snap.data ?? [];
                  if (logros.isEmpty) {
                    return const Text('Aún no tienes logros.');
                  }
                  return Column(
                    children: logros.map((l) => Card(
                      child: ListTile(
                        title: Text(l.nombre),
                        subtitle: Text(l.descripcion),
                        trailing: Text('+${l.puntosOtorgados}'),
                      ),
                    )).toList(),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}