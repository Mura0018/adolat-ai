import '../entities/ai_conversation.dart';
import '../entities/ai_message.dart';

/// Suhbat (conversation) hayot davri ustidagi abstrakt shartnoma
/// (Module 4, Phase 2A talabi: "Conversation repository contracts").
///
/// `AIRepository` (`ai_repository.dart`) — bitta AI so'roviga javob
/// olish haqida; `ConversationRepository` esa — suhbat tarixini
/// saqlash/o'qish/yopish haqida. Ikkalasi qasddan ajratilgan (Single
/// Responsibility): AI provayderni almashtirish suhbat saqlash usuliga
/// ta'sir qilmasligi, va aksincha, saqlash usulini (xotira → Redis →
/// DB) almashtirish AI provayder tanloviga ta'sir qilmasligi kerak.
abstract interface class ConversationRepository {
  /// Yangi, bo'sh, `active` holatdagi suhbat yaratadi.
  AIConversation create();

  /// Suhbatni identifikatori bo'yicha qaytaradi, topilmasa `null`.
  AIConversation? getById(String conversationId);

  /// Mavjud suhbatga xabar qo'shadi va yangilangan nusxani qaytaradi.
  ///
  /// Tashlaydi:
  /// - `ConversationNotFoundException` — suhbat topilmasa.
  /// - `ConversationClosedException` — suhbat allaqachon yopilgan
  ///   bo'lsa (`AIConversation.appendMessage`ga qarang).
  AIConversation appendMessage(String conversationId, AIMessage message);

  /// Suhbatni yopadi (`AIConversationStatus.closed`) va yangilangan
  /// nusxani qaytaradi. Suhbat topilmasa `ConversationNotFoundException`
  /// tashlaydi.
  AIConversation close(String conversationId);
}
