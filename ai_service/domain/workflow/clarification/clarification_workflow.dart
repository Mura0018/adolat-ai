import '../../case/case_category.dart';
import '../collected_information.dart';
import '../completeness/information_completeness_evaluator.dart';
import '../information_requirement.dart';
import 'clarification_step.dart';

/// Aniqlashtiruvchi savollar OQIMI (Module 5, Phase 5C talabi:
/// "Clarification workflow").
///
/// Xolis (pure) domen xizmati -- o'zida hech qanday holat saqlamaydi,
/// har safar joriy `CollectedInformation`dan QAYTA hisoblaydi.
/// `AIRetryExecutor`/`isValidCaseStatusTransition` (Module 4/5) bilan
/// bir xil ruh: qoida -- funksiya, holat -- chaqiruvchida.
///
/// **Savollar tartibi (ATAYLAB shu):**
/// 1. Avval MAJBURIY (`InformationImportance.mandatory`) bo'laklar --
///    katalogdagi tartibda;
/// 2. keyin IXTIYORIY bo'laklar.
///
/// Shu bilan foydalanuvchi oqimni yarim yo'lda to'xtatsa ham, eng
/// muhim ma'lumotlar allaqachon yig'ilgan bo'ladi.
///
/// **"AI determines missing information" qanday ta'minlangan:**
/// "yetishmayotgan"ni bu klass O'ZI o'ylab topmaydi -- uni
/// `InformationCompletenessEvaluator` hisoblaydi, savol matni esa
/// katalogdan keladi. Kelgusida haqiqiy AI shu IKKI chegaradan
/// birortasining ortiga qo'yilishi mumkin (masalan matndan qaysi
/// bo'lak allaqachon aytilganini aniqlaydigan evaluator) -- shu
/// klassning O'ZI o'zgarmaydi (talab: "No AI provider integration").
class ClarificationWorkflow {
  const ClarificationWorkflow(this._evaluator);

  final InformationCompletenessEvaluator _evaluator;

  /// Hali javob berilmagan savollar -- TARTIBLANGAN ro'yxat.
  /// Hammasi to'ldirilgan bo'lsa, bo'sh ro'yxat (xatolik EMAS).
  List<ClarificationStep> remainingSteps({
    required CaseCategory category,
    required CollectedInformation collected,
  }) {
    final completeness = _evaluator.evaluate(category: category, collected: collected);
    final ordered = <InformationRequirement>[
      ...completeness.missingMandatory,
      ...completeness.missingOptional,
    ];

    return List.unmodifiable([
      for (var i = 0; i < ordered.length; i++)
        ClarificationStep(
          requirement: ordered[i],
          stepNumber: i + 1,
          totalSteps: ordered.length,
        ),
    ]);
  }

  /// Navbatdagi BITTA savol; oqim tugagan bo'lsa `null`.
  ///
  /// `null` -- "boshi berk" holat emas: chaqiruvchi (`BuildCaseActionPlanUseCase`)
  /// bu holatda harakat rejasiga o'tadi (`DEVELOPMENT_RULES.md`,
  /// 18–19-band).
  ClarificationStep? nextStep({
    required CaseCategory category,
    required CollectedInformation collected,
  }) {
    final steps = remainingSteps(category: category, collected: collected);
    return steps.isEmpty ? null : steps.first;
  }

  /// Oqim tugadimi -- barcha (majburiy VA ixtiyoriy) savollarga javob
  /// berilganmi.
  ///
  /// **`InformationCompleteness.isSufficient` bilan ADASHTIRILMASIN:**
  /// u faqat MAJBURIY bo'laklarga qaraydi (keyingi bosqichga o'tish
  /// uchun yetarlimi), bu esa -- oqimda umuman savol qolmadimi.
  bool isComplete({
    required CaseCategory category,
    required CollectedInformation collected,
  }) {
    return remainingSteps(category: category, collected: collected).isEmpty;
  }
}
