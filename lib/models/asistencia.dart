import 'package:cloud_firestore/cloud_firestore.dart';

class Asistencia {
  final String id;
  final String usuarioId;
  final DateTime fecha;
  final String hora;

  Asistencia({
    required this.id,
    required this.usuarioId,
    required this.fecha,
    required this.hora,
  });

  factory Asistencia.fromMap(Map<String, dynamic> map) => Asistencia(
        id: map['id'] as String,
        usuarioId: map['usuario_id'] as String,
        fecha: map['fecha'] is Timestamp
            ? (map['fecha'] as Timestamp).toDate()
            : map['fecha'] is String
                ? DateTime.tryParse(map['fecha']) ?? DateTime.now()
                : DateTime.now(),
        hora: map['hora'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'usuario_id': usuarioId,
        'fecha': Timestamp.fromDate(fecha),
        'hora': hora,
      };
}
