/// `ConversationRepository`/`AIConversation` tashlaydigan, ANIQ
/// AJRATILADIGAN (distinguishable) xatolik turlari (Module 4, Phase 2C
/// talabi: "Error abstraction").
///
/// Ilgari (Phase 2A) bu holatlar umumiy `StateError` bilan
/// ifodalangan edi -- bu chaqiruvchi tomonga "aynan NIMA xato ketdi"
/// ma'lumotini bermas edi (`StateError.message`ni fragile string
/// solishtirish orqali tekshirishga majbur qilar edi). Bundan tashqari,
/// bu ikkalasi ham dasturlash xatosi emas -- kutilgan, oldindan
/// bilingan ish vaqti holatlari, shuning uchun `Error` (dasturlash
/// xatolari uchun) o'rniga `Exception` interfeysini amalga oshiradi
/// (Dart konventsiyasi: `Error` != `Exception`).
///
/// `domain/usecases/send_conversation_message_usecase.dart` shu
/// turlarni aniq `catch` qilib, mos `AIFailure` variantiga
/// (`entities/ai_failure.dart`) tarjima qiladi.
library;

/// Berilgan `conversationId` bo'yicha suhbat topilmadi.
class ConversationNotFoundException implements Exception {
  const ConversationNotFoundException(this.conversationId);

  final String conversationId;

  @override
  String toString() => 'ConversationNotFoundException($conversationId)';
}

/// Suhbat allaqachon yopilgan, unga yangi xabar qo'shib bo'lmaydi.
class ConversationClosedException implements Exception {
  const ConversationClosedException(this.conversationId);

  final String conversationId;

  @override
  String toString() => 'ConversationClosedException($conversationId)';
}
