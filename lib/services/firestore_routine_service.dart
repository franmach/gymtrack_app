import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/models/ejercicioAsignado.dart';
import 'routine_service.dart';

/// Servicio real que carga la rutina generada desde Firestore
class FirestoreRoutineService implements RoutineService {
  @override
  Future<List<String>> fetchRoutineDays(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection('rutinas')
        .doc(userId)
        .get();
    if (!doc.exists) return [];
    final diasRaw = (doc.data()!['rutina'] as List<dynamic>);
    return diasRaw.map((d) => d['dia'] as String).toList();
  }

  @override
  Future<List<EjercicioAsignado>> fetchExercisesForDay(
      String userId, String day) async {
    final doc = await FirebaseFirestore.instance
        .collection('rutinas')
        .doc(userId)
        .get();
    if (!doc.exists) return [];
    final diasRaw = (doc.data()!['rutina'] as List<dynamic>);
    final diaMap =
        diasRaw.firstWhere((d) => d['dia'] == day, orElse: () => null);
    if (diaMap == null) return [];
    final ejerciciosRaw = diaMap['ejercicios'] as List<dynamic>;
    return ejerciciosRaw.map((ej) {
      final m = ej as Map<String, dynamic>;
      return EjercicioAsignado(
        nombre: m['nombre'] as String,
        grupoMuscular: m['grupo_muscular'] as String,
        series: m['series'] as int,
        repeticiones: m['repeticiones'] as int,
        descansoSegundos: m['descanso_segundos'] as int,
      );
    }).toList();
  }
}
