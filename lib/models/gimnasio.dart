import 'package:flutter/foundation.dart';

class Gimnasio {
  final String nombre;
  final List<String> dias_abiertos;
  final List<String> equipamiento;
  final String apertura;
  final String cierre;
  final List<String> administradores;
  final List<String> profesores;
  final List<String> alumnos;

  Gimnasio({
    required this.nombre,
    required this.dias_abiertos,
    required this.equipamiento,
    required this.apertura,
    required this.cierre,
    required this.administradores,
    required this.profesores,
    required this.alumnos,
  });

  Gimnasio copyWith({
    String? nombre,
    List<String>? dias_abiertos,
    List<String>? equipamiento,
    String? apertura,
    String? cierre,
    List<String>? administradores,
    List<String>? profesores,
    List<String>? alumnos,
  }) {
    return Gimnasio(
      nombre: nombre ?? this.nombre,
      dias_abiertos: dias_abiertos ?? this.dias_abiertos,
      equipamiento: equipamiento ?? this.equipamiento,
      apertura: apertura ?? this.apertura,
      cierre: cierre ?? this.cierre,
      administradores: administradores ?? this.administradores,
      profesores: profesores ?? this.profesores,
      alumnos: alumnos ?? this.alumnos,
    );
  }

  factory Gimnasio.fromMap(Map<String, dynamic> data) {
    final horario = data['horario'] ?? {};
    return Gimnasio(
      nombre: data['nombre'] ?? '',
      dias_abiertos: List<String>.from(data['dias_abiertos'] ?? []),
      equipamiento: List<String>.from(data['equipamiento'] ?? []),
      apertura: horario['apertura'] ?? '',
      cierre: horario['cierre'] ?? '',
      administradores: List<String>.from(data['administradores'] ?? []),
      profesores: List<String>.from(data['profesores'] ?? []),
      alumnos: List<String>.from(data['alumnos'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'dias_abiertos': dias_abiertos,
      'equipamiento': equipamiento,
      'horario': {
        'apertura': apertura,
        'cierre': cierre,
      },
      'administradores': administradores,
      'profesores': profesores,
      'alumnos': alumnos,
    };
  }
}
