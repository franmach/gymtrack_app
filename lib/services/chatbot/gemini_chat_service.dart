// lib/services/chatbot/gemini_chat_service.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'chat_service.dart';

class GeminiChatService implements ChatService {
  late final GenerativeModel _model;
  ChatSession? _chat;

  GeminiChatService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception('GEMINI_API_KEY no encontrada en .env');
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        '''
Sos un asistente de entrenamiento y nutrición de la app GymTrack.
Respondé en español, con un tono profesional y motivador.
Adaptá tus respuestas al contexto personal del usuario que se te proporciona.
Si el usuario pregunta algo que requiere cálculos (por ejemplo calorías, repeticiones, descanso), estimá de forma realista.
Si la información no está clara, pedí aclaración, no inventes datos.
''',
      ),
    );
    _chat = _model.startChat();
  }

  @override
  Future<String> sendMessage(String userText,
      {Map<String, dynamic>? userContext}) async {
    _chat ??= _model.startChat();

    // Generar un prompt contextualizado con los datos del usuario
    final contextPrompt = _buildPrompt(userText, userContext);

    final resp = await _chat!.sendMessage(Content.text(contextPrompt));
    return resp.text ?? 'No tengo una respuesta por el momento.';
  }

  String _buildPrompt(String message, Map<String, dynamic>? ctx) {
    if (ctx == null) return message;

    final datos = '''
Contexto del usuario:
- Nombre: ${ctx['nombre'] ?? 'Desconocido'}
- Edad: ${ctx['edad'] ?? 'N/D'}
- Peso: ${ctx['peso'] ?? 'N/D'} kg
- Altura: ${ctx['altura'] ?? 'N/D'} cm
- Género: ${ctx['genero'] ?? 'N/D'}
- Nivel: ${ctx['nivel'] ?? 'N/D'}
- Objetivo: ${ctx['objetivo'] ?? 'N/D'}
- Lesiones o limitaciones: ${ctx['lesiones'] ?? 'Ninguna'}

Pregunta del usuario:
"$message"
''';
    return datos;
  }

  @override
  Future<void> reset() async {
    _chat = _model.startChat();
  }
}