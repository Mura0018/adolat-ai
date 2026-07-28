import '../entities/ai_cancellation_token.dart';

/// Suhbat bo'yicha faol (in-flight) AI so'rovlarini bekor qilish
/// mumkin bo'lgan holatda kuzatib boradigan abstrakt shartnoma
/// (Module 4, Phase 2A talabi: "Cancellation token" — repository
/// darajasida rasmiylashtirilgan).
///
/// `ConversationRepository`dan alohida (Single Responsibility): bekor
/// qilishni kuzatish — vaqtinchalik, jarayon xotirasidagi holat;
/// suhbat tarixi esa — davomiy ma'lumot. Ikkalasini bitta klassda
/// aralashtirish (Module 4 Phase 1'dagi `AISessionManager` kabi)
/// kelajakda faqat bittasini (masalan suhbat tarixini DB'ga, bekor
/// qilishni esa Redis pub/sub'ga) ko'chirishni qiyinlashtiradi.
abstract interface class AICancellationRegistry {
  /// Suhbat uchun yangi bekor qilish tokenini ro'yxatga oladi va
  /// qaytaradi. Agar shu suhbat uchun allaqachon faol token bo'lsa, u
  /// eskisi bilan almashtiriladi (bitta suhbatda bir vaqtning o'zida
  /// faqat bitta faol so'rov bo'ladi degan farazga asoslanadi).
  AICancellationToken register(String conversationId);

  /// Suhbat uchun joriy faol operatsiyani bekor qiladi (agar mavjud
  /// bo'lsa) va ro'yxatdan olib tashlaydi.
  void cancel(String conversationId);

  /// Operatsiya (muvaffaqiyatli yoki xatolik bilan) yakunlanganda
  /// ro'yxatdan olib tashlaydi — bekor qilmasdan.
  void release(String conversationId);
}
