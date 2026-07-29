import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_case_repository.dart';
import '../../ai_service/domain/case/case_category.dart';
import '../../ai_service/domain/case/case_exceptions.dart';
import '../../ai_service/domain/usecases/get_case_usecase.dart';

void main() {
  group('GetCaseUseCase -- Phase 5B security rules', () {
    test('returns the case when the requesting user is the owner', () {
      final caseRepository = InMemoryCaseRepository();
      final created = caseRepository.create(
        userId: 'user1',
        category: CaseCategory.complaint,
        problemSummary: 'x',
        conversationId: 'conv1',
      );
      final useCase = GetCaseUseCase(caseRepository);

      final result = useCase(caseId: created.id, requestingUserId: 'user1');

      expect(result, created);
    });

    test('throws CaseAccessDeniedException when a different user requests the case', () {
      final caseRepository = InMemoryCaseRepository();
      final created = caseRepository.create(
        userId: 'user1',
        category: CaseCategory.complaint,
        problemSummary: 'x',
        conversationId: 'conv1',
      );
      final useCase = GetCaseUseCase(caseRepository);

      expect(
        () => useCase(caseId: created.id, requestingUserId: 'user2'),
        throwsA(isA<CaseAccessDeniedException>()),
      );
    });

    test('throws CaseNotFoundException for an unknown case, before any ownership check', () {
      final caseRepository = InMemoryCaseRepository();
      final useCase = GetCaseUseCase(caseRepository);

      expect(
        () => useCase(caseId: 'unknown', requestingUserId: 'user1'),
        throwsA(isA<CaseNotFoundException>()),
      );
    });
  });
}
