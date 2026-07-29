import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_case_repository.dart';
import '../../ai_service/data/session/in_memory_conversation_repository.dart';
import '../../ai_service/domain/case/case_category.dart';
import '../../ai_service/domain/case/case_exceptions.dart';
import '../../ai_service/domain/case/case_timeline.dart';
import '../../ai_service/domain/entities/ai_message.dart';
import '../../ai_service/domain/usecases/record_case_answer_usecase.dart';

void main() {
  group('RecordCaseAnswerUseCase', () {
    test('appends the answer to the conversation and a userAnswered timeline event', () {
      final caseRepository = InMemoryCaseRepository();
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final created = caseRepository.create(
        userId: 'user1',
        category: CaseCategory.complaint,
        problemSummary: 'x',
        conversationId: conversation.id,
      );
      final useCase = RecordCaseAnswerUseCase(
        caseRepository: caseRepository,
        conversationRepository: conversationRepository,
      );

      final updated = useCase(caseId: created.id, answer: 'Voqea 2026-yil yanvarida sodir bo\'lgan');

      final updatedConversation = conversationRepository.getById(conversation.id)!;
      expect(updatedConversation.messages.last.role, AIMessageRole.user);
      expect(updatedConversation.messages.last.content, 'Voqea 2026-yil yanvarida sodir bo\'lgan');
      expect(updated.timeline.events.last.type, CaseTimelineEventType.userAnswered);
    });

    test('throws CaseNotFoundException for an unknown case', () {
      final caseRepository = InMemoryCaseRepository();
      final conversationRepository = InMemoryConversationRepository();
      final useCase = RecordCaseAnswerUseCase(
        caseRepository: caseRepository,
        conversationRepository: conversationRepository,
      );

      expect(
        () => useCase(caseId: 'unknown', answer: 'x'),
        throwsA(isA<CaseNotFoundException>()),
      );
    });
  });
}
