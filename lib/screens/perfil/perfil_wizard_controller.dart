import 'dart:io' show File;               // Asegura sólo File (evita traer Platform)
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; // <-- IMPORT NECESARIO PARA XFile
import '../../services/ai_service.dart';
import 'package:gymtrack_app/services/generar_rutina_service.dart';

/// Modelo acumulador en memoria de los datos del perfil
class PerfilUsuario {
  File? imagenFile;
  String? imagenUrl; // si ya estaba cargada
  double? peso;
  double? altura;
  String? genero;
  String? nivelExperiencia;
  String? objetivo;
  int? disponibilidad; // días/semana
  int? minPorSesion;
  String? textoLesiones;
  List<String>? lesionesProcesadas;

  Uint8List? imagenBytes; // <-- añadido para Web

  bool get completosBasicos =>
      peso != null &&
      altura != null &&
      genero != null &&
      nivelExperiencia != null &&
      objetivo != null &&
      disponibilidad != null &&
      minPorSesion != null;
}

class PerfilWizardController extends ChangeNotifier {
  final String uid;
  final Box prefs = Hive.box('gt_prefs');

  PerfilUsuario data = PerfilUsuario();
  int currentStep = 0; // 0..5 (6 pasos totales)

  bool _saving = false;
  bool get saving => _saving;

  PerfilWizardController({required this.uid}) {
    _loadPersisted();
  }

  // Cargar progreso previo (step + campos) desde Hive
  void _loadPersisted() {
    currentStep = prefs.get('perfil_wizard_step_$uid', defaultValue: 0);
    final map = (prefs.get('perfil_wizard_data_$uid') as Map?)?.cast<String, dynamic>();
    if (map != null) {
      data.peso = (map['peso'] as num?)?.toDouble();
      data.altura = (map['altura'] as num?)?.toDouble();
      data.genero = map['genero'];
      data.nivelExperiencia = map['nivelExperiencia'];
      data.objetivo = map['objetivo'];
      data.disponibilidad = map['disponibilidad'];
      data.minPorSesion = map['minPorSesion'];
      data.textoLesiones = map['textoLesiones'];
      data.lesionesProcesadas = (map['lesionesProcesadas'] as List?)?.cast<String>();
      data.imagenUrl = map['imagenUrl'];
    }
  }

  void _persist() {
    prefs.put('perfil_wizard_step_$uid', currentStep);
    prefs.put('perfil_wizard_data_$uid', {
      'peso': data.peso,
      'altura': data.altura,
      'genero': data.genero,
      'nivelExperiencia': data.nivelExperiencia,
      'objetivo': data.objetivo,
      'disponibilidad': data.disponibilidad,
      'minPorSesion': data.minPorSesion,
      'textoLesiones': data.textoLesiones,
      'lesionesProcesadas': data.lesionesProcesadas,
      'imagenUrl': data.imagenUrl,
      'hasBytes': data.imagenBytes != null, // indicador (no guardamos bytes en Hive)
    });
  }

  void setImagenFile(File? f) { // uso móvil/desktop
    if (kIsWeb) return;
    data.imagenFile = f;
    data.imagenBytes = null;
    _persist();
    notifyListeners();
  }

  Future<void> setImagenXFile(XFile? xfile) async {
    if (xfile == null) {
      data.imagenFile = null;
      data.imagenBytes = null;
    } else {
      if (kIsWeb) {
        data.imagenBytes = await xfile.readAsBytes();
        data.imagenFile = null;
      } else {
        data.imagenFile = File(xfile.path);
        data.imagenBytes = null;
      }
    }
    _persist();
    notifyListeners();
  }

  void setFisicos({
    required double peso,
    required double altura,
    required String genero,
  }) {
    data.peso = peso;
    data.altura = altura;
    data.genero = genero;
    _persist();
    notifyListeners();
  }

  void setExperienciaObjetivo({
    required String nivel,
    required String objetivo,
  }) {
    data.nivelExperiencia = nivel;
    data.objetivo = objetivo;
    _persist();
    notifyListeners();
  }

  void setDisponibilidad({
    required int disponibilidad,
    required int minPorSesion,
  }) {
    data.disponibilidad = disponibilidad;
    data.minPorSesion = minPorSesion;
    _persist();
    notifyListeners();
  }

  void setLimitaciones({
    required String texto,
  }) {
    data.textoLesiones = texto.trim();
    _persist();
    notifyListeners();
  }

  void next() {
    if (currentStep < 5) {
      currentStep++;
      _persist();
      notifyListeners();
    }
  }

  void back() {
    if (currentStep > 0) {
      currentStep--;
      _persist();
      notifyListeners();
    }
  }

  double progress() => (currentStep + 1) / 6.0; // 6 pantallas

  Future<void> confirmarGuardar() async {
    if (data.nivelExperiencia == null ||
        data.objetivo == null ||
        data.disponibilidad == null ||
        data.minPorSesion == null ||
        data.peso == null ||
        data.altura == null ||
        data.genero == null) {
      throw Exception('Datos incompletos.');
    }

    _saving = true;
    notifyListeners();

    try {
      // Analizar lesiones si hay texto y aún no procesado
      if (data.textoLesiones != null &&
          data.textoLesiones!.isNotEmpty &&
          (data.lesionesProcesadas == null ||
              data.lesionesProcesadas!.isEmpty)) {
        final ai = AiService();
        data.lesionesProcesadas =
            await ai.analizarLesionesConGemini(data.textoLesiones!);
      }

      // Subir imagen si corresponde
      if (data.imagenBytes != null || data.imagenFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('usuarios')
            .child('$uid.jpg');

        if (kIsWeb && data.imagenBytes != null) {
          final meta = SettableMetadata(contentType: 'image/jpeg');
          final snap = await storageRef.putData(data.imagenBytes!, meta);
          data.imagenUrl = await snap.ref.getDownloadURL();
        } else if (!kIsWeb && data.imagenFile != null) {
          final snap = await storageRef.putFile(data.imagenFile!);
          data.imagenUrl = await snap.ref.getDownloadURL();
        }
      }
      await FirebaseFirestore.instance.collection('usuarios').doc(uid).update({
        'peso': data.peso,
        'altura': data.altura,
        'genero': data.genero,
        'nivelExperiencia': data.nivelExperiencia,
        'objetivo': data.objetivo,
        'disponibilidadSemanal': data.disponibilidad,
        'minPorSesion': data.minPorSesion,
        'lesiones': data.lesionesProcesadas ?? [],
        'perfilCompleto': true,
        if (data.imagenUrl != null) 'imagen_url': data.imagenUrl,
      });

      // 2) Generar rutina automáticamente (reutiliza la lógica centralizada)
      try {
        await RutinaService.generarRutinaParaUsuario(uid);
      } catch (e) {
        debugPrint('Generación de rutina falló: $e'); // no bloquear el guardado
      }

      // Limpiar persistencia local (ya completo)
      prefs.delete('perfil_wizard_step_$uid');
      prefs.delete('perfil_wizard_data_$uid');
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}