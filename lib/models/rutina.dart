class Rutina {
  final String id;
  final String usuarioId;
  final DateTime fechaGeneracion;
  final bool esActual;
  final String objetivo;
  final String dificultad;
  final int diasPorSemana;

  Rutina({
    required this.id,
    required this.usuarioId,
    required this.fechaGeneracion,
    required this.esActual,
    required this.objetivo,
    required this.dificultad,
    required this.diasPorSemana,
  });

  factory Rutina.fromMap(Map<String, dynamic> m) => Rutina(
        id: m['id'] as String,
        usuarioId: m['usuario_id'] as String,
        fechaGeneracion: DateTime.parse(m['fecha_generacion'] as String),
        esActual: m['es_actual'] as bool,
        objetivo: m['objetivo'] as String,
        dificultad: m['dificultad'] as String,
        diasPorSemana: m['dias_por_semana'] as int,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'usuario_id': usuarioId,
        'fecha_generacion': fechaGeneracion.toIso8601String(),
        'es_actual': esActual,
        'objetivo': objetivo,
        'dificultad': dificultad,
        'dias_por_semana': diasPorSemana,
      };
}