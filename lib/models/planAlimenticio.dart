class PlanAlimenticio {
  final String id;
  final String usuarioId;
  final DateTime fechaCreacion;
  final String objetivo;
  final bool esActual;

  PlanAlimenticio({
    required this.id,
    required this.usuarioId,
    required this.fechaCreacion,
    required this.objetivo,
    required this.esActual,
  });

  factory PlanAlimenticio.fromMap(Map<String, dynamic> m) => PlanAlimenticio(
        id: m['id'] as String,
        usuarioId: m['usuario_id'] as String,
        fechaCreacion: DateTime.parse(m['fecha_creacion'] as String),
        objetivo: m['objetivo'] as String,
        esActual: m['es_actual'] as bool,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'usuario_id': usuarioId,
        'fecha_creacion': fechaCreacion.toIso8601String(),
        'objetivo': objetivo,
        'es_actual': esActual,
      };
}
