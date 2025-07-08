import 'package:gymtrack_app/models/diaEntrenamiento.dart';

class Rutina {
  final String id;
  final String usuarioId;
  final DateTime fechaGeneracion;
  final bool esActual;
  final String objetivo;
  final String dificultad;
  final int diasPorSemana;
  final double horasPorSesion;
  final List<DiaEntrenamiento> dias;

  Rutina({
    required this.id,
    required this.usuarioId,
    required this.fechaGeneracion,
    required this.esActual,
    required this.objetivo,
    required this.dificultad,
    required this.diasPorSemana,
    required this.horasPorSesion,
    required this.dias,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'usuario_id': usuarioId,
    'fecha_generacion': fechaGeneracion.toIso8601String(),
    'es_actual': esActual,
    'objetivo': objetivo,
    'dificultad': dificultad,
    'dias_por_semana': diasPorSemana,
    'horas_por_sesion': horasPorSesion,
    'dias': dias.map((d) => d.toMap()).toList(),
  };
}
