import '../repositories/conversation_exceptions.dart';
import 'ai_conversation_status.dart';
import 'ai_message.dart';

/// Bitta AI suhbat sessiyasi — xabarlar tarixi, identifikatori va
/// hayot davri holati (Module 4 talabi: "AI Session — Conversation ID,
/// Message history"; Phase 2A talabi: "Conversation lifecycle").
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
    this.status = AIConversationStatus.active,
  });

  final String id;
  final List<AIMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AIConversationStatus status;

  bool get isClosed => status == AIConversationStatus.closed;

  /// Yangi xabar bilan **yangi** nusxa qaytaradi — `AIConversation`
  /// o'zgarmas (immutable), sessiya holatini `ConversationRepository`
  /// boshqaradi (`domain/repositories/conversation_repository.dart`).
  ///
  /// **Lifecycle qoidasi:** yopilgan suhbatga xabar qo'shib bo'lmaydi —
  /// bu kutilgan, oldindan bilingan ish vaqti holati (dasturlash xatosi
  /// emas), shuning uchun aniq ajraladigan `ConversationClosedException`
  /// tashlanadi (`../repositories/conversation_exceptions.dart`, Phase
  /// 2C talabi: "Error abstraction") — chaqiruvchi qatlam
  /// (`domain/usecases/send_conversation_message_usecase.dart`) buni
  /// aniq `catch` qilib, mos `AIFailure` variantiga tarjima qiladi.
  AIConversation appendMessage(AIMessage message) {
    if (isClosed) {
      throw ConversationClosedException(id);
    }
    return AIConversation(
      id: id,
      messages: [...messages, message],
      createdAt: createdAt,
      updatedAt: message.createdAt,
      status: status,
    );
  }

  /// Suhbatni yopadi — shundan keyin [appendMessage] `ConversationClosedException`
  /// tashlaydi. Allaqachon yopilgan suhbatni qayta yopish xavfsiz
  /// (idempotent), yangi nusxa qaytaradi lekin holat o'zgarmaydi.
  AIConversation close({required DateTime closedAt}) {
    if (isClosed) return this;
    return AIConversation(
      id: id,
      messages: messages,
      createdAt: createdAt,
      updatedAt: closedAt,
      status: AIConversationStatus.closed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AIConversation) return false;
    if (other.id != id ||
        other.createdAt != createdAt ||
        other.updatedAt != updatedAt ||
        other.status != status ||
        other.messages.length != messages.length) {
      return false;
    }
    for (var i = 0; i < messages.length; i++) {
      if (other.messages[i] != messages[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    status,
    Object.hashAll(messages),
  );

  @override
  String toString() =>
      'AIConversation(id: $id, status: $status, messages: ${messages.length}, updatedAt: $updatedAt)';
}
