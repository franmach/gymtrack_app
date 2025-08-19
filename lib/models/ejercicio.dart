class Ejercicio {
  final String id;
  final String nombre;
  final String tipo;
  final String grupoMuscular;
  final String dificultad;
  final String equipamiento;

  Ejercicio({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.grupoMuscular,
    required this.dificultad,
    required this.equipamiento,
  });

  factory Ejercicio.fromMap(Map<String, dynamic> m) => Ejercicio(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        tipo: m['tipo'] as String,
        grupoMuscular: m['grupo_muscular'] ?? m['grupoMuscular'] ?? '',
        dificultad: m['dificultad'] as String,
        equipamiento: m['equipamiento'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'tipo': tipo,
        'grupo_muscular': grupoMuscular,
        'dificultad': dificultad,
        'equipamiento': equipamiento,
      };
}
