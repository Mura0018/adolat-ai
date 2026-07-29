import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/case/case.dart';
import '../../ai_service/domain/case/case_category.dart';
import '../../ai_service/domain/case/case_exceptions.dart';
import '../../ai_service/domain/case/case_priority.dart';
import '../../ai_service/domain/case/case_status.dart';
import '../../ai_service/domain/case/case_timeline.dart';

Case _case({CaseStatus status = CaseStatus.created, String problemSummary = 'sezgir matn'}) {
  return Case(
    id: 'case1',
    userId: 'user1',
    category: CaseCategory.complaint,
    priority: CasePriority.normal,
    status: status,
    conversationId: 'conv1',
    problemSummary: problemSummary,
    timeline: const CaseTimeline(),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('Case.withStatus', () {
    test('returns a new immutable instance on a valid transition', () {
      final original = _case();

      final updated = original.withStatus(CaseStatus.understanding, at: DateTime(2026, 1, 2));

      expect(original.status, CaseStatus.created);
      expect(updated.status, CaseStatus.understanding);
      expect(updated.updatedAt, DateTime(2026, 1, 2));
    });

    test('throws InvalidCaseStatusTransitionException on an invalid transition', () {
      final archived = _case(status: CaseStatus.archived);

      expect(
        () => archived.withStatus(CaseStatus.understanding, at: DateTime(2026, 1, 2)),
        throwsA(isA<InvalidCaseStatusTransitionException>()),
      );
    });

    test('does not itself append a timeline event', () {
      final original = _case();

      final updated = original.withStatus(CaseStatus.understanding, at: DateTime(2026, 1, 2));

      expect(updated.timeline.events, isEmpty);
    });
  });

  group('Case.appendTimelineEvent', () {
    test('returns a new instance with the event appended and updatedAt bumped', () {
      final original = _case();
      final event = CaseTimelineEvent(
        id: 'evt1',
        type: CaseTimelineEventType.note,
        description: 'x',
        occurredAt: DateTime(2026, 1, 3),
      );

      final updated = original.appendTimelineEvent(event);

      expect(original.timeline.events, isEmpty);
      expect(updated.timeline.events, [event]);
      expect(updated.updatedAt, DateTime(2026, 1, 3));
    });
  });

  group('Case.toString', () {
    test('never includes the raw problemSummary', () {
      final case_ = _case(problemSummary: 'juda maxfiy shaxsiy tafsilot');

      expect(case_.toString().contains('juda maxfiy shaxsiy tafsilot'), isFalse);
    });
  });

  group('Case.isTerminal', () {
    test('is true only for archived', () {
      expect(_case(status: CaseStatus.archived).isTerminal, isTrue);
      expect(_case(status: CaseStatus.completed).isTerminal, isFalse);
    });
  });
}
