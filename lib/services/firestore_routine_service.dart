import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/models/ejercicioAsignado.dart';
import 'routine_service.dart';
// 🔹 Importamos el OfflineService
import 'package:gymtrack_app/services/offline_service.dart';

/// Servicio real que carga la rutina generada desde Firestore
class FirestoreRoutineService implements RoutineService {
  @override
  Future<List<String>> fetchRoutineDays(String userId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('rutinas')
          .where('uid', isEqualTo: userId)
          .where('es_actual', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return [];

      final rutinaData = query.docs.first.data();

      // 🔹 Guardamos rutina completa offline
      await OfflineService.saveRoutine(userId, rutinaData);

      final diasRaw = (rutinaData['rutina'] as List<dynamic>);
      return diasRaw.map((d) => d['dia'] as String).toList();
    } catch (e) {
      print('❌ Error al obtener rutina: $e');
      return [];
    }
  }

  @override
  Future<List<EjercicioAsignado>> fetchExercisesForDay(
      String userId, String day) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('rutinas')
          .where('uid', isEqualTo: userId)
          .where('es_actual', isEqualTo: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return [];

      final rutinaData = query.docs.first.data();

      // 🔹 Guardamos rutina completa offline
      await OfflineService.saveRoutine(userId, rutinaData);

      final diasRaw = (rutinaData['rutina'] as List<dynamic>);
      final diaMap = diasRaw.firstWhere(
        (d) => d['dia'] == day,
        orElse: () => null,
      );
      if (diaMap == null) return [];

      final ejerciciosRaw = diaMap['ejercicios'] as List<dynamic>;

      // 🔹 Convertimos cada ejercicio usando el factory constructor
      return ejerciciosRaw
          .map((ej) => EjercicioAsignado.fromMap(ej as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error al obtener ejercicios: $e');
      return [];
    }
  }
}
