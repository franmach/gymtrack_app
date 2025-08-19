class EjercicioAsignado {
  final String nombre;
  final String grupoMuscular;
  final int series;
  final int repeticiones;
  final int descansoSegundos;
  final double? peso; 

  EjercicioAsignado({
    required this.nombre,
    required this.grupoMuscular,
    required this.series,
    required this.repeticiones,
    required this.descansoSegundos,
    this.peso,
  });

  factory EjercicioAsignado.fromMap(Map<String, dynamic> map) {
    return EjercicioAsignado(
      nombre: map['nombre'] ?? '',
      grupoMuscular: map['grupo_muscular'] ?? '',
      series: map['series'] ?? 0,
      repeticiones: map['repeticiones'] ?? 0,
      descansoSegundos: map['descanso_segundos'] ?? 0,
      peso: map['peso'] != null ? (map['peso'] as num).toDouble() : null,
    );
  }

  /// Convertir a Map para guardar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'grupo_muscular': grupoMuscular,
      'series': series,
      'repeticiones': repeticiones,
      'descanso_segundos': descansoSegundos,
      if (peso != null) 'peso': peso, // Solo lo guarda si no es null
    };
  }
}
