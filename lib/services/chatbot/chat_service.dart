// lib/services/chatbot/chat_service.dart  (todo en minúsculas)
abstract class ChatService {
  Future<String> sendMessage(String userText);
  Future<void> reset();
}