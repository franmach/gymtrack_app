class EjercicioAsignado {
  final String nombre;
  final String grupoMuscular;
  final int series;
  final int repeticiones;
  final int descansoSegundos;

  EjercicioAsignado({
    required this.nombre,
    required this.grupoMuscular,
    required this.series,
    required this.repeticiones,
    required this.descansoSegundos,
  });

  Map<String, dynamic> toMap() => {
    'nombre': nombre,
    'grupo_muscular': grupoMuscular,
    'series': series,
    'repeticiones': repeticiones,
    'descanso_segundos': descansoSegundos,
  };
}
