import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/educational_advice.dart';
import 'package:gymtrack_app/services/user_repository.dart';
import 'package:gymtrack_app/services/ai_service.dart';

/// Servicio responsable de:
/// - Reunir datos del usuario (perfil, rutina actual, sesiones, plan nutricional)
/// - Enviar prompt unificado a un modelo generativo (Gemini)
/// - Guardar consejos en Firestore bajo `educational_advices/{userId}/advices`
/// - Proveer métodos para obtener consejos (Future y Stream)
class AdviceService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserRepository _userRepo;

  AdviceService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    UserRepository? userRepo,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _userRepo = userRepo ?? UserRepository();

  CollectionReference<Map<String, dynamic>> _userAdvicesRef(String userId) =>
      _firestore.collection('educational_advices').doc(userId).collection('advices').withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data() ?? {},
            toFirestore: (m, _) => m,
          );

  /// Convierte recursivamente datos que provienen de Firestore a objetos
  /// JSON-serializables. Convierte Timestamp/DateTime a ISO strings.
  dynamic _toSerializable(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is Map) {
      final out = <String, dynamic>{};
      value.forEach((k, v) {
        out[k.toString()] = _toSerializable(v);
      });
      return out;
    }
    if (value is List) {
      return value.map((e) => _toSerializable(e)).toList();
    }
    // tipos primitivos (num, bool, String)
    return value;
  }

  /// Genera consejos para el usuario `userId` en las categorías indicadas.
  /// Solo el propio usuario o un admin pueden invocar esta generación.
  Future<void> generateAdviceForUser(
    String userId, {
    List<String> categorias = const ['nutricion', 'lesiones', 'habitos'],
  }) async {
    final current = _auth.currentUser;
    if (current == null) throw Exception('Usuario no autenticado');

    // Seguridad básica: solo el propio usuario o admin puede generar
    if (current.uid != userId) {
      final uDoc = await _firestore.collection('usuarios').doc(current.uid).get();
      final role = uDoc.data()?['rol'] ?? 'alumno';
      if (role != 'admin') {
        throw Exception('Permisos insuficientes para generar consejos para otro usuario.');
      }
    }

    // Reusar UserRepository para traer datos principales
    final perfilRaw = await _userRepo.fetchUsuarioRaw(userId);
    final rutinaActual = await _userRepo.fetchRutinaActual(userId);
    final sesionesRaw = await _userRepo.fetchSessions(uid: userId, limit: 50);
  // Leer plan nutricional por documento (ruta nueva: nutrition_plans/{userId})
  final planSnap = await _firestore.collection('nutrition_plans').doc(userId).get();
  final nutritionPlan = planSnap.exists ? planSnap.data() : null;

    // Construir prompt unificado (breve y estructurado)
    final promptBuffer = StringBuffer()
      ..writeln('Eres un entrenador/experto en nutrición y prevención de lesiones.')
      ..writeln('Generá consejos personalizados para el siguiente usuario en las categorías solicitadas.')
      ..writeln('RESPONDE EN JSON con la estructura: { "consejos": [ { "tipo": "nutricion|lesiones|habitos", "mensaje": "..." } ] }')
      ..writeln('NO agregues texto fuera del JSON. No uses markdown.')
      ..writeln('')
      ..writeln('Categorias solicitadas: ${categorias.join(', ')}')
      ..writeln('')
      ..writeln('Perfil (objeto JSON):')
      ..writeln(jsonEncode(_toSerializable(perfilRaw ?? {})))
      ..writeln('')
      ..writeln('Rutina actual:')
      ..writeln(jsonEncode(_toSerializable(rutinaActual ?? {})))
      ..writeln('')
      ..writeln('Sesiones (hasta 50):')
      ..writeln(jsonEncode(_toSerializable(sesionesRaw)))
      ..writeln('')
      ..writeln('Plan nutricional (si existe):')
      ..writeln(jsonEncode(_toSerializable(nutritionPlan ?? {})))
      ..writeln('')
      ..writeln('Generá al menos un consejo por categoría solicitada, máximo 3 por categoría. Sé conciso (1–3 frases por consejo).');

    final prompt = promptBuffer.toString();

    // Usar la misma estrategia que AiService: GEMINI key de .env y GenerativeModel
    final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (geminiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY no configurada en .env');
    }

    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiKey);

    final response = await model.generateContent([Content.text(prompt)]);
    final rawText = response.text ?? '';

    // Limpiar posible markup (reusa método de AiService si quieres)
    final ai = AiService();
    final limpio = ai.limpiarJson(rawText);

    // Parsear JSON
    dynamic decoded;
    try {
      decoded = jsonDecode(limpio);
    } catch (e) {
      // Guardar fallback: mensaje de error como consejo tipo 'general' para trazar
      await _userAdvicesRef(userId).add({
        'userId': userId,
        'tipo': 'general',
        'mensaje': 'Error: la IA no devolvió JSON válido. Contenido bruto: ${rawText.substring(0, rawText.length > 500 ? 500 : rawText.length)}',
        'fecha': Timestamp.now(),
        'fuente': 'ai',
      });
      rethrow;
    }

    final List<Map<String, dynamic>> consejosList = [];
    if (decoded is Map && decoded['consejos'] is List) {
      for (final c in decoded['consejos']) {
        if (c is Map) {
          final tipo = (c['tipo'] ?? 'general').toString().toLowerCase();
          final mensaje = c['mensaje']?.toString() ?? '';
          consejosList.add({
            'userId': userId,
            'tipo': tipo,
            'mensaje': mensaje,
            'fecha': Timestamp.now(),
            'fuente': 'ai',
            'createdBy': current.uid, // auditoría: quien disparó la generación
            'version': 1,
          });
        }
      }
    } else if (decoded is List) {
      // Permitir también una lista simple de objetos
      for (final c in decoded) {
        if (c is Map) {
          consejosList.add({
            'userId': userId,
            'tipo': (c['tipo'] ?? 'general').toString().toLowerCase(),
            'mensaje': c['mensaje']?.toString() ?? '',
            'fecha': Timestamp.now(),
            'fuente': 'ai',
          });
        }
      }
    }

    // Guardar en Firestore
    final batch = _firestore.batch();
    final advCol = _firestore.collection('educational_advices').doc(userId).collection('advices');
    for (final m in consejosList) {
      final ref = advCol.doc();
      batch.set(ref, m);
    }
    try {
      await batch.commit();
    } on FirebaseException catch (fe) {
      print('AdviceService: FirebaseException al guardar consejos: code=${fe.code} message=${fe.message}');
      rethrow;
    } catch (e) {
      print('AdviceService: error al guardar consejos: $e');
      rethrow;
    }
  }

  /// Recupera los consejos del usuario (consulta puntual).
  /// Verifica permisos básicos: solo propietario o admin pueden leer.
  Future<List<EducationalAdvice>> getUserAdvices(String userId) async {
    final current = _auth.currentUser;
    if (current == null) throw Exception('Usuario no autenticado');

    if (current.uid != userId) {
      final uDoc = await _firestore.collection('usuarios').doc(current.uid).get();
      final role = uDoc.data()?['rol'] ?? 'alumno';
      if (role != 'admin') {
        throw Exception('Permisos insuficientes para leer consejos de otro usuario.');
      }
    }

    try {
      final snap = await _firestore
          .collection('educational_advices')
          .doc(userId)
          .collection('advices')
          .orderBy('fecha', descending: true)
          .get();

      return snap.docs.map((d) => EducationalAdvice.fromMap(d.data(), d.id)).toList();
    } on FirebaseException catch (fe) {
      print('AdviceService.getUserAdvices: FirebaseException code=${fe.code} message=${fe.message}');
      rethrow;
    } catch (e) {
      print('AdviceService.getUserAdvices error: $e');
      rethrow;
    }
  }

  /// Stream en tiempo real de consejos del usuario (para UI reactiva).
  Stream<List<EducationalAdvice>> streamUserAdvices(String userId) {
    // Nota: la seguridad final debe implementarse con reglas de Firestore.
    final coll = _firestore.collection('educational_advices').doc(userId).collection('advices').orderBy('fecha', descending: true);
    return coll.snapshots().handleError((e) {
      if (e is FirebaseException) {
        print('AdviceService.streamUserAdvices: FirebaseException code=${e.code} message=${e.message}');
      } else {
        print('AdviceService.streamUserAdvices error: $e');
      }
    }).map((qs) => qs.docs.map((d) => EducationalAdvice.fromMap(d.data(), d.id)).toList());
  }
}