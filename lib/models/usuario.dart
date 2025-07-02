class Usuario {
  final String uid;                  // generado por Firebase Auth
  final String nombre;
  final String apellido;
  final String email;
  final int edad;
  final double peso;
  final double altura;
  final int disponibilidad;
  final String nivelExperiencia;
  final String objetivo;
  final String rol;                  // alumno, admin, entrenador.
  final DateTime fechaRegistro;      

  Usuario({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.email,
    required this.edad,
    required this.peso,
    required this.altura,
    required this.disponibilidad,
    required this.nivelExperiencia,
    required this.objetivo,
    required this.rol,
    required this.fechaRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'email': email,
      'edad': edad,
      'peso': peso,
      'altura': altura,
      'disponibilidad': disponibilidad,
      'nivelExperiencia': nivelExperiencia,
      'objetivo': objetivo,
      'rol': rol,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }
}