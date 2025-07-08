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
}
