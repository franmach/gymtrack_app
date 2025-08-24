import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/models/ejercicioAsignado.dart';
import 'routine_service.dart';

/// Servicio real que carga la rutina generada desde Firestore
class FirestoreRoutineService implements RoutineService {
  @override
  Future<List<String>> fetchRoutineDays(String userId) async {
    final query = await FirebaseFirestore.instance
        .collection('rutinas')
        .where('uid', isEqualTo: userId)
        .where('es_actual', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return [];

    final diasRaw = (query.docs.first.data()['rutina'] as List<dynamic>);
    return diasRaw.map((d) => d['dia'] as String).toList();
  }

  @override
  Future<List<EjercicioAsignado>> fetchExercisesForDay(
      String userId, String day) async {
    final query = await FirebaseFirestore.instance
        .collection('rutinas')
        .where('uid', isEqualTo: userId)
        .where('es_actual', isEqualTo: true)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return [];

    final diasRaw = (query.docs.first.data()['rutina'] as List<dynamic>);
    final diaMap = diasRaw.firstWhere(
      (d) => d['dia'] == day,
      orElse: () => null,
    );
    if (diaMap == null) return [];

    final ejerciciosRaw = diaMap['ejercicios'] as List<dynamic>;
    return ejerciciosRaw.map((ej) {
      final m = ej as Map<String, dynamic>;
      return EjercicioAsignado(
        nombre: (m['nombre'] ?? '').toString(),
        grupoMuscular:
            (m['grupo_muscular'] ?? m['grupoMuscular'] ?? 'Sin especificar')
                .toString(),
        series: (m['series'] ?? 0) as int,
        repeticiones: (m['repeticiones'] ?? m['reps'] ?? 0) as int,
        peso: m['peso'] != null ? (m['peso'] as num).toDouble() : null,
        descansoSegundos: (m['descanso_segundos'] ?? 0) as int,
      );
    }).toList();
  }
}
