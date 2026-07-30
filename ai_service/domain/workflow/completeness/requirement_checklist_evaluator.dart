import '../../case/case_category.dart';
import '../collected_information.dart';
import '../information_requirement.dart';
import '../information_requirement_catalog.dart';
import 'information_completeness.dart';
import 'information_completeness_evaluator.dart';

/// `InformationCompletenessEvaluator`ning XOLIS (pure), qaror
/// qabul QILMAYDIGAN implementatsiyasi: katalogdagi har bir bo'lak
/// `CollectedInformation`da bormi -- shu, boshqa hech narsa.
///
/// **Nega `data/`da emas, `domain/`da:** bu klassda hech qanday
/// MAZMUN (savol matni, shablon) yo'q -- faqat QOIDA.
/// `isValidCaseStatusTransition` (Module 5, Phase 5B) `domain/`da
/// bo'lgani bilan bir xil mezon; mazmun esa katalog
/// implementatsiyasida (`data/workflow/`) yotadi.
class RequirementChecklistEvaluator implements InformationCompletenessEvaluator {
  const RequirementChecklistEvaluator(this._catalog);

  final InformationRequirementCatalog _catalog;

  @override
  InformationCompleteness evaluate({
    required CaseCategory category,
    required CollectedInformation collected,
  }) {
    final satisfied = <InformationRequirement>[];
    final missing = <InformationRequirement>[];

    // Katalogdagi TARTIB saqlanadi -- aniqlashtiruvchi savollar
    // ketma-ketligi shu tartibga tayanadi (`ClarificationWorkflow`).
    for (final requirement in _catalog.requirementsFor(category)) {
      if (collected.has(requirement.id)) {
        satisfied.add(requirement);
      } else {
        missing.add(requirement);
      }
    }

    return InformationCompleteness(
      satisfied: List.unmodifiable(satisfied),
      missing: List.unmodifiable(missing),
    );
  }
}
