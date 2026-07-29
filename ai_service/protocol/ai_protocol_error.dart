/// Provayderdan mustaqil, simli (wire) xatolik shartnomasi (Module 4,
/// Phase 3A talabi: "Error Protocol").
///
/// **`AIFailure` (`domain/entities/ai_failure.dart`, Phase 2C) bilan
/// aynan bir xil klass EMAS -- ataylab:** `AIFailure` -- Dart sealed
/// klass ierarxiyasi, faqat shu jarayon (process) ichida, backendning
/// o'z domain qatlamida ishlatiladi. `AIProtocolError` esa JSON orqali
/// SIMDAN o'tadi -- klient Dart/Flutter bo'lishi shart emas (kelgusida
/// boshqa til/platforma ham shu protokolga rioya qilishi mumkin),
/// shuning uchun `code` Dart turi emas, BARQAROR enum qiymati
/// (`AIProtocolErrorCode`) -- versiyalar osha nomi o'zgarmasligi kerak.
/// Ikkalasi orasidagi tarjima (`AIFailure` -> `AIProtocolError`)
/// kelgusi integratsiya bosqichida (haqiqiy HTTP/WebSocket handler
/// qurilganda) qo'shiladi -- bu bosqich faqat SHAKLNI belgilaydi.
enum AIProtocolErrorCode {
  network,
  timeout,
  rateLimited,
  providerError,
  safetyRejected,
  providerNotConfigured,
  conversationNotFound,
  conversationClosed,

  /// Klient noto'g'ri shakllangan so'rov yuborganda (masalan majburiy
  /// maydon yo'q) -- bu `AIFailure`da yo'q, chunki bu backend ICHKI
  /// xatoligi emas, balki KLIENT xatoligi.
  invalidRequest,

  /// Klient hech qanday yaroqli hisob ma'lumoti (credential) taqdim
  /// etmadi -- `gateway/auth/` (Module 4, Phase 3B, "Authentication
  /// Boundary").
  unauthenticated,

  /// Klient autentifikatsiyadan o'tgan, lekin so'ralgan amalga huquqi
  /// yo'q (masalan `AIRequestEnvelope.userId` autentifikatsiya
  /// qilingan shaxsdan farq qiladi) -- `gateway/dispatch/`.
  unauthorized,
  unknown,
}

class AIProtocolError {
  const AIProtocolError({
    required this.code,
    required this.message,
    required this.retryable,
  });

  final AIProtocolErrorCode code;

  /// Foydalanuvchiga ko'rsatilishi mumkin bo'lgan, xavfsiz matn
  /// (flutter klientdagi `Failure`/`describeErrorForUser()`
  /// konventsiyasiga muvofiq -- xom stack trace/ichki tafsilot emas).
  final String message;

  /// Klient shu so'rovni (o'zgarishsiz) qayta yuborishi mantiqan
  /// to'g'rimi -- `AIFailure.isRetryable`ning simli (wire) ko'rinishi.
  final bool retryable;

  Map<String, dynamic> toJson() => {
    'code': code.name,
    'message': message,
    'retryable': retryable,
  };

  factory AIProtocolError.fromJson(Map<String, dynamic> json) {
    return AIProtocolError(
      code: AIProtocolErrorCode.values.byName(json['code'] as String),
      message: json['message'] as String,
      retryable: json['retryable'] as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIProtocolError &&
            other.code == code &&
            other.message == message &&
            other.retryable == retryable);
  }

  @override
  int get hashCode => Object.hash(code, message, retryable);

  @override
  String toString() =>
      'AIProtocolError(code: $code, retryable: $retryable, message: $message)';
}
