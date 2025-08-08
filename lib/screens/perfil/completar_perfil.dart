import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/screens/perfil/perfil_screen.dart';
import 'package:gymtrack_app/services/ai_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
  String textoLesiones = '';
  List<String>? lesionesProcesadas;
  int minPorSesion = 0;
  File? imagenSeleccionada;
  String gimnasioId = 'gimnasio_point'; // Fijo por ahora

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

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        imagenSeleccionada = File(pickedFile.path);
      });
    }
  }

  Future<void> tomarFotoConCamara() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        imagenSeleccionada = File(pickedFile.path);
      });
    } else {
      print('No se seleccionó ninguna imagen.');
    }
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final ai = AiService();
    lesionesProcesadas = await ai.analizarLesionesConGemini(textoLesiones);

    String? urlImagen;

    // SUBIR IMAGEN A STORAGE SI HAY UNA
    try {
      if (imagenSeleccionada != null && imagenSeleccionada!.existsSync()) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('usuarios')
            .child('${widget.uid}.jpg');

        final uploadTask = storageRef.putFile(imagenSeleccionada!);

        final snapshot = await uploadTask.whenComplete(() => null);
        urlImagen = await snapshot.ref.getDownloadURL();
      }
    } catch (e) {
      print("❌ Error al subir imagen: $e");
    }

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
        'lesiones': lesionesProcesadas,
        'perfilCompleto': true,
        if (urlImagen != null) 'imagen_url': urlImagen,
        'gimnasioId': gimnasioId,
      });

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: tomarFotoConCamara,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Tomar foto'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: _seleccionarImagen,
                          icon: const Icon(Icons.photo),
                          label: const Text('Galería'),
                        ),
                      ],
                    ),
                    if (imagenSeleccionada != null)
                      Image.file(imagenSeleccionada!, height: 150),
                    const SizedBox(height: 16),
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
                      onSaved: (value) => textoLesiones = value?.trim() ?? '',
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
