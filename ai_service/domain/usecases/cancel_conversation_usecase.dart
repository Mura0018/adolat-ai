import '../repositories/ai_cancellation_registry.dart';

/// Suhbat bo'yicha joriy faol AI so'rovini bekor qiladi (Module 4,
/// Phase 2C talabi: "AI UseCases").
class CancelConversationUseCase {
  const CancelConversationUseCase(this._cancellationRegistry);

  final AICancellationRegistry _cancellationRegistry;

  void call(String conversationId) {
    _cancellationRegistry.cancel(conversationId);
  }
}
