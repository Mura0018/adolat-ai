import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/case/case_status.dart';

void main() {
  group('isValidCaseStatusTransition', () {
    test('rejects transitioning to the same status', () {
      for (final status in CaseStatus.values) {
        expect(isValidCaseStatusTransition(from: status, to: status), isFalse);
      }
    });

    test('archived is terminal -- no outgoing transitions', () {
      for (final to in CaseStatus.values) {
        if (to == CaseStatus.archived) continue;
        expect(isValidCaseStatusTransition(from: CaseStatus.archived, to: to), isFalse);
      }
    });

    test('any active status can transition to archived', () {
      for (final from in CaseStatus.values) {
        if (from == CaseStatus.archived) continue;
        expect(isValidCaseStatusTransition(from: from, to: CaseStatus.archived), isTrue);
      }
    });

    test('completed can only transition to archived -- no reopening', () {
      for (final to in CaseStatus.values) {
        if (to == CaseStatus.archived) continue;
        expect(isValidCaseStatusTransition(from: CaseStatus.completed, to: to), isFalse);
      }
    });

    test('active, non-completed statuses can move both forward and backward', () {
      expect(
        isValidCaseStatusTransition(
          from: CaseStatus.analysisReady,
          to: CaseStatus.informationGathering,
        ),
        isTrue,
      );
      expect(
        isValidCaseStatusTransition(from: CaseStatus.created, to: CaseStatus.actionPlanning),
        isTrue,
      );
    });

    test('isActive/isTerminal are mutually exclusive and correct', () {
      for (final status in CaseStatus.values) {
        expect(status.isActive, status != CaseStatus.archived);
        expect(status.isTerminal, status == CaseStatus.archived);
      }
    });
  });
}
