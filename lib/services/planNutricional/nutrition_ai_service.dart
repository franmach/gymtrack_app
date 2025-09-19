import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:uuid/uuid.dart';

import '../../models/comidaPlanItem.dart';
import '../../models/comida.dart';
import '../../models/infoNutricional.dart';

/// Servicio que genera planes alimenticios con IA.
/// 1) Intenta Gemini (forzado a application/json)
/// 2) Si hay 503, cae a OpenAI (gpt-3.5-turbo)
class NutritionAIService {
  final String _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final String _openAiApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final _uuid = const Uuid();

  late final GenerativeModel _geminiModel;

  NutritionAIService() {
    // Gemini con salida JSON estricta
    _geminiModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiApiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        // opcional: limita tamaño para reducir desbordes
        // maxOutputTokens: 2048,
        temperature: 0.6,
      ),
    );

    // OpenAI fallback
    OpenAI.apiKey = _openAiApiKey;
  }

  /// Genera plan semanal
  Future<List<ComidaPlanItem>> generateWeeklyPlan({
    required String usuarioId,
    required bool vegetarian,
    required bool vegan,
    required List<String> excludedFoods,
    required Map<String, dynamic> perfil,
  }) async {
    final prompt = _buildPrompt(vegetarian, vegan, excludedFoods, perfil);

    try {
      // 1) Gemini
      final geminiResponse =
          await _geminiModel.generateContent([Content.text(prompt)]);
      final raw = geminiResponse.text ?? '';
      final planJson = _preprocessModelOutput(raw);
      return _parsePlanFromJson(planJson, usuarioId);
    } on GenerativeAIException catch (e) {
      // 2) Fallback OpenAI SOLO si es 503 (límite/servicio)
      final msg = (e.message ?? '').toLowerCase();
      if (msg.contains('503') || msg.contains('unavailable')) {
        final openAiResponse = await OpenAI.instance.chat.create(
          model: 'gpt-3.5-turbo',
          messages: [
            OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole.system,
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(
                  'Sos un generador de JSON. Respondé únicamente JSON válido (array) sin markdown.',
                ),
              ],
            ),
            OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole.user,
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
              ],
            ),
          ],
          temperature: 0.6,
        );

        final raw =
            openAiResponse.choices.first.message.content?.first.text ?? '';
        final planJson = _preprocessModelOutput(raw);
        return _parsePlanFromJson(planJson, usuarioId);
      } else {
        rethrow;
      }
    }
  }

  /// Prompt estricto pidiendo SOLO array JSON y campos exactos.
  String _buildPrompt(
    bool vegetarian,
    bool vegan,
    List<String> excludedFoods,
    Map<String, dynamic> perfil,
  ) {
    final b = StringBuffer()
      ..writeln('Genera un plan nutricional semanal para un usuario con:')
      ..writeln('- Edad: ${perfil["edad"] ?? "-"}')
      ..writeln('- Peso: ${perfil["peso"] ?? "-"} kg')
      ..writeln('- Objetivo: ${perfil["objetivo"] ?? "-"}')
      ..writeln('- Vegetariano: $vegetarian, Vegano: $vegan')
      ..writeln('- Excluir alimentos: ${excludedFoods.join(", ")}')
      ..writeln('REGLAS DE SALIDA (MUY IMPORTANTE):')
      ..writeln('1) Respondé ÚNICAMENTE con un JSON **array** válido, sin markdown ni ```.')
      ..writeln('2) NO uses comas finales antes de ] o }.')
      ..writeln(
          '3) Cada elemento del array debe tener EXACTAMENTE estos campos: '
          '{"day":"Lunes","tipo":"desayuno|almuerzo|merienda|cena|colación","nombre":"Avena...","horario":"08:00","calories":350,"protein":20,"carbs":40,"fat":10,"portion":150}.')
      ..writeln('4) Usá valores en español (día y tipo).')
      ..writeln('5) Devolvé SIEMPRE un array (aunque sea vacío: []).');
    return b.toString();
  }

  /// Sanea la salida de la IA para que sea JSON válido antes de jsonDecode.
  String _preprocessModelOutput(String s) {
    if (s.isEmpty) return '[]';
    var t = s.trim();

    // Quitar fences y etiquetas de markdown
    t = t
        .replaceAll(RegExp(r'```json', caseSensitive: false), '')
        .replaceAll('```', '');

    // Quitar BOM / espacios raros
    t = t.replaceAll('\uFEFF', '');

    // Normalizar comillas “ ” ‘ ’ -> " '
    t = t.replaceAll(RegExp(r'[“”]'), '"').replaceAll(RegExp(r"[‘’]"), "'");

    // Extraer solo lo que está entre el primer '[' y el último ']'
    final start = t.indexOf('[');
    final end = t.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      t = t.substring(start, end + 1);
    }

    // Quitar comentarios por si vinieran (no válidos en JSON)
    t = t.replaceAll(RegExp(r'//.*'), '');
    t = t.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');

    // Quitar comas finales antes de } o ]
    t = t.replaceAll(RegExp(r',(\s*[}\]])'), r'$1');

    // Asegurar que parezca un array
    if (!t.trimLeft().startsWith('[')) {
      // A veces viene un objeto { plan: [...] }
      try {
        final obj = jsonDecode(t);
        if (obj is Map && obj.values.isNotEmpty) {
          final firstArr = obj.values.firstWhere(
            (v) => v is List,
            orElse: () => null,
          );
          if (firstArr is List) {
            return jsonEncode(firstArr);
          }
        }
      } catch (_) {
        // si no se puede, envolvemos como array de un único item malformado
      }
    }

    return t.trim();
  }

  /// Parsea el JSON (ya saneado) a tus modelos
  List<ComidaPlanItem> _parsePlanFromJson(String jsonString, String usuarioId) {
    try {
      final decoded = jsonDecode(jsonString);

      final List<dynamic> items;
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map && decoded['plan'] is List) {
        items = decoded['plan'] as List<dynamic>;
      } else {
        // Si no es lista, no rompemos la app
        return <ComidaPlanItem>[];
      }

      return items.map((item) {
        final tipo = (item['tipo'] ?? item['mealType'] ?? '') as String;
        final horario = (item['horario'] ?? '') as String;

        return ComidaPlanItem(
          id: _uuid.v4(),
          day: item['day'] as String,
          horario: horario,
          tipo: tipo,
          portion: (item['portion'] is num)
              ? (item['portion'] as num).toDouble().toString()
              : (item['portion']?.toString() ?? '1'),
          comida: Comida(
            id: _uuid.v4(),
            nombre: item['nombre'] as String,
            tipo: tipo,
            horario: horario,
            macros: InfoNutricional(
              calories: (item['calories'] as num).toDouble(),
              proteinGrams: (item['protein'] as num).toDouble(),
              carbGrams: (item['carbs'] as num).toDouble(),
              fatGrams: (item['fat'] as num).toDouble(),
            ),
          ),
        );
      }).toList();
    } on FormatException catch (e) {
      // Log útil: muestra primeros 400 chars del payload roto
      final preview = jsonString.length > 400
          ? '${jsonString.substring(0, 400)}...'
          : jsonString;
      throw FormatException(
          'JSON inválido: ${e.message}\nPreview salida IA:\n$preview');
    }
  }
}