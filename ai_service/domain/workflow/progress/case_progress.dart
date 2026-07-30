import '../../case/case_status.dart';
import '../completeness/information_completeness.dart';
import '../information_requirement.dart';

/// Foydalanuvchiga ko'rsatiladigan ISH PROGRESSI (Module 5, Phase 5C
/// talabi: "Progress tracking -- show what information is complete,
/// show what is still missing").
///
/// **Ikki xil progress, ATAYLAB birlashtirilmagan:**
/// 1. MA'LUMOT progressi ([completedInformation]/[missingInformation]) --
///    aniqlashtirish oqimining qay darajada to'lganligi;
/// 2. HAYOT-DAVRI progressi ([lifecycleStageIndex]) -- ish `CaseStatus`
///    bo'yicha qaysi bosqichda (Module 5, Phase 5B).
///
/// Ular bir-biriga AVTOMATIK bog'lanmaydi: ma'lumot to'liq bo'lishi
/// ishni keyingi bosqichga O'ZI o'tkazmaydi (bu qaror
/// `AdvanceCaseStatusUseCase` orqali, aniq chaqiruv bilan qabul
/// qilinadi -- Phase 5B'dagi bir xil intizom).
///
/// **Xavfsizlik:** bu klass foydalanuvchi JAVOBLARINI (xom matn)
/// saqlamaydi -- faqat qaysi bo'lak to'ldirilgan/to'ldirilmaganini
/// bildiradi. Shu sababli progressni loglash/monitoringga uzatish
/// sezgir ma'lumot chiqib ketishiga olib kelmaydi ("No sensitive
/// information in domain logs", Module 5, Phase 5B).
class CaseProgress {
  const CaseProgress({
    required this.caseId,
    required this.status,
    required this.completeness,
  });

  final String caseId;
  final CaseStatus status;
  final InformationCompleteness completeness;

  /// Nima ALLAQACHON to'plangan.
  List<InformationRequirement> get completedInformation => completeness.satisfied;

  /// Nima HALI yetishmayapti (majburiy + ixtiyoriy).
  List<InformationRequirement> get missingInformation => completeness.missing;

  /// Faqat MAJBURIY yetishmayotganlar -- keyingi bosqichga o'tishni
  /// to'sib turgan bo'laklar.
  List<InformationRequirement> get missingMandatoryInformation =>
      completeness.missingMandatory;

  int get completedCount => completeness.satisfied.length;

  int get totalCount => completeness.totalCount;

  /// 0.0–1.0.
  double get informationCompletionRatio => completeness.completionRatio;

  /// Majburiy bo'laklar to'liqmi -- **huquqiy baho EMAS** (talab: "No
  /// legal judgement"), faqat "so'ralganlar berildimi".
  bool get isInformationSufficient => completeness.isSufficient;

  /// 1'dan boshlanadigan hayot-davri bosqichi raqami
  /// (`CaseStatus.values` tartibida).
  int get lifecycleStageIndex => CaseStatus.values.indexOf(status) + 1;

  int get lifecycleStageCount => CaseStatus.values.length;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CaseProgress &&
            other.caseId == caseId &&
            other.status == status &&
            other.completeness == completeness);
  }

  @override
  int get hashCode => Object.hash(caseId, status, completeness);

  @override
  String toString() =>
      'CaseProgress(caseId: $caseId, status: ${status.name}, '
      '$completedCount/$totalCount information, stage $lifecycleStageIndex/$lifecycleStageCount)';
}
