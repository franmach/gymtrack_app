import 'package:cloud_firestore/cloud_firestore.dart';
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
  factory UsuarioBasico.fromMap(Map<String, dynamic> map, String uid) {
    return UsuarioBasico(
      uid: uid,
      nombre: map['nombre'] ?? '',
      apellido: map['apellido'] ?? '',
      fechaNacimiento: map['fechaNacimiento'] is Timestamp
          ? (map['fechaNacimiento'] as Timestamp).toDate()
          : map['fechaNacimiento'] is String
              ? DateTime.tryParse(map['fechaNacimiento'])
              : null,
      edad: map['edad'] ?? 0,
      email: map['email'] ?? '',
      perfilCompleto: map['perfilCompleto'] ?? false,
      fechaRegistro: map['fechaRegistro'] is Timestamp
          ? (map['fechaRegistro'] as Timestamp).toDate()
          : map['fechaRegistro'] is String
              ? DateTime.tryParse(map['fechaRegistro']) ?? DateTime.now()
              : DateTime.now(),
    );
  }
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
