import 'ai_provider_id.dart';

/// AI so'rovi davomida yuzaga kelishi mumkin bo'lgan xatoliklarning
/// tur-xavfsiz (type-safe) taksonomiyasi (Module 4, Phase 2C talabi:
/// "Error abstraction").
///
/// Ilgari (Phase 1–2B) `AIStreamEventError` xom `String message` olib
/// yurar edi — bu chaqiruvchi tomonga XATOLIK TURINI emas, faqat matnni
/// beradi, shuning uchun "qayta urinish kerakmi?" kabi qarorni avtomatik
/// qabul qilib bo'lmas edi. `AIFailure` shu bo'shliqni to'ldiradi: flutter
/// klientdagi `core/error/failure.dart`'ning shu loyihaga xos konventsiyasi
/// bilan bir xil — sealed ierarxiya, lekin bu yerga AI'ga xos
/// `isRetryable` xususiyati qo'shilgan (`domain/retry/ai_retry_policy.dart`
/// aynan shu bayroqqa asoslanib qaror qabul qiladi).
///
/// **Muhim:** bu klass foydalanuvchiga ko'rsatiladigan matnni o'zi
/// belgilamaydi (`describeErrorForUser()` singari funksiya bu yerda yo'q)
/// — bu keyingi bosqichda, haqiqiy backend integratsiyasida hal
/// qilinadi. Hozircha faqat TUZILISH (structure) beriladi.
sealed class AIFailure {
  const AIFailure();

  /// Shu turdagi xatolikni bir xil parametrlar bilan qayta urinish
  /// mantiqan to'g'rimi. `AIRetryPolicy`/`AIRetryExecutor` shu
  /// qiymatga tayanadi -- individual chaqiruv joylari buni o'zlari
  /// hal qilmaydi (Single Source of Truth).
  bool get isRetryable;
}

/// Tarmoq darajasidagi vaqtinchalik nosozlik (ulanish uzilishi va h.k.).
/// Odatda qayta urinish bilan tuzaladi.
final class AINetworkFailure extends AIFailure {
  const AINetworkFailure({this.message});

  final String? message;

  @override
  bool get isRetryable => true;

  @override
  String toString() => 'AINetworkFailure(message: $message)';
}

/// So'rov belgilangan vaqt ichida javob olmadi.
final class AITimeoutFailure extends AIFailure {
  const AITimeoutFailure();

  @override
  bool get isRetryable => true;

  @override
  String toString() => 'AITimeoutFailure()';
}

/// Provayder so'rovlar sonini cheklash (rate limit) sababli rad etdi.
final class AIRateLimitFailure extends AIFailure {
  const AIRateLimitFailure({this.retryAfter});

  /// Provayder tavsiya qilgan kutish vaqti (agar ma'lum bo'lsa).
  final Duration? retryAfter;

  @override
  bool get isRetryable => true;

  @override
  String toString() => 'AIRateLimitFailure(retryAfter: $retryAfter)';
}

/// Provayder o'zi (masalan noto'g'ri so'rov formati, model xatosi)
/// xatolik qaytardi. Odatda bir xil so'rovni qayta yuborish natijani
/// o'zgartirmaydi, shuning uchun standart holatda qayta urinilmaydi.
final class AIProviderFailure extends AIFailure {
  const AIProviderFailure({required this.message, required this.providerId});

  final String message;
  final AIProviderId providerId;

  @override
  bool get isRetryable => false;

  @override
  String toString() =>
      'AIProviderFailure(providerId: $providerId, message: $message)';
}

/// So'rov yoki (kelgusida) javob xavfsizlik qatlamidan (`AISafetyService`)
/// o'tmadi. Bir xil so'rovni qayta yuborish bir xil natija beradi --
/// hech qachon qayta urinilmaydi.
final class AISafetyRejectionFailure extends AIFailure {
  const AISafetyRejectionFailure({required this.reason});

  final String reason;

  @override
  bool get isRetryable => false;

  @override
  String toString() => 'AISafetyRejectionFailure(reason: $reason)';
}

/// So'ralgan `AIProviderId` uchun `di/ai_service_locator.dart`da
/// hech qanday adapter ro'yxatdan o'tkazilmagan -- konfiguratsiya
/// xatosi, qayta urinish yordam bermaydi.
final class AIProviderNotConfiguredFailure extends AIFailure {
  const AIProviderNotConfiguredFailure({required this.providerId});

  final AIProviderId providerId;

  @override
  bool get isRetryable => false;

  @override
  String toString() => 'AIProviderNotConfiguredFailure(providerId: $providerId)';
}

/// Berilgan `conversationId` bo'yicha suhbat topilmadi.
final class AIConversationNotFoundFailure extends AIFailure {
  const AIConversationNotFoundFailure({required this.conversationId});

  final String conversationId;

  @override
  bool get isRetryable => false;

  @override
  String toString() =>
      'AIConversationNotFoundFailure(conversationId: $conversationId)';
}

/// Suhbat allaqachon yopilgan, unga yangi xabar qo'shib bo'lmaydi.
final class AIConversationClosedFailure extends AIFailure {
  const AIConversationClosedFailure({required this.conversationId});

  final String conversationId;

  @override
  bool get isRetryable => false;

  @override
  String toString() =>
      'AIConversationClosedFailure(conversationId: $conversationId)';
}

/// Klient shu so'rovda o'zini kimligini (`AIRequestEnvelope.userId`)
/// autentifikatsiya qatlami tasdiqlagan shaxsdan (`AIAuthContext.userId`)
/// FARQLI deb da'vo qildi (Module 4, Phase 3B, "Authentication
/// Boundary" -- `gateway/dispatch/ai_request_dispatcher.dart`).
/// Dasturlash xatosi emas -- soxtalashtirish (spoofing) urinishi yoki
/// eskirgan klient holati, hech qachon qayta urinilmaydi.
final class AIUnauthorizedFailure extends AIFailure {
  const AIUnauthorizedFailure();

  @override
  bool get isRetryable => false;

  @override
  String toString() => 'AIUnauthorizedFailure()';
}

/// So'rov shakli (masalan `context` maydonining kutilgan ichki
/// tuzilishi) yaroqsiz -- backend ICHKI xatosi emas, KLIENT xatosi
/// (Module 4, Phase 3B, "Request Dispatcher"). Bir xil noto'g'ri
/// so'rovni qayta yuborish bir xil natija beradi -- qayta urinilmaydi.
final class AIInvalidRequestFailure extends AIFailure {
  const AIInvalidRequestFailure({required this.reason});

  final String reason;

  @override
  bool get isRetryable => false;

  @override
  String toString() => 'AIInvalidRequestFailure(reason: $reason)';
}

/// Yuqoridagilarning hech biriga to'g'ri kelmaydigan, kutilmagan
/// xatolik. Konservativ standart -- qayta urinilmaydi (sababi
/// noma'lum bo'lgani uchun xavfsiz taraf tanlanadi).
final class AIUnknownFailure extends AIFailure {
  const AIUnknownFailure({this.message});

  final String? message;

  @override
  bool get isRetryable => false;

  @override
  String toString() => 'AIUnknownFailure(message: $message)';
}
