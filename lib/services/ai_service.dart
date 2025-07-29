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
Generá una rutina de entrenamiento semanal con los siguientes datos del usuario:

Edad: $edad años  
Peso: $peso kg  
Altura: $altura cm  
Género: $genero  
Nivel de experiencia: $nivel  
Objetivo físico: $objetivo  
Solo puede entrenar $dias días a la semana  
Duración máxima por sesión: $minPorSesion minutos  
Lesiones o limitaciones: $lesiones

⚠️ Importante:
- Respondé ÚNICAMENTE con un JSON válido.
- Todos los valores deben estar entre comillas si no son números (por ejemplo: "Máximo posible", "8-12").
- No uses comillas inclinadas, ni backticks, ni Markdown.
- No uses comas finales después del último ítem en arrays.
- Evitá rangos tipo 8-12. Usá strings, ejemplo: "8 a 12".

Ejemplo de respuesta esperada:
{
  "rutina": [
    {
      "dia": "Lunes",
      "ejercicios": [
        {
          "nombre": "Sentadillas",
          "grupo_muscular": "Piernas",
          "series": 4,
          "repeticiones": "12",
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
      throw FormatException(
          'La respuesta no es un JSON válido: $e\n\nContenido:\n$output');
    }
  }

  Future<List<String>> analizarLesionesConGemini(String texto) async {
  final prompt = '''
Analiza el siguiente texto ingresado por un usuario sobre sus lesiones o limitaciones físicas. 
Extraé una lista clara de lesiones o zonas afectadas, lo más breve y específica posible.
Si no se detecta ninguna lesión relevante, respondé con una lista vacía.

Texto:
"$texto"

Respondé SOLO con una lista en formato JSON, sin ningún formato markdown, sin comentarios ni comillas extrañas. Solo:

["lesión 1", "lesión 2"]
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
}
