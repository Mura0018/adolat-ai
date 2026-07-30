import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/case/case_category.dart';
import '../../ai_service/domain/workflow/collected_information.dart';
import '../../ai_service/domain/workflow/completeness/requirement_checklist_evaluator.dart';
import '../../ai_service/domain/workflow/information_requirement.dart';
import '../../ai_service/domain/workflow/information_requirement_catalog.dart';

/// Test uchun oldindan bilinadigan katalog -- haqiqiy
/// `StaticInformationRequirementCatalog` mazmuni o'zgarsa ham bu
/// testlar buzilmasligi uchun.
class _FakeCatalog implements InformationRequirementCatalog {
  const _FakeCatalog(this.requirements);

  final List<InformationRequirement> requirements;

  @override
  List<InformationRequirement> requirementsFor(CaseCategory category) => requirements;
}

const _mandatoryA = InformationRequirement(id: 'a', question: 'A?');
const _mandatoryB = InformationRequirement(id: 'b', question: 'B?');
const _optionalC = InformationRequirement(
  id: 'c',
  question: 'C?',
  importance: InformationImportance.optional,
);

void main() {
  group('RequirementChecklistEvaluator', () {
    test('splits catalog requirements into satisfied and missing, preserving order', () {
      const evaluator = RequirementChecklistEvaluator(
        _FakeCatalog([_mandatoryA, _mandatoryB, _optionalC]),
      );

      final result = evaluator.evaluate(
        category: CaseCategory.complaint,
        collected: const CollectedInformation(entries: {'b': 'javob'}),
      );

      expect(result.satisfied, [_mandatoryB]);
      expect(result.missing, [_mandatoryA, _optionalC]);
      expect(result.totalCount, 3);
    });

    test('is not sufficient while a mandatory requirement is missing', () {
      const evaluator = RequirementChecklistEvaluator(_FakeCatalog([_mandatoryA, _optionalC]));

      final result = evaluator.evaluate(
        category: CaseCategory.complaint,
        collected: const CollectedInformation(),
      );

      expect(result.isSufficient, isFalse);
      expect(result.missingMandatory, [_mandatoryA]);
      expect(result.missingOptional, [_optionalC]);
    });

    test('is sufficient when only optional requirements remain', () {
      const evaluator = RequirementChecklistEvaluator(_FakeCatalog([_mandatoryA, _optionalC]));

      final result = evaluator.evaluate(
        category: CaseCategory.complaint,
        collected: const CollectedInformation(entries: {'a': 'javob'}),
      );

      expect(result.isSufficient, isTrue);
      expect(result.missing, [_optionalC]);
      expect(result.completionRatio, 0.5);
    });

    test('treats a blank answer as missing -- an empty string cannot fake progress', () {
      const evaluator = RequirementChecklistEvaluator(_FakeCatalog([_mandatoryA]));

      final result = evaluator.evaluate(
        category: CaseCategory.complaint,
        collected: const CollectedInformation(entries: {'a': '   '}),
      );

      expect(result.isSufficient, isFalse);
      expect(result.missing, [_mandatoryA]);
    });

    test('an empty catalog is sufficient and fully complete -- never a dead end', () {
      const evaluator = RequirementChecklistEvaluator(_FakeCatalog([]));

      final result = evaluator.evaluate(
        category: CaseCategory.complaint,
        collected: const CollectedInformation(),
      );

      expect(result.isSufficient, isTrue);
      expect(result.completionRatio, 1.0);
      expect(result.totalCount, 0);
    });

    test('completionRatio counts optional requirements too', () {
      const evaluator = RequirementChecklistEvaluator(
        _FakeCatalog([_mandatoryA, _mandatoryB, _optionalC]),
      );

      final result = evaluator.evaluate(
        category: CaseCategory.complaint,
        collected: const CollectedInformation(entries: {'a': '1', 'b': '2'}),
      );

      expect(result.isSufficient, isTrue);
      expect(result.completionRatio, closeTo(2 / 3, 0.0001));
    });
  });
}
