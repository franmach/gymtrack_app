import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart'; // <-- nuevo para leer días del gimnasio

class AiService {
  late final GenerativeModel _model;

  AiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY no encontrada en .env');
    }

    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
  }

  String limpiarJson(String respuesta) {
    return respuesta.replaceAll('```json', '').replaceAll('```', '').trim();
  }

  /// Fuerza que campos numéricos tengan enteros (reemplaza palabras como Máximo, Fallo, etc.)
  String _sanitizeNumericFields(String raw) {
    final fields = ['series', 'repeticiones', 'descanso_segundos', 'peso'];
    var txt = raw;

    for (final f in fields) {
      final reg = RegExp('"$f"\\s*:\\s*([^,}\\n]+)');
      txt = txt.replaceAllMapped(reg, (m) {
        final original = m.group(1)!.trim();

        // Si ya es entero (o decimal para peso) válido, dejar
        final isInt = RegExp(r'^[0-9]+$').hasMatch(original);
        final isDouble =
            f == 'peso' && RegExp(r'^[0-9]+(\\.[0-9]+)?$').hasMatch(original);

        if (isInt || isDouble) return m.group(0)!;

        // Limpiar comillas si las tuviera
        final cleaned = original.replaceAll('"', '').toLowerCase();

        // Heurísticas: palabras que significan "máximo/fallo"
        if (cleaned.contains('max') ||
            cleaned.contains('máx') ||
            cleaned.contains('fallo')) {
          // Valor razonable por defecto
          final defaultMax = f == 'repeticiones'
              ? 12
              : (f == 'series' ? 3 : (f == 'descanso_segundos' ? 60 : 0));
          return '"$f": $defaultMax';
        }

        // Si había rango (ej: 8-12) tomar el mayor
        final rango =
            RegExp(r'([0-9]{1,3})\s*-\s*([0-9]{1,3})').firstMatch(cleaned);
        if (rango != null) {
          return '"$f": ${rango.group(2)}';
        }

        // Extraer primer número existente
        final numMatch = RegExp(r'([0-9]{1,3})').firstMatch(cleaned);
        if (numMatch != null) {
          return '"$f": ${numMatch.group(1)}';
        }

        // Fallback
        final fallback = f == 'repeticiones'
            ? 10
            : f == 'series'
                ? 3
                : f == 'descanso_segundos'
                    ? 60
                    : 0;
        return '"$f": $fallback';
      });
    }
    return txt;
  }

  /// Normaliza nombre de día a capitalizado en español.
  String _normalizarDia(String dia) {
    dia = dia.trim().toLowerCase();
    switch (dia) {
      case 'lunes':
        return 'Lunes';
      case 'martes':
        return 'Martes';
      case 'miercoles':
      case 'miércoles':
        return 'Miércoles';
      case 'jueves':
        return 'Jueves';
      case 'viernes':
        return 'Viernes';
      case 'sabado':
      case 'sábado':
        return 'Sábado';
      case 'domingo':
        return 'Domingo';
      default:
        return dia[0].toUpperCase() + dia.substring(1);
    }
  }

  /// Obtiene días abiertos del gimnasio (normalizados) o semana completa si falla.
  Future<List<String>> _obtenerDiasGimnasio(String? gimnasioId) async {
    const semanaOrden = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    if (gimnasioId == null) return semanaOrden;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('gimnasios')
          .doc(gimnasioId)
          .get();
      if (!doc.exists) return semanaOrden;
      final data = doc.data()!;
      final dias = (data['dias_abiertos'] as List?)
              ?.map((d) => _normalizarDia(d.toString()))
              .toSet() ??
          {};
      return semanaOrden.where(dias.contains).toList();
    } catch (_) {
      return semanaOrden;
    }
  }

  Map<String, dynamic> _postProcessRutina({
    required Map<String, dynamic> parsed,
    required List<String> diasAsignados,
  }) {
    if (parsed['rutina'] is! List) return parsed;
    final allowedSet = diasAsignados.toSet();

    List dias = (parsed['rutina'] as List).where((d) {
      if (d is! Map) return false;
      final diaNombre = _normalizarDia(d['dia']?.toString() ?? '');
      if (!allowedSet.contains(diaNombre)) return false;
      final ejercicios = d['ejercicios'];
      if (ejercicios is! List || ejercicios.isEmpty) return false;
      final esDescanso = ejercicios.any((e) {
        final nombre = (e['nombre'] ?? '').toString().toLowerCase();
        return nombre.contains('descanso');
      });
      return !esDescanso;
    }).toList();

    // Forzar exactamente los días asignados en orden. Si falta alguno, crear placeholder simple.
    final mapaDias = {for (var d in dias) _normalizarDia(d['dia']): d};
    final List result = [];
    for (final dia in diasAsignados) {
      if (mapaDias.containsKey(dia)) {
        result.add(mapaDias[dia]);
      } else if (dias.isNotEmpty) {
        // Clonar primer día como plantilla y ajustar nombre
        final plantilla = Map<String, dynamic>.from(dias.first);
        plantilla['dia'] = dia;
        result.add(plantilla);
      }
    }
    parsed['rutina'] = result;
    return parsed;
  }

  Future<Map<String, dynamic>> generarRutinaComoJson({
    required int edad,
    required double peso,
    required double altura,
    required String nivel,
    required String objetivo,
    required int disponibilidadSemanal,
    required int minPorSesion,
    required String genero,
    required String lesiones,
    String? gimnasioId,
  }) async {
    // 1. Días abiertos del gimnasio
    final diasGimnasio = await _obtenerDiasGimnasio(gimnasioId);
    // 2. Días asignados = primeros N según disponibilidad del usuario
    final diasAsignados = diasGimnasio.take(disponibilidadSemanal).toList();
    // 3. Cadena para el prompt
    final listaDias = diasAsignados.join(', ');

    final prompt = '''
Actuás como entrenador personal experto.
Generá una rutina semanal basada en los datos del usuario.

REGLAS ESTRICTAS DE FORMATO:
- RESPONDE SOLO JSON válido (sin markdown, sin ```).
- Raíz: {"rutina": [ ... ] }
- Debes generar EXACTAMENTE ${diasAsignados.length} objetos de día, con estos días y SOLO estos días (en este orden): [$listaDias].
- No incluyas días de descanso ni objetos vacíos.
- Cada día: "dia": "<Nombre>", "ejercicios": [ ... ].
- Ejercicio: nombre, grupo_muscular, series (int), repeticiones (int), descanso_segundos (int), peso (opcional numérico si aplica, NO texto).
- No uses palabras como Máximo, Fallo, AMRAP, rango "8-12". Sustituye por un único número estimado.
- No repitas ejercicios idénticos seguidos sin necesidad.
- NO agregues texto fuera del JSON.

DATOS USUARIO:
Edad: $edad
Peso: $peso
Altura: $altura
Género: $genero
Nivel: $nivel
Objetivo: $objetivo
Días entrenamiento (usuario): $disponibilidadSemanal
Días asignados (según gimnasio): ${diasAsignados.length}
Min por sesión: $minPorSesion
Lesiones: $lesiones
GimnasioId: ${gimnasioId ?? 'N/A'}

EJEMPLO DE FORMATO (NO copiar literal):
{
  "rutina": [
    {
      "dia": "${diasAsignados.isNotEmpty ? diasAsignados.first : 'Lunes'}",
      "ejercicios": [
        {
          "nombre": "Sentadilla",
          "grupo_muscular": "Piernas",
          "series": 4,
          "repeticiones": 10,
          "descanso_segundos": 60,
          "peso": 20
        }
      ]
    }
  ]
}
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final output = response.text;
    if (output == null) throw Exception('Respuesta vacía de Gemini');

    var cleaned = limpiarJson(output);
    cleaned = _sanitizeNumericFields(cleaned);

    Map<String, dynamic> parsed;
    try {
      parsed = jsonDecode(cleaned);
    } catch (e) {
      throw FormatException(
          'La respuesta no es un JSON válido tras sanitizar: $e\n\nContenido:\n$cleaned');
    }

    parsed = _postProcessRutina(
      parsed: parsed,
      diasAsignados: diasAsignados,
    );
    return parsed;
  }

  Future<List<String>> analizarLesionesConGemini(String texto) async {
    final prompt = '''
Sos un analizador médico simplificado. Tu tarea es detectar ÚNICAMENTE lesiones o limitaciones físicas del siguiente texto.

Reglas estrictas:
- Extraé SOLO lesiones o partes del cuerpo afectadas (ejemplo: "rodilla", "lumbalgia", "hombro").
- Ignorá cualquier otra cosa irrelevante: chistes, insultos, números, frases sin sentido, síntomas vagos ("me duele todo", "estoy roto").
- Si no se detecta ninguna lesión real, devolvé una lista vacía.
- La respuesta DEBE ser SIEMPRE un JSON válido con un array de strings, sin comentarios, sin markdown, sin texto adicional, sin caracteres extra.
- NO inventes lesiones. Si no estás seguro, devolvé lista vacía.

Texto del usuario:
"$texto"

Respondé SOLO con un array JSON plano, por ejemplo:
["rodilla", "columna cervical"]

o si no hay nada relevante:
[]
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    String? output = response.text;

    if (output == null) {
      throw Exception('Respuesta vacía de Gemini');
    }

    // Limpiar posibles backticks y markdown
    output = output.replaceAll('```json', '').replaceAll('```', '').trim();

    try {
      final decoded = jsonDecode(output);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Error al parsear JSON de lesiones: $e\nContenido:\n$output');
      return [];
    }
  }

  Future<Map<String, dynamic>> ajustarRutinaConHistorial({
    required Map<String, dynamic> perfil,
    required Map<String, dynamic> rutinaActual,
    required Map<String, dynamic> resumenMensual,
  }) async {
    final prompt = '''
Sos un entrenador personal experto. Tu tarea es AJUSTAR la rutina actual de un usuario en base a su progreso real del último mes.

NO generes una rutina nueva desde cero.

Mantené la estructura general de la rutina actual:
- Misma cantidad de días por semana
- Ejercicios similares o los mismos (si dieron resultado)
- Solo cambiá repeticiones, series o peso cuando sea necesario

Tené en cuenta:
- Si un ejercicio fue completado con facilidad, podés aumentar ligeramente las repeticiones, series o peso.
- Si un ejercicio fue marcado como incompleto o difícil, podés reducir el volumen o el peso, o reemplazarlo.
- Evitá mantener ejercicios que el usuario falló repetidamente.

La respuesta debe ser SOLO un JSON con esta estructura:

{
  "dias": {
    "Lunes": [
      {
        "nombre": "Press banca",
        "grupoMuscular": "Pecho",
        "series": 4,
        "repeticiones": 10,
        "peso": 22
      },
      ...
    ],
    "Miércoles": [ ... ]
  }
}

No expliques tu decisión. No uses texto fuera del JSON. Solo devolvé el JSON ajustado.
''';

    final response = await _model.generateContent([
      Content.text(prompt),
      Content.text('Perfil del usuario:\n${jsonEncode(perfil)}'),
      Content.text('Rutina actual:\n${jsonEncode(rutinaActual)}'),
      Content.text('Resumen mensual:\n${jsonEncode(resumenMensual)}'),
    ]);

    final rawText = response.text ?? '{}';
    final limpio = limpiarJson(rawText);

    try {
      final decoded = json.decode(limpio);
      return decoded['dias'] != null ? {'dias': decoded['dias']} : decoded;
    } catch (e) {
      throw FormatException(
          'La respuesta de Gemini no es JSON válido: $e\nContenido:\n$limpio');
    }
  }
}
