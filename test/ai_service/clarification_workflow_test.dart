import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/case/case_category.dart';
import '../../ai_service/domain/workflow/clarification/clarification_workflow.dart';
import '../../ai_service/domain/workflow/collected_information.dart';
import '../../ai_service/domain/workflow/completeness/requirement_checklist_evaluator.dart';
import '../../ai_service/domain/workflow/information_requirement.dart';
import '../../ai_service/domain/workflow/information_requirement_catalog.dart';

class _FakeCatalog implements InformationRequirementCatalog {
  const _FakeCatalog(this.requirements);

  final List<InformationRequirement> requirements;

  @override
  List<InformationRequirement> requirementsFor(CaseCategory category) => requirements;
}

const _optionalFirst = InformationRequirement(
  id: 'optional_first',
  question: 'Ixtiyoriy?',
  importance: InformationImportance.optional,
);
const _mandatoryOne = InformationRequirement(id: 'mandatory_one', question: 'Birinchi?');
const _mandatoryTwo = InformationRequirement(id: 'mandatory_two', question: 'Ikkinchi?');

ClarificationWorkflow _workflow(List<InformationRequirement> requirements) {
  return ClarificationWorkflow(RequirementChecklistEvaluator(_FakeCatalog(requirements)));
}

void main() {
  group('ClarificationWorkflow.remainingSteps', () {
    test('asks mandatory requirements before optional ones, even if declared later', () {
      final workflow = _workflow([_optionalFirst, _mandatoryOne, _mandatoryTwo]);

      final steps = workflow.remainingSteps(
        category: CaseCategory.complaint,
        collected: const CollectedInformation(),
      );

      expect(steps.map((s) => s.requirement.id), [
        'mandatory_one',
        'mandatory_two',
        'optional_first',
      ]);
    });

    test('numbers steps from 1 and marks the last one as final', () {
      final workflow = _workflow([_mandatoryOne, _mandatoryTwo]);

      final steps = workflow.remainingSteps(
        category: CaseCategory.complaint,
        collected: const CollectedInformation(),
      );

      expect(steps.map((s) => s.stepNumber), [1, 2]);
      expect(steps.every((s) => s.totalSteps == 2), isTrue);
      expect(steps.first.isFinal, isFalse);
      expect(steps.last.isFinal, isTrue);
    });

    test('already answered requirements drop out of the flow and it renumbers', () {
      final workflow = _workflow([_mandatoryOne, _mandatoryTwo, _optionalFirst]);

      final steps = workflow.remainingSteps(
        category: CaseCategory.complaint,
        collected: const CollectedInformation(entries: {'mandatory_one': 'javob'}),
      );

      expect(steps.map((s) => s.requirement.id), ['mandatory_two', 'optional_first']);
      expect(steps.map((s) => s.stepNumber), [1, 2]);
      expect(steps.first.totalSteps, 2);
    });
  });

  group('ClarificationWorkflow.nextStep', () {
    test('returns the first remaining question', () {
      final workflow = _workflow([_mandatoryOne, _mandatoryTwo]);

      final step = workflow.nextStep(
        category: CaseCategory.complaint,
        collected: const CollectedInformation(),
      );

      expect(step?.requirement, _mandatoryOne);
    });

    test('returns null once every question -- including optional -- is answered', () {
      final workflow = _workflow([_mandatoryOne, _optionalFirst]);

      final step = workflow.nextStep(
        category: CaseCategory.complaint,
        collected: const CollectedInformation(
          entries: {'mandatory_one': 'javob', 'optional_first': 'javob'},
        ),
      );

      expect(step, isNull);
      expect(
        workflow.isComplete(
          category: CaseCategory.complaint,
          collected: const CollectedInformation(
            entries: {'mandatory_one': 'javob', 'optional_first': 'javob'},
          ),
        ),
        isTrue,
      );
    });

    test('an unanswered optional question still keeps the flow open', () {
      final workflow = _workflow([_mandatoryOne, _optionalFirst]);
      const collected = CollectedInformation(entries: {'mandatory_one': 'javob'});

      // Majburiylar to'liq (isSufficient == true) bo'lsa ham, oqim
      // hali tugamagan -- bu ikkisi ATAYLAB har xil tushuncha.
      expect(
        workflow.isComplete(category: CaseCategory.complaint, collected: collected),
        isFalse,
      );
      expect(
        workflow.nextStep(category: CaseCategory.complaint, collected: collected)?.requirement,
        _optionalFirst,
      );
    });
  });

  group('ClarificationWorkflow statelessness', () {
    test('recomputes from the given information every call -- keeps no internal state', () {
      final workflow = _workflow([_mandatoryOne]);

      final before = workflow.nextStep(
        category: CaseCategory.complaint,
        collected: const CollectedInformation(),
      );
      final after = workflow.nextStep(
        category: CaseCategory.complaint,
        collected: const CollectedInformation(entries: {'mandatory_one': 'javob'}),
      );
      final againBefore = workflow.nextStep(
        category: CaseCategory.complaint,
        collected: const CollectedInformation(),
      );

      expect(before, isNotNull);
      expect(after, isNull);
      expect(againBefore, before);
    });
  });
}
