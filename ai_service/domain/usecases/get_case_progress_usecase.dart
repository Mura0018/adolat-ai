import '../workflow/completeness/information_completeness_evaluator.dart';
import '../workflow/progress/case_progress.dart';
import 'get_case_usecase.dart';

/// Ish progressini qaytaradi -- nima to'plangan, nima yetishmayapti
/// (Module 5, Phase 5C talabi: "Progress tracking").
///
/// **Progress SAQLANMAYDI, HISOBLANADI:** `CaseProgress` hech qayerda
/// yozilmaydi -- har safar joriy `Case.collectedInformation` va
/// katalogdan qayta hisoblanadi. Shu bilan katalog o'zgarganda
/// (yangi majburiy bo'lak qo'shilganda) mavjud ishlarning progressi
/// AVTOMATIK to'g'ri qoladi; saqlangan progress esa eskirib qolardi.
class GetCaseProgressUseCase {
  const GetCaseProgressUseCase({
    required GetCaseUseCase getCase,
    required InformationCompletenessEvaluator evaluator,
  }) : _getCase = getCase,
       _evaluator = evaluator;

  final GetCaseUseCase _getCase;
  final InformationCompletenessEvaluator _evaluator;

  /// Tashlaydi: `CaseNotFoundException`, `CaseAccessDeniedException`.
  CaseProgress call({required String caseId, required String requestingUserId}) {
    final case_ = _getCase(caseId: caseId, requestingUserId: requestingUserId);
    return CaseProgress(
      caseId: case_.id,
      status: case_.status,
      completeness: _evaluator.evaluate(
        category: case_.category,
        collected: case_.collectedInformation,
      ),
    );
  }
}
