import 'package:cloud_firestore/cloud_firestore.dart';

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
  final List<String>? lesiones;
  final String rol;
  final DateTime fechaRegistro;
  final String? gimnasioId;
  final DateTime? ultimaAsistencia;

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
    this.lesiones,
    required this.rol,
    required this.fechaRegistro,
    this.gimnasioId,
    this.ultimaAsistencia,
  });

  factory Usuario.fromMap(Map<String, dynamic> data, String uid) {
    return Usuario(
      uid: uid,
      nombre: data['nombre'] ?? '',
      apellido: data['apellido'] ?? '',
      email: data['email'] ?? '',
      edad: data['edad'] ?? 0,
      peso: (data['peso'] ?? 0).toDouble(),
      altura: (data['altura'] ?? 0).toDouble(),
      disponibilidadSemanal: data['disponibilidadSemanal'] ?? 0,
      minPorSesion: data['minPorSesion'] ?? 0,
      nivelExperiencia: data['nivelExperiencia'] ?? '',
      objetivo: data['objetivo'] ?? '',
      genero: data['genero'] ?? '',
      lesiones: (data['lesiones'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      rol: data['rol'] ?? 'alumno',
      fechaRegistro:
          DateTime.tryParse(data['fechaRegistro'] ?? '') ?? DateTime.now(),
      gimnasioId: data['gimnasioId'],
      ultimaAsistencia: data['ultimaAsistencia'] is Timestamp
          ? (data['ultimaAsistencia'] as Timestamp).toDate()
          : data['ultimaAsistencia'] is String
              ? DateTime.tryParse(data['ultimaAsistencia'])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
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
      'lesiones': lesiones ?? [],
      'rol': rol,
      'fechaRegistro': fechaRegistro.toIso8601String(),
      'gimnasioId': gimnasioId,
      'ultimaAsistencia': ultimaAsistencia != null
          ? Timestamp.fromDate(ultimaAsistencia!)
          : null,
    };
  }
}
