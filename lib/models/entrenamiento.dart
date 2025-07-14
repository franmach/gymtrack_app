import 'package:cloud_firestore/cloud_firestore.dart';

class Entrenamiento {
  final String id;
  final String usuarioId;
  final String rutinaId;
  final DateTime fecha;
  final int duracion;
  final String estado;
  final List<Map<String, dynamic>> ejercicios;

  Entrenamiento({
    required this.id,
    required this.usuarioId,
    required this.rutinaId,
    required this.fecha,
    required this.duracion,
    required this.estado,
    required this.ejercicios,
  });

  factory Entrenamiento.fromMap(Map<String, dynamic> map) => Entrenamiento(
        id: map['id'] as String,
        usuarioId: map['usuario_id'] as String,
        rutinaId: map['rutina_id'] as String,
        fecha: (map['fecha'] as Timestamp).toDate(),
        duracion: map['duracion'] as int,
        estado: map['estado'] as String,
        ejercicios: List<Map<String, dynamic>>.from(map['ejercicios'] as List),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'usuario_id': usuarioId,
        'rutina_id': rutinaId,
        'fecha': Timestamp.fromDate(fecha),
        'duracion': duracion,
        'estado': estado,
        'ejercicios': ejercicios,
      };
}
