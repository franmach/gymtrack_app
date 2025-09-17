import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:gymtrack_app/models/progresoCorporal.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProgresoScreen extends StatefulWidget {
  const ProgresoScreen({super.key});

  @override
  State<ProgresoScreen> createState() => _ProgresoScreenState();
}

class _ProgresoScreenState extends State<ProgresoScreen> {
  final _formKey = GlobalKey<FormState>();

  double? pesoActual;
  final _pesoController = TextEditingController();
  final _cinturaController = TextEditingController();
  final _brazosController = TextEditingController();
  final _piernasController = TextEditingController();
  final _pechoController = TextEditingController();

  File? _imagen;
  bool _guardando = false;
  bool _mostrarResumen = false;
  ProgresoCorporal? _ultimoRegistro;

  @override
  void initState() {
    super.initState();
    _traerPesoUsuario();
  }

  Future<void> _traerPesoUsuario() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('usuarios').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      final peso = (data['peso'] as num?)?.toDouble();
      setState(() {
        pesoActual = peso;
        _pesoController.text = peso?.toString() ?? '';
      });
    }
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imagen = File(picked.path);
      });
    }
  }

  Future<void> _guardarProgreso() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final docRef = FirebaseFirestore.instance
          .collection('progreso_corporales')
          .doc(uid)
          .collection('registros')
          .doc();

      String? url;

      if (_imagen != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('progreso_fotos/$uid/${docRef.id}.jpg');
        await storageRef.putFile(_imagen!);
        url = await storageRef.getDownloadURL();
      }

      final progreso = ProgresoCorporal(
        id: docRef.id,
        usuarioId: uid,
        fecha: DateTime.now(),
        peso: double.tryParse(_pesoController.text) ?? 0,
        cintura: double.tryParse(_cinturaController.text) ?? 0,
        brazos: double.tryParse(_brazosController.text) ?? 0,
        piernas: double.tryParse(_piernasController.text) ?? 0,
        pecho: double.tryParse(_pechoController.text) ?? 0,
        fotoUrl: url,
      );

      setState(() {
        _ultimoRegistro = progreso;
        _mostrarResumen = true;
      });

      // Espera a que el usuario confirme antes de guardar en Firestore
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar el progreso: $e')));
    } finally {
      setState(() => _guardando = false);
    }
  }

  Future<void> _confirmarRegistro() async {
    if (_ultimoRegistro == null) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final docRef = FirebaseFirestore.instance
        .collection('progreso_corporales')
        .doc(uid)
        .collection('registros')
        .doc(_ultimoRegistro!.id);

    await docRef.set(_ultimoRegistro!.toMap());

    await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
      'peso': _ultimoRegistro!.peso,
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progreso registrado correctamente.')));
    Navigator.pop(context);
  }

  String? _validarCampoNumerico(String? value, String label) {
    if (value == null || value.isEmpty) return 'Campo requerido';
    final num = double.tryParse(value);
    if (num == null || num <= 0) return 'Ingrese un valor válido para $label';
    return null;
  }

  Widget _buildResumen(ProgresoCorporal registro) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Resumen del registro:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Text('Peso: ${registro.peso} kg'),
        Text('Cintura: ${registro.cintura} cm'),
        Text('Brazos: ${registro.brazos} cm'),
        Text('Piernas: ${registro.piernas} cm'),
        Text('Pecho: ${registro.pecho} cm'),
        if (registro.fotoUrl != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Image.file(_imagen!, height: 150),
          ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _confirmarRegistro,
                child: const Text('Confirmar y Guardar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _mostrarResumen = false;
                  });
                },
                child: const Text('Editar'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Progreso Corporal')),
      body: _guardando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Mostrar el peso actual SIEMPRE antes del formulario o resumen
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          const Icon(Icons.monitor_weight, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            pesoActual != null
                                ? 'Peso actual registrado: ${pesoActual!.toStringAsFixed(1)} kg'
                                : 'Peso actual no registrado',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_mostrarResumen && _ultimoRegistro != null)
                      _buildResumen(_ultimoRegistro!)
                    else ...[
                      TextFormField(
                        controller: _pesoController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Registrar nuevo peso (kg)',
                        ),
                        validator: (v) => _validarCampoNumerico(v, 'peso'),
                      ),
                      TextFormField(
                        controller: _cinturaController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Cintura (cm)'),
                        validator: (v) => _validarCampoNumerico(v, 'cintura'),
                      ),
                      TextFormField(
                        controller: _brazosController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Brazos (cm)'),
                        validator: (v) => _validarCampoNumerico(v, 'brazos'),
                      ),
                      TextFormField(
                        controller: _piernasController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Piernas (cm)'),
                        validator: (v) => _validarCampoNumerico(v, 'piernas'),
                      ),
                      TextFormField(
                        controller: _pechoController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'Pecho (cm)'),
                        validator: (v) => _validarCampoNumerico(v, 'pecho'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _seleccionarImagen,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Seleccionar foto (opcional)'),
                      ),
                      if (_imagen != null) ...[
                        const SizedBox(height: 12),
                        Image.file(_imagen!, height: 200),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _guardarProgreso,
                        child: const Text('Registrar Progreso'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _pesoController.dispose();
    _cinturaController.dispose();
    _brazosController.dispose();
    _piernasController.dispose();
    _pechoController.dispose();
    super.dispose();
  }
}
