import '../../protocol/ai_request_envelope.dart';

/// So'rov shakli yaroqsiz bo'lishining ANIQ sababi (Module 4, Phase 4B
/// talabi: "Request validation contracts").
///
/// **Nega `AIInvalidRequestFailure`/`AIProtocolErrorCode.invalidRequest`
/// (Phase 3B) yetarli emas edi:** ular faqat "so'rov yaroqsiz" degan
/// BITTA umumiy holatni bildiradi, `reason`/`message` xom matn sifatida.
/// Bu yetarli edi, chunki hech qanday haqiqiy tekshiruv (validation)
/// mantig'i hali yo'q edi -- `AIRequestDispatcher` faqat `context`
/// shaklini (`Map` ekanligini) tekshiradi. Endi (Phase 4B) tekshiruv
/// QOIDALARI tur-xavfsiz ro'yxatga olinadi, shunda kelgusi haqiqiy
/// validator implementatsiyasi (hali YO'Q -- pastdagi
/// [AIRequestValidator]ga qarang) va klient tomoni (masalan forma
/// xatoligini maydon bo'yicha ko'rsatish) bir xil, barqaror kod
/// to'plamiga tayanadi.
enum AIRequestViolationCode {
  /// `message` bo'sh yoki faqat probel.
  messageEmpty,

  /// `message` uzunlik chegarasidan oshib ketgan.
  messageTooLong,

  /// `attachments` ro'yxati ruxsat etilgan maksimal sonidan ko'p.
  tooManyAttachments,

  /// `context`ning ichki tuzilishi kutilgan shaklga (`Map<String,
  /// Map<String, dynamic>>`) mos kelmaydi -- `AIRequestDispatcher`da
  /// allaqachon tekshiriladigan, shu yerda rasmiylashtirilgan hol.
  invalidContextShape,

  /// `protocolVersion` backend qo'llab-quvvatlaydigan versiyalar
  /// oralig'idan tashqarida -- `ai_version_negotiation_contract.dart`
  /// bilan bog'liq, lekin alohida: bu YAKKA so'rov darajasidagi
  /// tekshiruv, versiya kelishuvi esa alohida amal (endpoint).
  unsupportedProtocolVersion,
}

/// Bitta topilgan qoidabuzarlik -- qaysi maydonda, qaysi sababdan.
class AIRequestViolation {
  const AIRequestViolation({required this.code, required this.field, required this.detail});

  final AIRequestViolationCode code;

  /// `AIRequestEnvelope`dagi maydon nomi (masalan `'message'`,
  /// `'attachments'`) -- klient UI'da mos maydonni ko'rsatishi uchun.
  final String field;

  /// Foydalanuvchiga ko'rsatilishi mumkin bo'lgan, xavfsiz tavsif
  /// (`AIProtocolError.message` konventsiyasi bilan bir xil ruhda).
  final String detail;

  Map<String, dynamic> toJson() => {'code': code.name, 'field': field, 'detail': detail};

  factory AIRequestViolation.fromJson(Map<String, dynamic> json) {
    return AIRequestViolation(
      code: AIRequestViolationCode.values.byName(json['code'] as String),
      field: json['field'] as String,
      detail: json['detail'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIRequestViolation &&
            other.code == code &&
            other.field == field &&
            other.detail == detail);
  }

  @override
  int get hashCode => Object.hash(code, field, detail);

  @override
  String toString() => 'AIRequestViolation(code: $code, field: $field)';
}

/// Bitta so'rovni tekshirish natijasi -- bo'sh ro'yxat = yaroqli.
class AIRequestValidationResult {
  const AIRequestValidationResult({this.violations = const []});

  static const valid = AIRequestValidationResult();

  final List<AIRequestViolation> violations;

  bool get isValid => violations.isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AIRequestValidationResult) return false;
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
      'AIRequestValidationResult(isValid: $isValid, violations: ${violations.length})';
}

/// So'rov tekshiruvi CHEGARASI -- **faqat interfeys, hech qanday
/// implementatsiya yo'q** (`AISafetyService`/`AIAuthenticator`/
/// `AIConnectivityMonitor`/`AITransport` bilan bir xil, allaqachon
/// o'rnatilgan konventsiya).
///
/// Bu `AIGateway.handle()`dan OLDIN yoki `AIRequestDispatcher` ICHIDA
/// (hozirgi `context`-shakl tekshiruvi o'rnini bosuvchi, kengaytirilgan
/// shaklda) chaqirilishi mo'ljallangan -- aniq joylashuv haqiqiy
/// implementatsiya qo'shilganda hal qilinadi.
abstract interface class AIRequestValidator {
  AIRequestValidationResult validate(AIRequestEnvelope request);
}
