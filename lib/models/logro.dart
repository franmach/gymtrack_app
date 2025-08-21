import 'package:cloud_firestore/cloud_firestore.dart';

class Logro {
  final String id;
  final String nombre;
  final String descripcion;
  final int puntosOtorgados;
  final String tipo;
  final String? periodo;
  final DateTime otorgadoEn;

  Logro({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.puntosOtorgados,
    required this.tipo,
    this.periodo,
    required this.otorgadoEn,
  });

  static Logro fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
    SnapshotOptions? options,
  ) {
    final data = doc.data()!;
    return Logro(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      puntosOtorgados: data['puntosOtorgados'] ?? 0,
      tipo: data['tipo'] ?? '',
      periodo: data['periodo'],
      otorgadoEn: (data['otorgadoEn'] as Timestamp).toDate(),
    );
  }

  Map<String, Object?> toFirestore() => {
    'nombre': nombre,
    'descripcion': descripcion,
    'puntosOtorgados': puntosOtorgados,
    'tipo': tipo,
    if (periodo != null) 'periodo': periodo,
    'otorgadoEn': Timestamp.fromDate(otorgadoEn),
  };
}