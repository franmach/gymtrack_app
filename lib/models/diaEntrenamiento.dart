import 'package:gymtrack_app/models/ejercicioAsignado.dart';

class DiaEntrenamiento {
  final String nombre; // Ej: "Lunes", "Martes"
  final List<EjercicioAsignado> ejercicios;

  DiaEntrenamiento({
    required this.nombre,
    required this.ejercicios,
  });

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'ejercicios': ejercicios.map((e) => e.toMap()).toList(),
  };

  factory DiaEntrenamiento.fromMap(Map<String, dynamic> map) {
  return DiaEntrenamiento(
    nombre: map['nombre'] ?? '',
    ejercicios: (map['ejercicios'] as List<dynamic>? ?? [])
        .map((e) => EjercicioAsignado.fromMap(e as Map<String, dynamic>))
        .toList(),
  );  
  }
}
