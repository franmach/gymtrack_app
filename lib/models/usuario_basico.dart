class UsuarioBasico {
  final String uid;
  final String nombre;
  final String apellido;
  final DateTime? fechaNacimiento;
  final int edad;
  final String email;
  final bool perfilCompleto;
  final DateTime fechaRegistro;

  UsuarioBasico({
    required this.uid,
    required this.nombre,
    required this.apellido,
    required this.fechaNacimiento,
    required this.edad,
    required this.email,
    this.perfilCompleto = false,
    required this.fechaRegistro,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'apellido': apellido,
      'fechaNacimiento': fechaNacimiento,
      'edad': edad,
      'email': email,
      'perfilCompleto': perfilCompleto,
      'fechaRegistro': fechaRegistro.toIso8601String(),
    };
  }
}
