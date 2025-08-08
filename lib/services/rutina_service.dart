import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymtrack_app/models/usuario.dart'; // Ajustar si el path es diferente
import 'package:gymtrack_app/services/ai_service.dart';

class RutinaService {
  static Future<void> generarRutinaDesdePerfil(Usuario usuario) async {
    print('Llamando a Gemini...');
    final ai = AiService();

    try {
      //Obtener rutina desde AI
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
        gimnasioId: usuario.gimnasioId,
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
        'rutina': rutinaJson['rutina'],
      });

      print('Rutina generada y guardada correctamente');
    } catch (e) {
      print('Error al generar rutina: $e');
      rethrow;
    }
  }
}
