import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/models/usuario.dart';
import 'package:gymtrack_app/services/ai_service.dart';
import 'package:gymtrack_app/services/generar_rutina_service.dart';
import 'package:gymtrack_app/utils/analisis_sesiones.dart';
import 'package:gymtrack_app/models/rutina.dart';

class AjusteRutinaService {
  final FirebaseFirestore firestore;
  final AiService aiService;

  AjusteRutinaService({
    required this.firestore,
    required this.aiService,
  });

  DateTime _parseFechaGeneracion(dynamic rawFecha) {
    if (rawFecha == null) {
      throw Exception('fecha_generacion no encontrada en la rutina.');
    }

    if (rawFecha is Timestamp) {
      return rawFecha.toDate();
    } else if (rawFecha is String) {
      return DateTime.parse(rawFecha);
    } else {
      throw Exception(
          'Tipo de dato inesperado para fecha_generacion: ${rawFecha.runtimeType}');
    }
  }

  dynamic limpiarTimestamps(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    } else if (value is Map) {
      // Convierte cualquier tipo de mapa a Map<String, dynamic>
      return Map<String, dynamic>.fromEntries(
        value.entries.map(
          (e) => MapEntry(e.key.toString(), limpiarTimestamps(e.value)),
        ),
      );
    } else if (value is Iterable) {
      return value.map(limpiarTimestamps).toList();
    } else {
      return value;
    }
  }

  Future<void> ajustarRutinaMensual(Usuario usuario) async {
    final now = DateTime.now();

    final rutinaSnap = await firestore
        .collection('rutinas')
        .where('uid', isEqualTo: usuario.uid)
        .where('es_actual', isEqualTo: true)
        .limit(1)
        .get();

    if (rutinaSnap.docs.isEmpty) {
      print('❌ No se encontró rutina actual.');
      return;
    }

    final rutinaActual = rutinaSnap.docs.first.data();
    final fechaGeneracion =
        _parseFechaGeneracion(rutinaActual['fecha_generacion']);

    final diasTranscurridos = now.difference(fechaGeneracion).inDays;
    print('→ Fecha de generación: $fechaGeneracion');
    print('→ Días transcurridos desde la última rutina: $diasTranscurridos');

    if (diasTranscurridos < 30) {
      print('⏳ No corresponde ajuste: pasaron solo $diasTranscurridos días.');
      return;
    }

    print('→ Obteniendo sesiones del último mes...');
    final desde = now.subtract(const Duration(days: 30));
    final sesionesSnap = await firestore
        .collection('sesiones')
        .where('uid', isEqualTo: usuario.uid)
        .where('date', isGreaterThan: Timestamp.fromDate(desde))
        .get();

    final sesiones = sesionesSnap.docs.map((d) => d.data()).toList();
    for (var sesion in sesiones) {
      print(
          'DEBUG sesion[date]: ${sesion['date']} (${sesion['date'].runtimeType})');
    }
    print('→ Se encontraron ${sesiones.length} sesiones');

    print('→ Generando resumen mensual...');
    final resumenMensual = AnalisisSesiones.generarResumenMensual(sesiones);
    print('→ Resumen generado: ${jsonEncode(resumenMensual)}');

    print('→ Enviando datos a Gemini...');
    final perfilLimpio = limpiarTimestamps(usuario.toMap());

    final rutinaActualLimpia = limpiarTimestamps(rutinaActual);
    final resumenMensualLimpio = limpiarTimestamps(resumenMensual);
    final nuevaRutinaJson = await aiService.ajustarRutinaConHistorial(
      perfil: perfilLimpio,
      rutinaActual: rutinaActualLimpia,
      resumenMensual: resumenMensualLimpio,
    );

    print('→ Rutina ajustada recibida de Gemini');

    await RutinaService.guardarRutinaAjustada(
      uid: usuario.uid,
      nivelExperiencia: usuario.nivelExperiencia,
      objetivo: usuario.objetivo,
      rutinaJson: nuevaRutinaJson,
    );

    print('✅ Rutina ajustada y guardada con éxito.');
  }
}
