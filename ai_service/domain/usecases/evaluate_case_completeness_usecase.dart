import '../workflow/completeness/information_completeness.dart';
import '../workflow/completeness/information_completeness_evaluator.dart';
import 'get_case_usecase.dart';

/// Ish bo'yicha YETARLI ma'lumot to'planganmi -- baholaydi (Module 5,
/// Phase 5C talabi: "Information completeness evaluation").
///
/// **Bu HUQUQIY BAHO EMAS** (talab: "No legal judgement"): natija
/// faqat "so'ralgan majburiy bo'laklar to'ldirilganmi" degan savolga
/// javob beradi (`InformationCompleteness`ga qarang).
///
/// **Holatni O'ZI o'zgartirmaydi:** yetarli ma'lumot to'plangani
/// aniqlansa ham, ishni `CaseStatus.analysisReady`ga o'tkazish bu
/// usecase'ning ishi EMAS -- `AdvanceCaseStatusUseCase` alohida, aniq
/// chaqiriladi (Module 5, Phase 5B'da o'rnatilgan intizom: "qachon
/// o'tish kerak" qarori kod ichida taxmin qilinmaydi).
class EvaluateCaseCompletenessUseCase {
  const EvaluateCaseCompletenessUseCase({
    required GetCaseUseCase getCase,
    required InformationCompletenessEvaluator evaluator,
  }) : _getCase = getCase,
       _evaluator = evaluator;

  final GetCaseUseCase _getCase;
  final InformationCompletenessEvaluator _evaluator;

  /// Tashlaydi: `CaseNotFoundException`, `CaseAccessDeniedException`
  /// (`GetCaseUseCase` orqali -- egalik tekshiruvi).
  InformationCompleteness call({required String caseId, required String requestingUserId}) {
    final case_ = _getCase(caseId: caseId, requestingUserId: requestingUserId);
    return _evaluator.evaluate(
      category: case_.category,
      collected: case_.collectedInformation,
    );
  }
}
