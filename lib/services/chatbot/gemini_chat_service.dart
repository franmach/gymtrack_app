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
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      // Tip: podés setear systemInstruction para “acotar” el rol del bot
      systemInstruction: Content.system(
        'Sos un asistente de GymTrack. Contestá conciso en español. '
        'Si el usuario pide rutinas detalladas, sugerí usar la función de Rutinas o Plan Alimenticio.'
      ),
    );
    _chat = _model.startChat();
  }

  @override
  Future<String> sendMessage(String userText) async {
    _chat ??= _model.startChat();
    final resp = await _chat!.sendMessage(Content.text(userText));
    return resp.text ?? 'No tengo una respuesta en este momento.';
  }

  @override
Future<void> reset() async {
  _chat = _model.startChat(); // o null si preferís re-crear al primer uso
}
}