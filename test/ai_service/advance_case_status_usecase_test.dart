import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_case_repository.dart';
import '../../ai_service/domain/case/case_category.dart';
import '../../ai_service/domain/case/case_exceptions.dart';
import '../../ai_service/domain/case/case_status.dart';
import '../../ai_service/domain/usecases/advance_case_status_usecase.dart';

void main() {
  group('AdvanceCaseStatusUseCase', () {
    test('transitions a case to a new valid status', () {
      final caseRepository = InMemoryCaseRepository();
      final created = caseRepository.create(
        userId: 'user1',
        category: CaseCategory.complaint,
        problemSummary: 'x',
        conversationId: 'conv1',
      );
      final useCase = AdvanceCaseStatusUseCase(caseRepository);

      final updated = useCase(caseId: created.id, newStatus: CaseStatus.understanding);

      expect(updated.status, CaseStatus.understanding);
    });

    test('throws InvalidCaseStatusTransitionException for an invalid transition', () {
      final caseRepository = InMemoryCaseRepository();
      final created = caseRepository.create(
        userId: 'user1',
        category: CaseCategory.complaint,
        problemSummary: 'x',
        conversationId: 'conv1',
      );
      final useCase = AdvanceCaseStatusUseCase(caseRepository);
      useCase(caseId: created.id, newStatus: CaseStatus.completed);

      expect(
        () => useCase(caseId: created.id, newStatus: CaseStatus.understanding),
        throwsA(isA<InvalidCaseStatusTransitionException>()),
      );
    });

    test('throws CaseNotFoundException for an unknown case', () {
      final caseRepository = InMemoryCaseRepository();
      final useCase = AdvanceCaseStatusUseCase(caseRepository);

      expect(
        () => useCase(caseId: 'unknown', newStatus: CaseStatus.understanding),
        throwsA(isA<CaseNotFoundException>()),
      );
    });
  });
}
