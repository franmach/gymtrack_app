class RutinaEjercicio {
  final String rutinaId;
  final String ejercicioId;
  final int repeticiones;
  final int series;
  final int tiempo;

  RutinaEjercicio({
    required this.rutinaId,
    required this.ejercicioId,
    required this.repeticiones,
    required this.series,
    required this.tiempo,
  });

  factory RutinaEjercicio.fromMap(Map<String, dynamic> m) => RutinaEjercicio(
        rutinaId: m['rutina_id'] as String,
        ejercicioId: m['ejercicio_id'] as String,
        repeticiones: m['repeticiones'] as int,
        series: m['series'] as int,
        tiempo: m['tiempo'] as int,
      );

  Map<String, dynamic> toMap() => {
        'rutina_id': rutinaId,
        'ejercicio_id': ejercicioId,
        'repeticiones': repeticiones,
        'series': series,
        'tiempo': tiempo,
      };
}