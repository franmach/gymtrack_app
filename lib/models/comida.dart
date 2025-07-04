class Comida {
  final String id;
  final String nombre;
  final String tipo;
  final double calorias;
  final String horario;

  Comida({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.calorias,
    required this.horario,
  });

  /// Convierte un Map (por ejemplo desde Firestore) a un objeto Comida
  factory Comida.fromMap(Map<String, dynamic> map) {
    return Comida(
      id: map['id'] as String,
      nombre: map['nombre'] as String,
      tipo: map['tipo'] as String,
      calorias: (map['calorias'] as num).toDouble(),
      horario: map['horario'] as String,
    );
  }

  /// Convierte este objeto en un Map (para guardar en Firestore o JSON)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'calorias': calorias,
      'horario': horario,
    };
  }
}