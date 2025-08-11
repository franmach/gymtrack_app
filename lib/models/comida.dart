import 'package:gymtrack_app/models/infoNutricional.dart';

class Comida {
  final String id;
  final String nombre;
  final String tipo; // e.g., "ensalada", "proteína"
  final String horario;
  final InfoNutricional macros;

  Comida({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.horario,
    required this.macros,
  });

  factory Comida.fromMap(Map<String, dynamic> m) => Comida(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        tipo: m['tipo'] as String,
        horario: m['horario'] as String,
        macros: InfoNutricional.fromMap(m['macros'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'tipo': tipo,
        'horario': horario,
        'macros': macros.toMap(),
      };
}