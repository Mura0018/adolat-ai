import '../../domain/entities/ai_cancellation_token.dart';
import '../../domain/entities/ai_conversation.dart';
import '../../domain/entities/ai_message.dart';

/// AI suhbat sessiyalarini xotirada boshqaradi (Module 4 talabi: "AI
/// Session — Conversation ID, Message history, Cancellation support").
///
/// **Foundation bosqichi cheklovi:** xotiradagi (`Map`) saqlash — bu
/// bitta xizmat nusxasi (instance) doirasida ishlaydi, ko'p nusxali
/// (multi-instance) joylashtirishda alohida umumiy saqlash (masalan
/// Redis) kerak bo'ladi. Bu Module 4, Phase 1 doirasidan tashqarida —
/// interfeys shakli (`AISessionManager`) shu almashtirishga tayyor
/// bo'lishi uchun tor va aniq ushlab turilgan.
class AISessionManager {
  AISessionManager({String Function()? idGenerator})
    : _generateId = idGenerator ?? _defaultIdGenerator;

  final String Function() _generateId;
  final Map<String, AIConversation> _conversations = {};
  final Map<String, AICancellationToken> _activeCancellationTokens = {};

  static int _counter = 0;

  static String _defaultIdGenerator() {
    _counter += 1;
    return 'conv_${DateTime.now().microsecondsSinceEpoch}_$_counter';
  }

  AIConversation startConversation() {
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

  AIConversation? getConversation(String conversationId) {
    return _conversations[conversationId];
  }

  /// Mavjud suhbatga xabar qo'shadi va yangilangan nusxani saqlaydi.
  /// Suhbat topilmasa `StateError` tashlaydi — chaqiruvchi avval
  /// [startConversation]ni chaqirgan bo'lishi shart.
  AIConversation appendMessage(String conversationId, AIMessage message) {
    final existing = _conversations[conversationId];
    if (existing == null) {
      throw StateError('Suhbat topilmadi: $conversationId');
    }
    final updated = existing.appendMessage(message);
    _conversations[conversationId] = updated;
    return updated;
  }

  /// Berilgan suhbat uchun bekor qilish tokenini ro'yxatga oladi —
  /// `AIRepositoryImpl` shu tokenni provayder adapteriga uzatadi.
  AICancellationToken beginCancellableOperation(String conversationId) {
    final token = AICancellationToken();
    _activeCancellationTokens[conversationId] = token;
    return token;
  }

  /// Suhbat uchun joriy faol operatsiyani bekor qiladi (agar mavjud
  /// bo'lsa).
  void cancel(String conversationId) {
    _activeCancellationTokens[conversationId]?.cancel();
    _activeCancellationTokens.remove(conversationId);
  }

  void endOperation(String conversationId) {
    _activeCancellationTokens.remove(conversationId);
  }
}
