import 'package:hive/hive.dart';

/// -----------------------------------------
/// OFFLINE SERVICE
/// Maneja almacenamiento local para soportar
/// funcionalidades offline (ej: rutinas).
/// -----------------------------------------
class OfflineService {
  static const String _routineBoxName = 'offline_routines';

  static Future<void> init() async {
    // 🔹 Abrimos el box al inicio de la app
    await Hive.openBox(_routineBoxName);
  }

  static Future<void> saveRoutine(String userId, Map<String, dynamic> routineData) async {
    final box = Hive.box(_routineBoxName);
    await box.put(userId, {
      'routine': routineData,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }

  static Map<String, dynamic>? getRoutine(String userId) {
    try {
      final box = Hive.box(_routineBoxName);
      final data = box.get(userId) as Map?;

      if (data == null) return null;

      return {
        'routine': data['routine'],
        'lastUpdated': data['lastUpdated'],
      };
    } catch (e) {
      // Si el box no está abierto o hay cualquier error de Hive, devolvemos null
      // para que la app pueda continuar en modo online o mostrar un mensaje.
      // No usamos debugPrint aquí para evitar dependencias de Flutter en este servicio.
      print('OfflineService.getRoutine: box no disponible: $e');
      return null;
    }
  }

  static Future<void> clearRoutine(String userId) async {
    final box = Hive.box(_routineBoxName);
    await box.delete(userId);
  }
}

