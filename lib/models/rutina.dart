import 'package:gymtrack_app/models/diaEntrenamiento.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory Rutina.fromMap(Map<String, dynamic> map) {
  return Rutina(
    id: map['id'] ?? '',
    usuarioId: map['usuario_id'] ?? '',
    fechaGeneracion: map['fecha_generacion'] is DateTime
        ? map['fecha_generacion']
        : map['fecha_generacion'] is Timestamp
            ? (map['fecha_generacion'] as Timestamp).toDate()
            : map['fecha_generacion'] is String
                ? DateTime.tryParse(map['fecha_generacion']) ?? DateTime.now()
                : DateTime.now(),
    esActual: map['es_actual'] ?? false,
    objetivo: map['objetivo'] ?? '',
    dificultad: map['dificultad'] ?? '',
    diasPorSemana: map['dias_por_semana'] ?? 0,
    horasPorSesion: (map['horas_por_sesion'] ?? 0).toDouble(),
    dias: (map['dias'] as List<dynamic>? ?? [])
        .map((d) => DiaEntrenamiento.fromMap(d as Map<String, dynamic>))
        .toList(),
  );
}
}
