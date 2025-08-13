import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/models/usuario.dart'; // Ajustar si el path es diferente
import 'package:gymtrack_app/services/ai_service.dart';
import 'package:gymtrack_app/models/ejercicioAsignado.dart';

class RutinaService {
  static Future<void> generarRutinaDesdePerfil(Usuario usuario) async {
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
        lesiones: (usuario.lesiones ?? []).join(', '),
      );

      final rutinasRef = FirebaseFirestore.instance.collection('rutinas');

      //Desactivar otras rutinas del usuario
      final snapshot = await rutinasRef
          .where('uid', isEqualTo: usuario.uid)
          .where('es_actual', isEqualTo: true)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference.update({'es_actual': false});
      }

      //Agregar la nueva rutina como "actual"
      await rutinasRef.add({
        'uid': usuario.uid,
        'fecha_generacion': DateTime.now().toIso8601String(),
        'objetivo': usuario.objetivo,
        'nivel': usuario.nivelExperiencia,
        'dias_por_semana': usuario.disponibilidadSemanal,
        'min_por_sesion': usuario.minPorSesion,
        'es_actual': true,
        'rutina': (rutinaJson['rutina'] as List<dynamic>).map((dia) {
          return {
            'dia': dia['dia'],
            'ejercicios': (dia['ejercicios'] as List<dynamic>).map((ej) {
              final ejercicio =
                  EjercicioAsignado.fromMap(Map<String, dynamic>.from(ej));
              return ejercicio.toMap(); // Aquí incluimos peso si lo tiene
            }).toList(),
          };
        }).toList(),
      });

      print('Rutina generada y guardada correctamente');
    } catch (e) {
      print('Error al generar rutina: $e');
      rethrow;
    }
  }

  static Future<void> guardarRutinaAjustada({
    required String uid,
    required String nivelExperiencia,
    required String objetivo,
    required Map<String, dynamic> rutinaJson,
  }) async {
    final rutinasRef = FirebaseFirestore.instance.collection('rutinas');

    // Desactivar rutina actual
    final snapshot = await rutinasRef
        .where('uid', isEqualTo: uid)
        .where('es_actual', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'es_actual': false});
    }

    // Normalizar estructura de días
    dynamic diasRaw = rutinaJson['rutina'] ?? rutinaJson['dias'] ?? [];
    List<dynamic> diasLista;

    if (diasRaw is Map) {
      diasLista = diasRaw.entries
          .map((e) => {
                'dia': e.key,
                'ejercicios': e.value,
              })
          .toList();
    } else if (diasRaw is List) {
      diasLista = diasRaw;
    } else {
      diasLista = [];
    }

    // Guardar nueva rutina ajustada
    await rutinasRef.add({
      'uid': uid,
      'fecha_generacion': DateTime.now().toIso8601String(),
      'es_actual': true,
      'generada_automaticamente': true,
      'objetivo': objetivo,
      'nivel': rutinaJson['nivel'] ?? nivelExperiencia,
      'dias_por_semana': diasLista.length,
      'min_por_sesion': rutinaJson['min_por_sesion'] ?? 45,
      'rutina': diasLista.map((dia) {
        return {
          'dia': dia['dia'],
          'ejercicios': (dia['ejercicios'] as List<dynamic>).map((ej) {
            final ejercicio =
                EjercicioAsignado.fromMap(Map<String, dynamic>.from(ej));
            return ejercicio.toMap(); // Incluye peso si lo tiene
          }).toList(),
        };
      }).toList(),
    });

    print('✅ Rutina ajustada guardada correctamente');
  }
}
