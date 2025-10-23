// lib/services/chatbot/chat_service.dart

/// Interfaz base para los servicios del chatbot.
/// Define cómo deben comportarse los servicios (Gemini, futuros, etc.)
abstract class ChatService {
  /// Envía un mensaje al chatbot y devuelve la respuesta generada.
  ///
  /// [userText]: texto del usuario.
  /// [userContext]: mapa con datos del usuario (edad, peso, nivel, etc.)
  Future<String> sendMessage(String userText, {Map<String, dynamic>? userContext});

  /// Reinicia la sesión o el contexto del chatbot.
  Future<void> reset();
}