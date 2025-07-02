import 'package:cloud_firestore/cloud_firestore.dart';

class Notificacion {
  final String id;
  final String usuarioId;
  final String tipo;
  final String mensaje;
  final DateTime programadaPara;

  Notificacion({
    required this.id,
    required this.usuarioId,
    required this.tipo,
    required this.mensaje,
    required this.programadaPara,
  });

  factory Notificacion.fromMap(Map<String, dynamic> map) => Notificacion(
        id: map['id'] as String,
        usuarioId: map['usuario_id'] as String,
        tipo: map['tipo'] as String,
        mensaje: map['mensaje'] as String,
        programadaPara: (map['programada_para'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'usuario_id': usuarioId,
        'tipo': tipo,
        'mensaje': mensaje,
        'programada_para': Timestamp.fromDate(programadaPara),
      };
}