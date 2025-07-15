import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/screens/perfil/perfil_screen.dart';
import 'dart:convert';
import 'package:gymtrack_app/models/usuario.dart';
import 'package:gymtrack_app/services/ai_service.dart';

class CompletarPerfilScreen extends StatefulWidget {
  final String uid;
  const CompletarPerfilScreen({super.key, required this.uid});

  @override
  State<CompletarPerfilScreen> createState() => _CompletarPerfilScreenState();
}

class _CompletarPerfilScreenState extends State<CompletarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? fechaNacimiento;
  double peso = 0;
  double altura = 0;
  int disponibilidad = 0;
  String nivelExperiencia = '';
  String objetivo = '';
  String genero = '';
  String lesiones = '';
  int minPorSesion = 0;

  final niveles = [
    'Principiante (0–1 año)',
    'Intermedio (1–3 años)',
    'Avanzado (3+ años)',
  ];

  final objetivos = [
    'Bajar de peso',
    'Ganar músculo',
    'Tonificar',
    'Mejorar resistencia',
  ];

  final generos = [
    'Masculino',
    'Femenino',
    'Otro',
    'Prefiero no decirlo',
  ];

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.uid)
          .update({
        'peso': peso,
        'altura': altura,
        'disponibilidadSemanal': disponibilidad,
        'minPorSesion': minPorSesion,
        'nivelExperiencia': nivelExperiencia,
        'objetivo': objetivo,
        'genero': genero,
        'lesiones': lesiones,
        'perfilCompleto': true,
        'gimnasioId': 'gimnasio_point',
      });

      //Obtener datos desde Firestore
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(widget.uid)
          .get();
      final data = doc.data();

      //Construir el objeto Usuario
      final usuario = Usuario(
        uid: widget.uid,
        nombre: data?['nombre'] ?? '',
        apellido: data?['apellido'] ?? '',
        email: data?['email'] ?? '',
        edad: data?['edad'] ?? 0,
        peso: peso,
        altura: altura,
        disponibilidadSemanal: disponibilidad,
        minPorSesion: minPorSesion,
        nivelExperiencia: nivelExperiencia,
        objetivo: objetivo,
        genero: genero,
        lesiones: lesiones,
        rol: data?['rol'] ?? 'alumno',
        fechaRegistro:
            DateTime.tryParse(data?['fechaRegistro'] ?? '') ?? DateTime.now(),
        gimnasioId: 'gimnasio_point', // Asignar un gimnasio por defecto
      );

// 3. Generar rutina con IA
      await generarRutinaDesdePerfil(usuario);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil completado con éxito')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PerfilScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar perfil: $e')),
      );
    }
  }

  Future<void> generarRutinaDesdePerfil(Usuario usuario) async {
    print('Llamando a Gemini...');
    final ai = AiService();

    try {
      final rutinaJson = await ai.generarRutinaComoJson(
        edad: usuario.edad,
        peso: usuario.peso,
        altura: usuario.altura,
        nivel: usuario.nivelExperiencia,
        objetivo: usuario.objetivo,
        dias: usuario.disponibilidadSemanal,
        minPorSesion: usuario.minPorSesion,
        genero: usuario.genero,
        lesiones: usuario.lesiones ?? '',
      );

      await FirebaseFirestore.instance
          .collection('rutinas')
          .doc(usuario.uid)
          .set({
        'uid': usuario.uid,
        'fecha_generacion': DateTime.now().toIso8601String(),
        'objetivo': usuario.objetivo,
        'nivel': usuario.nivelExperiencia,
        'dias_por_semana': usuario.disponibilidadSemanal,
        'min_por_sesion': usuario.minPorSesion,
        'es_actual': true,
        'rutina': rutinaJson['rutina'],
        'gimnasioId': 'gimnasio_point',
      });

      print('✅ Rutina generada y guardada correctamente');
    } catch (e) {
      print('❌ Error al generar rutina: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completar Perfil')),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Peso (kg)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final num = double.tryParse(value ?? '');
                        if (num == null || num < 30 || num > 300) {
                          return 'Peso entre 30 y 300 kg';
                        }
                        return null;
                      },
                      onSaved: (value) => peso = double.parse(value!),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Altura (cm)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final num = double.tryParse(value ?? '');
                        if (num == null || num < 50 || num > 250) {
                          return 'Altura inválida (50–250 cm)';
                        }
                        return null;
                      },
                      onSaved: (value) => altura = double.parse(value!),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField(
                      decoration: const InputDecoration(
                          labelText: 'Nivel de experiencia'),
                      items: niveles
                          .map((nivel) => DropdownMenuItem(
                              value: nivel, child: Text(nivel)))
                          .toList(),
                      onChanged: (value) => nivelExperiencia = value!,
                      validator: (value) =>
                          value == null ? 'Campo obligatorio' : null,
                      onSaved: (value) => nivelExperiencia = value!,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField(
                      decoration:
                          const InputDecoration(labelText: 'Objetivo físico'),
                      items: objetivos
                          .map((obj) =>
                              DropdownMenuItem(value: obj, child: Text(obj)))
                          .toList(),
                      onChanged: (value) => objetivo = value!,
                      validator: (value) =>
                          value == null ? 'Campo obligatorio' : null,
                      onSaved: (value) => objetivo = value!,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Disponibilidad semanal (1-7 días)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final num = int.tryParse(value ?? '');
                        if (num == null || num < 1 || num > 7) {
                          return 'Entre 1 y 7 días';
                        }
                        return null;
                      },
                      onSaved: (value) => disponibilidad = int.parse(value!),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText:
                              'Duración aproximada por sesión (en minutos)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final num = int.tryParse(value ?? '');
                        if (num == null || num < 45 || num > 180) {
                          return 'Entre 45 y 180 minutos';
                        }
                        return null;
                      },
                      onSaved: (value) => minPorSesion = int.parse(value!),
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField(
                      decoration: const InputDecoration(labelText: 'Género'),
                      items: generos
                          .map((gen) =>
                              DropdownMenuItem(value: gen, child: Text(gen)))
                          .toList(),
                      onChanged: (value) => genero = value!,
                      validator: (value) =>
                          value == null ? 'Campo obligatorio' : null,
                      onSaved: (value) => genero = value!,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Limitaciones físicas o lesiones'),
                      maxLines: 3,
                      onSaved: (value) => lesiones = value ?? '',
                    ),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _guardarPerfil,
                      child: const Text('Guardar y continuar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
