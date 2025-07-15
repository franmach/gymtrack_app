import 'package:gymtrack_app/models/ejercicioAsignado.dart';

/// Interfaz para obtener la rutina del día
abstract class RoutineService {
  Future<List<String>> fetchRoutineDays(String userId);
  Future<List<EjercicioAsignado>> fetchExercisesForDay(String userId, String day);
}
