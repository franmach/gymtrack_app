import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// -----------------------------------------
/// OFFLINE SERVICE
/// Maneja almacenamiento local para soportar
/// funcionalidades offline (ej: rutinas).
/// -----------------------------------------
class OfflineService {
  static const String _routineBoxName = 'offline_routines';

  /// Inicializa Hive para rutinas (llamar al inicio de la app)
  static Future<void> init() async {
    await Hive.openBox(_routineBoxName);
  }

  /// Guarda una rutina en Hive, convirtiendo los Timestamps de Firestore.
  static Future<void> saveRoutine(String userId, Map<String, dynamic> routineData) async {
    try {
      final box = Hive.box(_routineBoxName);

      // 🔹 Sanitizar datos antes de guardar
      final sanitized = _sanitizeFirestoreData(routineData);

      await box.put(userId, {
        'routine': sanitized,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('OfflineService.saveRoutine: error al guardar -> $e');
    }
  }

  /// Recupera la rutina guardada offline
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
      print('OfflineService.getRoutine: box no disponible -> $e');
      return null;
    }
  }

  /// Limpia la rutina guardada de un usuario
  static Future<void> clearRoutine(String userId) async {
    try {
      final box = Hive.box(_routineBoxName);
      await box.delete(userId);
    } catch (e) {
      print('OfflineService.clearRoutine: error -> $e');
    }
  }

  /// 🔧 Convierte Timestamps y DateTime a tipos serializables (String)
  static dynamic _sanitizeFirestoreData(dynamic data) {
    if (data is Timestamp) {
      return data.toDate().toIso8601String();
    } else if (data is DateTime) {
      return data.toIso8601String();
    } else if (data is Map) {
      return data.map((key, value) => MapEntry(key, _sanitizeFirestoreData(value)));
    } else if (data is List) {
      return data.map((e) => _sanitizeFirestoreData(e)).toList();
    } else {
      return data;
    }
  }
}