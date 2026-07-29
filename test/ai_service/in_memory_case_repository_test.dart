import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_case_repository.dart';
import '../../ai_service/domain/case/case_category.dart';
import '../../ai_service/domain/case/case_exceptions.dart';
import '../../ai_service/domain/case/case_priority.dart';
import '../../ai_service/domain/case/case_status.dart';
import '../../ai_service/domain/case/case_timeline.dart';

void main() {
  group('InMemoryCaseRepository', () {
    test('create returns a case with status created and a caseCreated timeline event', () {
      final repo = InMemoryCaseRepository();

      final case_ = repo.create(
        userId: 'user1',
        category: CaseCategory.complaint,
        problemSummary: 'shikoyat matni',
        conversationId: 'conv1',
      );

      expect(case_.status, CaseStatus.created);
      expect(case_.userId, 'user1');
      expect(case_.priority, CasePriority.normal);
      expect(case_.timeline.events, hasLength(1));
      expect(case_.timeline.events.single.type, CaseTimelineEventType.caseCreated);
    });

    test('create honors an explicit priority', () {
      final repo = InMemoryCaseRepository();

      final case_ = repo.create(
        userId: 'user1',
        category: CaseCategory.complaint,
        problemSummary: 'x',
        conversationId: 'conv1',
        priority: CasePriority.urgent,
      );

      expect(case_.priority, CasePriority.urgent);
    });

    test('getById returns null for an unknown id', () {
      final repo = InMemoryCaseRepository();

      expect(repo.getById('unknown'), isNull);
    });

    test('getById returns the persisted case after creation', () {
      final repo = InMemoryCaseRepository();
      final created = repo.create(
        userId: 'user1',
        category: CaseCategory.application,
        problemSummary: 'x',
        conversationId: 'conv1',
      );

      expect(repo.getById(created.id), created);
    });

    test('listForUser returns only that user\'s cases', () {
      final repo = InMemoryCaseRepository();
      repo.create(
        userId: 'user1',
        category: CaseCategory.complaint,
        problemSummary: 'x',
        conversationId: 'conv1',
      );
      repo.create(
        userId: 'user2',
        category: CaseCategory.complaint,
        problemSummary: 'y',
        conversationId: 'conv2',
      );
      repo.create(
        userId: 'user1',
        category: CaseCategory.application,
        problemSummary: 'z',
        conversationId: 'conv3',
      );

      final cases = repo.listForUser('user1');

      expect(cases, hasLength(2));
      expect(cases.every((c) => c.userId == 'user1'), isTrue);
    });

    test('listForUser returns an empty list for a user with no cases', () {
      final repo = InMemoryCaseRepository();

      expect(repo.listForUser('nobody'), isEmpty);
    });

    test('updateStatus transitions the case and appends a statusChanged event', () {
      final repo = InMemoryCaseRepository();
      final created = repo.create(
        userId: 'user1',
        category: CaseCategory.complaint,
        problemSummary: 'x',
        conversationId: 'conv1',
      );

      final updated = repo.updateStatus(created.id, CaseStatus.understanding);

      expect(updated.status, CaseStatus.understanding);
      expect(updated.timeline.events, hasLength(2)); // caseCreated + statusChanged
      expect(updated.timeline.events.last.type, CaseTimelineEventType.statusChanged);
    });

    test('updateStatus throws CaseNotFoundException for an unknown case', () {
      final repo = InMemoryCaseRepository();

      expect(
        () => repo.updateStatus('unknown', CaseStatus.understanding),
        throwsA(isA<CaseNotFoundException>()),
      );
    });

    test('updateStatus propagates InvalidCaseStatusTransitionException', () {
      final repo = InMemoryCaseRepository();
      final created = repo.create(
        userId: 'user1',
        category: CaseCategory.complaint,
        problemSummary: 'x',
        conversationId: 'conv1',
      );
      final archived = repo.updateStatus(created.id, CaseStatus.archived);
      expect(archived.status, CaseStatus.archived);

      expect(
        () => repo.updateStatus(created.id, CaseStatus.understanding),
        throwsA(isA<InvalidCaseStatusTransitionException>()),
      );
    });

    test('addTimelineEvent appends without changing status', () {
      final repo = InMemoryCaseRepository();
      final created = repo.create(
        userId: 'user1',
        category: CaseCategory.complaint,
        problemSummary: 'x',
        conversationId: 'conv1',
      );

      final updated = repo.addTimelineEvent(
        created.id,
        CaseTimelineEvent(
          id: 'evt_manual',
          type: CaseTimelineEventType.note,
          description: 'qo\'lda eslatma',
          occurredAt: DateTime(2026, 1, 1),
        ),
      );

      expect(updated.status, CaseStatus.created);
      expect(updated.timeline.events, hasLength(2));
    });

    test('addTimelineEvent throws CaseNotFoundException for an unknown case', () {
      final repo = InMemoryCaseRepository();

      expect(
        () => repo.addTimelineEvent(
          'unknown',
          CaseTimelineEvent(
            id: 'evt1',
            type: CaseTimelineEventType.note,
            description: 'x',
            occurredAt: DateTime(2026, 1, 1),
          ),
        ),
        throwsA(isA<CaseNotFoundException>()),
      );
    });
  });
}
