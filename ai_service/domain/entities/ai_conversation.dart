import 'ai_message.dart';

/// Bitta AI suhbat sessiyasi — xabarlar tarixi va identifikatori
/// (Module 4 talabi: "AI Session — Conversation ID, Message history").
///
/// **Muhim:** bu klass shaxsan qaysi `appeal`/`dispute`ga tegishli
/// ekanligini bilmaydi — bu bog'lanish `CaseContext` (`domain/prompt/
/// case_context.dart`) orqali, prompt pipeline darajasida beriladi.
/// `AIConversation`ning o'zi umumiy, ish (case) turidan mustaqil.
///
/// Freezed ishlatilmagan sababi: `ai_message.dart`dagi izohga qarang.
class AIConversation {
  const AIConversation({
    required this.id,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final List<AIMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Yangi xabar bilan **yangi** nusxa qaytaradi — `AIConversation`
  /// o'zgarmas (immutable), sessiya holatini `AISessionManager`
  /// boshqaradi (`data/session/ai_session_manager.dart`).
  AIConversation appendMessage(AIMessage message) {
    return AIConversation(
      id: id,
      messages: [...messages, message],
      createdAt: createdAt,
      updatedAt: message.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AIConversation) return false;
    if (other.id != id ||
        other.createdAt != createdAt ||
        other.updatedAt != updatedAt ||
        other.messages.length != messages.length) {
      return false;
    }
    for (var i = 0; i < messages.length; i++) {
      if (other.messages[i] != messages[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, updatedAt, Object.hashAll(messages));

  @override
  String toString() =>
      'AIConversation(id: $id, messages: ${messages.length}, updatedAt: $updatedAt)';
}
