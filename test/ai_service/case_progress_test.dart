import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/case/case_status.dart';
import '../../ai_service/domain/workflow/completeness/information_completeness.dart';
import '../../ai_service/domain/workflow/information_requirement.dart';
import '../../ai_service/domain/workflow/progress/case_progress.dart';

const _done = InformationRequirement(id: 'done', question: 'Berilgan?');
const _missingMandatory = InformationRequirement(id: 'missing', question: 'Yetishmayapti?');
const _missingOptional = InformationRequirement(
  id: 'optional',
  question: 'Ixtiyoriy?',
  importance: InformationImportance.optional,
);

void main() {
  group('CaseProgress information view', () {
    const progress = CaseProgress(
      caseId: 'case1',
      status: CaseStatus.informationGathering,
      completeness: InformationCompleteness(
        satisfied: [_done],
        missing: [_missingMandatory, _missingOptional],
      ),
    );

    test('shows what is complete', () {
      expect(progress.completedInformation, [_done]);
      expect(progress.completedCount, 1);
    });

    test('shows what is still missing, and which of it blocks progress', () {
      expect(progress.missingInformation, [_missingMandatory, _missingOptional]);
      expect(progress.missingMandatoryInformation, [_missingMandatory]);
      expect(progress.isInformationSufficient, isFalse);
    });

    test('reports a ratio over all requirements', () {
      expect(progress.totalCount, 3);
      expect(progress.informationCompletionRatio, closeTo(1 / 3, 0.0001));
    });
  });

  group('CaseProgress lifecycle view', () {
    test('reports the lifecycle stage position independently of information progress', () {
      const progress = CaseProgress(
        caseId: 'case1',
        status: CaseStatus.created,
        completeness: InformationCompleteness(satisfied: [_done], missing: []),
      );

      expect(progress.isInformationSufficient, isTrue);
      // Ma'lumot to'liq bo'lsa ham, ish hali birinchi bosqichda --
      // holatni siljitish alohida, aniq qaror.
      expect(progress.lifecycleStageIndex, 1);
      expect(progress.lifecycleStageCount, CaseStatus.values.length);
    });

    test('the last lifecycle stage is archived', () {
      const progress = CaseProgress(
        caseId: 'case1',
        status: CaseStatus.archived,
        completeness: InformationCompleteness(satisfied: [], missing: []),
      );

      expect(progress.lifecycleStageIndex, progress.lifecycleStageCount);
    });
  });

  group('CaseProgress.toString', () {
    test('never leaks answers -- it only ever holds requirements', () {
      const progress = CaseProgress(
        caseId: 'case1',
        status: CaseStatus.created,
        completeness: InformationCompleteness(satisfied: [_done], missing: [_missingMandatory]),
      );

      expect(progress.toString().contains('1/2'), isTrue);
    });
  });
}
