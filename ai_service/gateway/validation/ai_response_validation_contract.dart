import '../../protocol/ai_response_envelope.dart';

/// Backend chiqaradigan javob o'zining SIMLI shartnomasiga mos
/// ekanligini tekshirish qoidalari (Module 4, Phase 4B talabi:
/// "Response validation contracts").
///
/// **`AIResponseEnvelope`dagi `assert`lardan farqi:** o'sha `assert`lar
/// (`status == failed` bo'lsa `error` majburiy, `assistantMessage`
/// faqat `completed`da) faqat DEBUG rejimida ishlaydi va `AIResponseEnvelope`
/// yaratilgan zahoti "hech bo'lmasa bittasi noto'g'ri bo'lsa qulab
/// tushadi" tarzida ishlaydi -- bu ICHKI dasturlash xatosidan himoya.
/// Bu fayldagi qoidalar esa RELEASE rejimida ham ishlashi mumkin bo'lgan,
/// tur-xavfsiz ro'yxat sifatida rasmiylashtirilgan -- kelgusi haqiqiy
/// backend implementatsiyasi javobni klientga jo'natishdan OLDIN oxirgi
/// marta shu ro'yxat bo'yicha tekshirib chiqishi mumkin (masalan
/// monitoring/audit maqsadida, `assert`lar allaqachon o'tgan bo'lsa
/// ham).
enum AIResponseViolationCode {
  /// `tokenUsage`da barcha uchta maydon (`promptTokens`,
  /// `completionTokens`, `totalTokens`) mavjud, lekin
  /// `promptTokens + completionTokens != totalTokens`.
  inconsistentTokenUsage,

  /// `latencyMs` manfiy qiymatga ega.
  negativeLatency,

  /// `respondedAt` `receivedAt`dan OLDINGI vaqtni ko'rsatadi.
  respondedBeforeReceived,
}

class AIResponseViolation {
  const AIResponseViolation({required this.code, required this.field, required this.detail});

  final AIResponseViolationCode code;
  final String field;
  final String detail;

  Map<String, dynamic> toJson() => {'code': code.name, 'field': field, 'detail': detail};

  factory AIResponseViolation.fromJson(Map<String, dynamic> json) {
    return AIResponseViolation(
      code: AIResponseViolationCode.values.byName(json['code'] as String),
      field: json['field'] as String,
      detail: json['detail'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIResponseViolation &&
            other.code == code &&
            other.field == field &&
            other.detail == detail);
  }

  @override
  int get hashCode => Object.hash(code, field, detail);

  @override
  String toString() => 'AIResponseViolation(code: $code, field: $field)';
}

class AIResponseValidationResult {
  const AIResponseValidationResult({this.violations = const []});

  static const valid = AIResponseValidationResult();

  final List<AIResponseViolation> violations;

  bool get isValid => violations.isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AIResponseValidationResult) return false;
    if (other.violations.length != violations.length) return false;
    for (var i = 0; i < violations.length; i++) {
      if (other.violations[i] != violations[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(violations);

  @override
  String toString() =>
      'AIResponseValidationResult(isValid: $isValid, violations: ${violations.length})';
}

/// Javob tekshiruvi CHEGARASI -- **faqat interfeys, hech qanday
/// implementatsiya yo'q** ([AIRequestValidator]/`AISafetyService` bilan
/// bir xil konventsiya).
abstract interface class AIResponseValidator {
  AIResponseValidationResult validate(AIResponseEnvelope response);
}
