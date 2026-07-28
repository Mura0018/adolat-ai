import '../../domain/entities/ai_cancellation_token.dart';
import '../../domain/repositories/ai_cancellation_registry.dart';

/// `AICancellationRegistry`ning xotiradagi implementatsiyasi (Module 4,
/// Phase 2A). `InMemoryConversationRepository`dagi bilan bir xil
/// ko'p-nusxali joylashtirish cheklovi amal qiladi.
class InMemoryCancellationRegistry implements AICancellationRegistry {
  final Map<String, AICancellationToken> _activeTokens = {};

  @override
  AICancellationToken register(String conversationId) {
    final token = AICancellationToken();
    _activeTokens[conversationId] = token;
    return token;
  }

  @override
  void cancel(String conversationId) {
    _activeTokens[conversationId]?.cancel();
    _activeTokens.remove(conversationId);
  }

  @override
  void release(String conversationId) {
    _activeTokens.remove(conversationId);
  }
}
