class Usuario {
  final String uid;
  final String nombre;
  final String apellido;
  final String email;
  final int edad;
  final double peso;
  final double altura;
  final int disponibilidadSemanal;
  final int minPorSesion;
  final String nivelExperiencia;
  final String objetivo;
  final String genero;
  final String lesiones;
  final String rol;
  final DateTime fechaRegistro;
  final String? gimnasioId;

  Usuario({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.edad,
    required this.peso,
    required this.altura,
    required this.disponibilidadSemanal,
    required this.minPorSesion,
    required this.nivelExperiencia,
    required this.objetivo,
    required this.genero,
    required this.lesiones,
    required this.rol,
    required this.fechaRegistro,
    this.gimnasioId,
  });

  double get horasPorSesion => minPorSesion / 60.0;

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'edad': edad,
      'peso': peso,
      'altura': altura,
      'disponibilidadSemanal': disponibilidadSemanal,
      'minPorSesion': minPorSesion,
      'nivelExperiencia': nivelExperiencia,
      'objetivo': objetivo,
      'genero': genero,
      'lesiones': lesiones,
      'rol': 'alumno', // Asumiendo que el rol es siempre "alumno"
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'gimnasioId': gimnasioId,
    };
  }
}
