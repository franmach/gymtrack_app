import 'package:cloud_firestore/cloud_firestore.dart';

class ProgresoCorporal {
  final String id;
  final String usuarioId;
  final DateTime fecha;
  final double peso;
  final double cintura;
  final double brazos;
  final double piernas;
  final double pecho;
  final String? fotoUrl;

  ProgresoCorporal({
    required this.id,
    required this.usuarioId,
    required this.fecha,
    required this.peso,
    required this.cintura,
    required this.brazos,
    required this.piernas,
    required this.pecho,
    this.fotoUrl,
  });

  factory ProgresoCorporal.fromMap(Map<String, dynamic> map) =>
      ProgresoCorporal(
        id: map['id'] as String,
        usuarioId: map['usuario_id'] as String,
        fecha: map['fecha'] is Timestamp
            ? (map['fecha'] as Timestamp).toDate()
            : map['fecha'] is String
                ? DateTime.tryParse(map['fecha']) ?? DateTime.now()
                : DateTime.now(),
        peso: (map['peso'] as num).toDouble(),
        cintura: (map['cintura'] as num).toDouble(),
        brazos: (map['brazos'] as num).toDouble(),
        piernas: (map['piernas'] as num).toDouble(),
        pecho: (map['pecho'] as num).toDouble(),
        fotoUrl: map['foto_url'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'usuario_id': usuarioId,
        'fecha': Timestamp.fromDate(fecha),
        'peso': peso,
        'cintura': cintura,
        'brazos': brazos,
        'piernas': piernas,
        'pecho': pecho,
        'foto_url': fotoUrl,
      };
}
