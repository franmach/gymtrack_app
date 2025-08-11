import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  Future<Map<String, dynamic>> generarRutinaComoJson({
    required int edad,
    required double peso,
    required double altura,
    required String nivel,
    required String objetivo,
    required int dias,
    required int minPorSesion,
    required String genero,
    required String lesiones,
  }) async {
    final prompt = '''
Generame una rutina semanal de entrenamiento para un usuario con los siguientes datos:

Edad: $edad años
Peso: $peso kg
Altura: $altura cm
Género: $genero
Nivel de experiencia: $nivel
Objetivo físico: $objetivo
Días disponibles por semana: $dias
Duración por sesión: $minPorSesion minutos
Lesiones: $lesiones

Respondé solamente con un JSON **válido**, sin explicaciones ni formato markdown, sin comentarios, sin comillas raras ni backticks. Solo el JSON puro.

Formato esperado:
{
  "rutina": [
    {
      "dia": "Lunes",
      "ejercicios": [
        {
          "nombre": "Sentadillas",
          "grupo_muscular": "Piernas",
          "series": 4,
          "repeticiones": 12,
          "descanso_segundos": 60
        }
      ]
    }
  ]
}
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    final output = response.text;

    if (output == null) {
      throw Exception('Respuesta vacía de Gemini');
    }

    try {
      final parsedJson = jsonDecode(output);
      return parsedJson;
    } catch (e) {
      throw FormatException('La respuesta no es un JSON válido: $e\n\nContenido:\n$output');
    }
  }

  /// Devuelve un List<dynamic> parseado de cualquier prompt que responda con JSON
Future<List<dynamic>> generarJsonDesdePrompt(String prompt) async {
  final response = await _model.generateContent([Content.text(prompt)]);
  final output = response.text;
  if (output == null) {
    throw Exception('Respuesta vacía de Gemini');
  }
  try {
    // parseamos asumiendo que viene un JSON array en texto puro
    return jsonDecode(output) as List<dynamic>;
  } catch (e) {
    throw FormatException('La respuesta no es un JSON válido: $e\n\n$output');
  }
}
}
