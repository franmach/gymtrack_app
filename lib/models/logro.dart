class Logro {
  final String id;
  final String nombre;
  final String descripcion;
  final String condicion;

  Logro({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.condicion,
  });

  factory Logro.fromMap(Map<String, dynamic> map) => Logro(
        id: map['id'] as String,
        nombre: map['nombre'] as String,
        descripcion: map['descripcion'] as String,
        condicion: map['condicion'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'condicion': condicion,
      };
}