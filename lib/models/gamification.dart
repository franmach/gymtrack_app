import 'package:meta/meta.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class GamificationStats {
  final int puntos;
  final int rachaActual;
  final int rachaRecord;
  final DateTime? ultimaAsistencia;

  const GamificationStats({
    required this.puntos,
    required this.rachaActual,
    required this.rachaRecord,
    required this.ultimaAsistencia,
  });

  static GamificationStats fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data()!;
    return GamificationStats(
      puntos: data['puntos'] ?? 0,
      rachaActual: data['rachaActual'] ?? 0,
      rachaRecord: data['rachaRecord'] ?? 0,
      ultimaAsistencia: (data['ultimaAsistencia'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, Object?> toFirestore() => {
    'puntos': puntos,
    'rachaActual': rachaActual,
    'rachaRecord': rachaRecord,
    'ultimaAsistencia': ultimaAsistencia != null ? Timestamp.fromDate(ultimaAsistencia!) : null,
  };
}


// Helpers de periodo
String keyDia(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String keySemana(DateTime d) {
  // ISO week: lunes como inicio
  final monday = d.subtract(Duration(days: d.weekday - 1));
  final firstMonday = DateTime(monday.year, 1, 1);
  final weekOfYear = ((monday.difference(firstMonday).inDays) ~/ 7 + 1);
  return '${monday.year.toString().padLeft(4, '0')}-${weekOfYear.toString().padLeft(2, '0')}';
}

String keyMes(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

// Funciones puras
bool esMismoDia(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool esAyer(DateTime hoy, DateTime ultima) {
  final ayer = hoy.subtract(const Duration(days: 1));
  return esMismoDia(ayer, ultima);
}

({int nuevaRacha, bool reinicia}) calcularRacha({
  required DateTime? ultimaAsistencia,
  required DateTime hoy,
  required int rachaActual,
}) {
  if (ultimaAsistencia == null) {
    return (nuevaRacha: 1, reinicia: false);
  }
  if (esMismoDia(hoy, ultimaAsistencia)) {
    return (nuevaRacha: rachaActual, reinicia: false);
  }
  if (esAyer(hoy, ultimaAsistencia)) {
    return (nuevaRacha: rachaActual + 1, reinicia: false);
  }
  return (nuevaRacha: 1, reinicia: true);
}