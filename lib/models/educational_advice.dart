import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo que representa un consejo educativo para un usuario.
class EducationalAdvice {
  final String id;
  final String userId;
  final String tipo; // 'nutricion' | 'lesiones' | 'habitos' | etc.
  final String mensaje;
  final DateTime fecha;
  final String fuente; // 'ai' o 'manual' (admin)
  final String createdBy; // uid o 'system' / admin id
  final int version;

  EducationalAdvice({
    required this.id,
    required this.userId,
    required this.tipo,
    required this.mensaje,
    required this.fecha,
    required this.fuente,
    required this.createdBy,
    required this.version,
  });

  factory EducationalAdvice.fromMap(Map<String, dynamic> m, String id) {
    final fechaRaw = m['fecha'];
    DateTime fecha;
    if (fechaRaw is Timestamp) {
      fecha = fechaRaw.toDate();
    } else if (fechaRaw is String) {
      fecha = DateTime.tryParse(fechaRaw) ?? DateTime.now();
    } else if (fechaRaw is DateTime) {
      fecha = fechaRaw;
    } else {
      fecha = DateTime.now();
    }

    return EducationalAdvice(
      id: id,
      userId: m['userId']?.toString() ?? '',
      tipo: m['tipo']?.toString() ?? 'general',
      mensaje: m['mensaje']?.toString() ?? '',
      fecha: fecha,
      fuente: m['fuente']?.toString() ?? 'ai',
      createdBy: m['createdBy']?.toString() ?? (m['fuente'] == 'ai' ? 'system' : ''),
      version: (m['version'] is int) ? m['version'] as int : int.tryParse('${m['version']}') ?? 1,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'tipo': tipo,
        'mensaje': mensaje,
        'fecha': Timestamp.fromDate(fecha),
        'fuente': fuente,
        'createdBy': createdBy,
        'version': version,
      };
}