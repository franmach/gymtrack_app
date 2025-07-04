class Permiso {
  final String id;
  final String nombre;
  final String descripcion;

  Permiso({required this.id, required this.nombre, required this.descripcion});

  factory Permiso.fromMap(Map<String, dynamic> m) => Permiso(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        descripcion: m['descripcion'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
      };
}