import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:uuid/uuid.dart';

import '../models/comidaPlanItem.dart';
import '../models/comida.dart';
import '../models/infoNutricional.dart';

/// Servicio que maneja la generación de planes alimenticios usando IA.
/// Primero intenta con Gemini y si hay error 503 (límite agotado), usa OpenAI como fallback.
class NutritionAIService {
  final String _geminiApiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  final String _openAiApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final _uuid = const Uuid();
  final uuid = Uuid();

  late GenerativeModel _geminiModel;

  NutritionAIService() {
    // Inicializamos Gemini
    _geminiModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _geminiApiKey,
    );

    // Inicializamos OpenAI
    OpenAI.apiKey = _openAiApiKey;
  }

  /// Genera un plan semanal de comidas usando IA
  Future<List<ComidaPlanItem>> generateWeeklyPlan({
    required String usuarioId,
    required bool vegetarian,
    required bool vegan,
    required List<String> excludedFoods,
    required Map<String, dynamic> perfil,
  }) async {
    final prompt = _buildPrompt(vegetarian, vegan, excludedFoods, perfil);

    try {
      // 1️⃣ Intentar con Gemini
      final geminiResponse = await _geminiModel.generateContent([Content.text(prompt)]);
      final planJson = geminiResponse.text ?? '';

      return _parsePlanFromJson(planJson, usuarioId);
    } on GenerativeAIException catch (e) {
      // 2️⃣ Si Gemini da error 503 → fallback a OpenAI
      if (e.message.contains('503')) {
        final openAiResponse = await OpenAI.instance.chat.create(
          model: 'gpt-3.5-turbo', // modelo más barato
          messages: [
            OpenAIChatCompletionChoiceMessageModel(
              role: OpenAIChatMessageRole.user,
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
              ],
            ),
          ],
        );

        final planJson = openAiResponse.choices.first.message.content?.first.text ?? '';
        return _parsePlanFromJson(planJson, usuarioId);
      } else {
        rethrow; // si es otro error, lo lanzamos
      }
    }
  }

  /// Construye el prompt para la IA
  String _buildPrompt(
    bool vegetarian,
    bool vegan,
    List<String> excludedFoods,
    Map<String, dynamic> perfil,
  ) {
    final buffer = StringBuffer()
      ..writeln("Genera un plan nutricional semanal para un usuario con:")
      ..writeln("- Edad: ${perfil["edad"] ?? "-"}")
      ..writeln("- Peso: ${perfil["peso"] ?? "-"} kg")
      ..writeln("- Objetivo: ${perfil["objetivo"] ?? "-"}")
      ..writeln("- Vegetariano: $vegetarian, Vegano: $vegan")
      ..writeln("- Excluir alimentos: ${excludedFoods.join(", ")}")
      ..writeln("Importante:")
      ..writeln("Respondé ÚNICAMENTE con un JSON válido.")
      ..writeln("No uses comillas inclinadas, ni backticks, ni Markdown.")
      ..writeln("No uses comas finales después del último ítem en arrays.")
      ..writeln("El JSON debe ser un array de objetos con los campos: ")
      ..writeln("day, mealType, nombre, horario, calories, protein, carbs, fat y portion.");

    return buffer.toString();
  }

  /// Convierte el JSON devuelto por la IA en una lista de ComidaPlanItem
  List<ComidaPlanItem> _parsePlanFromJson(String jsonString, String usuarioId) {
  final List<dynamic> decoded = jsonDecode(jsonString);

 return decoded.map((item) {
  return ComidaPlanItem(
    id: uuid.v4(), // ✅ ID único para el item
    day: item['day'] as String,
    horario: item['horario'] as String? ?? '', // ✅ Horario requerido
    tipo: item['tipo'] as String? ?? '',       // ✅ Tipo requerido
    portion: item['portion'].toString(),       // ✅ Convertimos a String
    comida: Comida(
      id: uuid.v4(),                           // ✅ ID único para la comida
      nombre: item['nombre'] as String,
      tipo: item['tipo'] as String? ?? '',
      horario: item['horario'] as String? ?? '',
      macros: InfoNutricional(
        calories: (item['calories'] as num).toDouble(),
        proteinGrams: (item['protein'] as num).toDouble(),
        carbGrams: (item['carbs'] as num).toDouble(),
        fatGrams: (item['fat'] as num).toDouble(),
      ),
    ),
  );
}).toList();
}
}
