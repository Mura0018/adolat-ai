import '../../domain/entities/ai_conversation.dart';
import '../../domain/entities/ai_message.dart';
import '../../domain/repositories/conversation_repository.dart';

/// `ConversationRepository`ning xotiradagi (in-memory) implementatsiyasi
/// (Module 4, Phase 2A).
///
/// **Cheklov:** bu bitta xizmat nusxasi (instance) doirasida ishlaydi —
/// ko'p nusxali (multi-instance) joylashtirishda alohida umumiy saqlash
/// (masalan Postgres/Redis) kerak bo'ladi. Bu Phase 2A doirasidan
/// tashqarida — abstrakt `ConversationRepository` shartnomasi allaqachon
/// shu almashtirishga tayyor (`docs/AI_ARCHITECTURE.md`, "Provider
/// Abstraction" bo'limidagi bir xil naqsh, endi saqlash uchun ham).
class InMemoryConversationRepository implements ConversationRepository {
  InMemoryConversationRepository({String Function()? idGenerator})
    : _generateId = idGenerator ?? _defaultIdGenerator;

  final String Function() _generateId;
  final Map<String, AIConversation> _conversations = {};

  static int _counter = 0;

  static String _defaultIdGenerator() {
    _counter += 1;
    return 'conv_${DateTime.now().microsecondsSinceEpoch}_$_counter';
  }

  @override
  AIConversation create() {
    final now = DateTime.now();
    final conversation = AIConversation(
      id: _generateId(),
      messages: const [],
      createdAt: now,
      updatedAt: now,
    );
    _conversations[conversation.id] = conversation;
    return conversation;
  }

  @override
  AIConversation? getById(String conversationId) {
    return _conversations[conversationId];
  }

  @override
  AIConversation appendMessage(String conversationId, AIMessage message) {
    final existing = _conversations[conversationId];
    if (existing == null) {
      throw StateError('Suhbat topilmadi: $conversationId');
    }
    final updated = existing.appendMessage(message);
    _conversations[conversationId] = updated;
    return updated;
  }

  @override
  AIConversation close(String conversationId) {
    final existing = _conversations[conversationId];
    if (existing == null) {
      throw StateError('Suhbat topilmadi: $conversationId');
    }
    final closed = existing.close(closedAt: DateTime.now());
    _conversations[conversationId] = closed;
    return closed;
  }
}
