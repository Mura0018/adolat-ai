import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_case_repository.dart';
import '../../ai_service/domain/case/case_category.dart';
import '../../ai_service/domain/usecases/list_user_cases_usecase.dart';

void main() {
  group('ListUserCasesUseCase -- Phase 5B security rules', () {
    test('only returns cases owned by the given user', () {
      final caseRepository = InMemoryCaseRepository();
      caseRepository.create(
        userId: 'user1',
        category: CaseCategory.complaint,
        problemSummary: 'x',
        conversationId: 'conv1',
      );
      caseRepository.create(
        userId: 'user2',
        category: CaseCategory.complaint,
        problemSummary: 'y',
        conversationId: 'conv2',
      );
      final useCase = ListUserCasesUseCase(caseRepository);

      final result = useCase('user1');

      expect(result, hasLength(1));
      expect(result.single.userId, 'user1');
    });

    test('returns an empty list for a user with no cases', () {
      final caseRepository = InMemoryCaseRepository();
      final useCase = ListUserCasesUseCase(caseRepository);

      expect(useCase('nobody'), isEmpty);
    });
  });
}
