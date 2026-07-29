import 'ai_client_conversation_status.dart';
import 'ai_client_message.dart';

/// Klientning mahalliy (optimistic) suhbat nusxasi -- foydalanuvchi
/// xabarini darhol UI'da ko'rsatish uchun, backend javobini kutmasdan.
///
/// **Muhim:** bu klass haqiqiy manba (source of truth) EMAS -- suhbat
/// tarixining haqiqiy holati backend'da (`ai_service/domain/entities/
/// ai_conversation.dart`, `ConversationRepository`) saqlanadi. Bu --
/// shunchaki klientning UI'ni darhol yangilash uchun ishlatadigan,
/// o'zgarmas (immutable) mahalliy ko'rinishi (`AiRequestPipeline`
/// bu klassni O'ZIO'ZGARTIRMAYDI -- chaqiruvchi (masalan kelgusi chat
/// controller) oqim hodisalariga qarab yangi nusxa yaratadi).
class AiClientConversation {
  const AiClientConversation({
    required this.id,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
    this.status = AiClientConversationStatus.active,
  });

  final String id;
  final List<AiClientMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AiClientConversationStatus status;

  bool get isClosed => status == AiClientConversationStatus.closed;

  /// Yangi xabar bilan **yangi** nusxa qaytaradi (o'zgarmas naqsh).
  AiClientConversation appendMessage(AiClientMessage message) {
    return AiClientConversation(
      id: id,
      messages: [...messages, message],
      createdAt: createdAt,
      updatedAt: message.createdAt,
      status: status,
    );
  }

  AiClientConversation close({required DateTime closedAt}) {
    if (isClosed) return this;
    return AiClientConversation(
      id: id,
      messages: messages,
      createdAt: createdAt,
      updatedAt: closedAt,
      status: AiClientConversationStatus.closed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AiClientConversation) return false;
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
  int get hashCode =>
      Object.hash(id, createdAt, updatedAt, status, Object.hashAll(messages));

  @override
  String toString() =>
      'AiClientConversation(id: $id, status: $status, messages: ${messages.length})';
}
