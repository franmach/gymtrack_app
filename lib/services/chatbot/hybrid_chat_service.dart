// lib/services/chatbot/hybrid_chat_service.dart
import 'chat_service.dart';

class HybridChatService implements ChatService {
  final ChatService local;    // FirestoreFaqService
  final ChatService fallback; // GeminiChatService

  HybridChatService({required this.local, required this.fallback});

  @override
  Future<String> sendMessage(String userText) async {
    final localResp = await local.sendMessage(userText);
    if (localResp.startsWith('No encuentro')) {
      return await fallback.sendMessage(userText);
    }
    return localResp;
  }

  @override
  Future<void> reset() async {
    await local.reset();
    await fallback.reset();
  }
}