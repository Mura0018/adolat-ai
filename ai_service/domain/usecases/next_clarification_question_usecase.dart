import '../workflow/clarification/clarification_step.dart';
import '../workflow/clarification/clarification_workflow.dart';
import 'get_case_usecase.dart';

/// Ish bo'yicha navbatdagi aniqlashtiruvchi savolni qaytaradi
/// (Module 5, Phase 5C talabi: "Clarification workflow -- structured
/// question flow").
///
/// Savolni "o'ylab topmaydi": qaysi ma'lumot yetishmayotganini
/// `ClarificationWorkflow` (→ `InformationCompletenessEvaluator`)
/// hisoblaydi, savol matni esa katalogdan keladi -- ikkalasi ham
/// almashtiriladigan chegara, hech biri haqiqiy AI provayderiga
/// bog'lanmagan (talab: "No AI provider integration").
class NextClarificationQuestionUseCase {
  const NextClarificationQuestionUseCase({
    required GetCaseUseCase getCase,
    required ClarificationWorkflow workflow,
  }) : _getCase = getCase,
       _workflow = workflow;

  final GetCaseUseCase _getCase;
  final ClarificationWorkflow _workflow;

  /// Navbatdagi savol; barcha savollarga javob berilgan bo'lsa `null`.
  ///
  /// Tashlaydi: `CaseNotFoundException`, `CaseAccessDeniedException`.
  ClarificationStep? call({required String caseId, required String requestingUserId}) {
    final case_ = _getCase(caseId: caseId, requestingUserId: requestingUserId);
    return _workflow.nextStep(
      category: case_.category,
      collected: case_.collectedInformation,
    );
  }

  /// Qolgan BARCHA savollar -- foydalanuvchiga oldindan "yana nechta
  /// savol bor" ko'rinishini berish uchun (`DEVELOPMENT_RULES.md`,
  /// 19-band).
  List<ClarificationStep> remaining({
    required String caseId,
    required String requestingUserId,
  }) {
    final case_ = _getCase(caseId: caseId, requestingUserId: requestingUserId);
    return _workflow.remainingSteps(
      category: case_.category,
      collected: case_.collectedInformation,
    );
  }
}
