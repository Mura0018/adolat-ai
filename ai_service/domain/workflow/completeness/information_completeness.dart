import '../information_requirement.dart';

/// Ma'lumot to'liqligini baholash NATIJASI (Module 5, Phase 5C talabi:
/// "Information completeness evaluation").
///
/// **Bu HUQUQIY BAHO EMAS** (talab: "No legal judgement") -- bu sof
/// MEXANIK ro'yxat tekshiruvi (checklist): "kerakli deb belgilangan
/// bo'laklarning qaysilari to'ldirilgan". [isSufficient] `true`
/// bo'lishi ishning "asosli"/"g'alaba qozonadigan" ekanini EMAS,
/// faqat SO'RALGAN savollarga javob berilganini bildiradi. Huquqiy
/// xulosa chiqarish `ai_service/`ning HECH BIR qatlamida yo'q va
/// bo'lmasligi kerak (`docs/DEVELOPMENT_RULES.md`, 15–16-band).
class InformationCompleteness {
  const InformationCompleteness({required this.satisfied, required this.missing});

  /// To'ldirilgan bo'laklar -- katalogdagi tartibda.
  final List<InformationRequirement> satisfied;

  /// To'ldirilmagan bo'laklar (majburiy + ixtiyoriy) -- katalogdagi
  /// tartibda.
  final List<InformationRequirement> missing;

  List<InformationRequirement> get missingMandatory =>
      missing.where((r) => r.isMandatory).toList(growable: false);

  List<InformationRequirement> get missingOptional =>
      missing.where((r) => !r.isMandatory).toList(growable: false);

  /// **FAQAT majburiy bo'laklarga qaraydi** -- ixtiyoriy bo'laklar
  /// to'ldirilmagan bo'lsa ham "yetarli" hisoblanadi, aks holda
  /// ixtiyoriy bo'lakning ma'nosi qolmas edi.
  ///
  /// Katalog bo'sh bo'lsa (`requirementsFor()` bo'sh ro'yxat qaytarsa)
  /// -- `true`: "hech narsa so'ralmagan → hammasi berilgan". Bu
  /// ATAYLAB: yangi toifa katalogga qo'shilmaguncha oqim to'sib
  /// qo'yilmaydi (`DEVELOPMENT_RULES.md`, 18-band -- foydalanuvchi
  /// boshi berk holatda qolmaydi).
  bool get isSufficient => missingMandatory.isEmpty;

  int get totalCount => satisfied.length + missing.length;

  /// 0.0–1.0 oralig'ida, BARCHA bo'laklar (majburiy + ixtiyoriy)
  /// bo'yicha -- foydalanuvchiga ko'rsatiladigan progress ko'rsatkichi
  /// ([isSufficient]dan farqli o'laroq, u faqat majburiylarga
  /// qaraydi).
  double get completionRatio => totalCount == 0 ? 1.0 : satisfied.length / totalCount;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! InformationCompleteness) return false;
    return _listEquals(other.satisfied, satisfied) && _listEquals(other.missing, missing);
  }

  static bool _listEquals(List<InformationRequirement> a, List<InformationRequirement> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(satisfied), Object.hashAll(missing));

  @override
  String toString() =>
      'InformationCompleteness(satisfied: ${satisfied.length}, missing: ${missing.length}, '
      'sufficient: $isSufficient)';
}
