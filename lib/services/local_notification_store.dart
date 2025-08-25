import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocalNotificationStore {
  static const _remindersBox = 'gt_reminders';
  static const _prefsBox = 'gt_prefs';

  // ---------- RECORDATORIOS ----------
  Future<void> upsertReminder(Map<String, dynamic> reminder) async {
    final box = Hive.box(_remindersBox);
    final id = reminder['id'] as String;

    final fixed = Map<String, dynamic>.from(reminder);
    if (reminder.containsKey('diasSemana')) {
      fixed['diasSemana'] = List<int>.from(reminder['diasSemana'] ?? <int>[]);
    }
    await box.put(id, fixed);
  }

  List<Map<String, dynamic>> listReminders() {
    final box = Hive.box(_remindersBox);
    return box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> deleteReminder(String id) async {
    final box = Hive.box(_remindersBox);
    await box.delete(id);
  }

  Future<void> deleteMotivationalReminders() async {
    final box = Hive.box('gt_reminders');
    final keysToDelete = box.keys.where((key) {
      final reminder = box.get(key);
      return reminder is Map && reminder['tipo'] == 'motivacional';
    }).toList();
    for (final key in keysToDelete) {
      await box.delete(key);
    }
  }

  // ---------- PREFERENCIAS ----------
  Future<void> savePrefs(Map<String, dynamic> prefs) async {
    final box = Hive.box(_prefsBox);
    await box.put('prefs', prefs);
  }

  Map<String, dynamic> loadPrefs() {
    final box = Hive.box(_prefsBox);
    final raw = box.get('prefs');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {
      'habilitadas': true,
      'diasActivos': {
        1: true,
        2: true,
        3: true,
        4: true,
        5: true,
        6: false,
        7: false
      },
      'motivacionales': true,
    };
  }

  // CAMBIO: métodos para motivacionales automáticas
  Future<void> setMotivationalEnabled(bool enabled) async {
    final prefs = loadPrefs();
    prefs['motivacionales'] = enabled;
    await savePrefs(prefs);
  }

  bool areMotivationalEnabled() {
    final prefs = loadPrefs();
    return prefs['motivacionales'] ?? true;
  }

  ValueListenable<Box> get remindersListenable =>
      Hive.box('gt_reminders').listenable();
}
