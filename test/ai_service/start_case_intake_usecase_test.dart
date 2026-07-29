import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/intake/mock_case_intake_assistant.dart';
import '../../ai_service/data/session/in_memory_case_repository.dart';
import '../../ai_service/data/session/in_memory_conversation_repository.dart';
import '../../ai_service/domain/case/case_category.dart';
import '../../ai_service/domain/case/case_status.dart';
import '../../ai_service/domain/case/case_timeline.dart';
import '../../ai_service/domain/entities/ai_message.dart';
import '../../ai_service/domain/usecases/start_case_intake_usecase.dart';

void main() {
  group('StartCaseIntakeUseCase', () {
    test('creates a case linked to a new conversation, in the understanding status', () async {
      final caseRepository = InMemoryCaseRepository();
      final conversationRepository = InMemoryConversationRepository();
      final useCase = StartCaseIntakeUseCase(
        caseRepository: caseRepository,
        conversationRepository: conversationRepository,
        intakeAssistant: const MockCaseIntakeAssistant(),
      );

      final case_ = await useCase(
        userId: 'user1',
        category: CaseCategory.complaint,
        problemDescription: 'Ishdan asossiz bo\'shatildim',
      );

      expect(case_.status, CaseStatus.understanding);
      expect(case_.userId, 'user1');
      expect(conversationRepository.getById(case_.conversationId), isNotNull);
    });

    test('writes the problem description as the first user message in the conversation', () async {
      final caseRepository = InMemoryCaseRepository();
      final conversationRepository = InMemoryConversationRepository();
      final useCase = StartCaseIntakeUseCase(
        caseRepository: caseRepository,
        conversationRepository: conversationRepository,
        intakeAssistant: const MockCaseIntakeAssistant(),
      );

      final case_ = await useCase(
        userId: 'user1',
        category: CaseCategory.complaint,
        problemDescription: 'Ishdan asossiz bo\'shatildim',
      );

      final conversation = conversationRepository.getById(case_.conversationId)!;
      expect(conversation.messages.first.role, AIMessageRole.user);
      expect(conversation.messages.first.content, 'Ishdan asossiz bo\'shatildim');
    });

    test('appends every clarification question as an assistant message and a timeline event', () async {
      final caseRepository = InMemoryCaseRepository();
      final conversationRepository = InMemoryConversationRepository();
      const assistant = MockCaseIntakeAssistant();
      final useCase = StartCaseIntakeUseCase(
        caseRepository: caseRepository,
        conversationRepository: conversationRepository,
        intakeAssistant: assistant,
      );

      final case_ = await useCase(
        userId: 'user1',
        category: CaseCategory.complaint,
        problemDescription: 'x',
      );

      final expectedQuestions = await assistant.generateClarificationQuestions(
        problemDescription: 'x',
        category: CaseCategory.complaint,
      );
      final conversation = conversationRepository.getById(case_.conversationId)!;
      final assistantMessages = conversation.messages
          .where((m) => m.role == AIMessageRole.assistant)
          .toList();

      expect(assistantMessages, hasLength(expectedQuestions.length));
      final questionEvents = case_.timeline.events
          .where((e) => e.type == CaseTimelineEventType.clarificationQuestionAsked)
          .toList();
      expect(questionEvents, hasLength(expectedQuestions.length));
    });

    test('does not depend on any real AI provider -- works purely with the mock assistant', () async {
      // Compile-time/architectural guarantee: this use case's constructor
      // only accepts CaseRepository/ConversationRepository/CaseIntakeAssistant
      // -- there is no AIProviderId/AIRepository parameter to wire a real
      // provider through, matching the "No AI provider dependency" rule.
      final caseRepository = InMemoryCaseRepository();
      final conversationRepository = InMemoryConversationRepository();
      final useCase = StartCaseIntakeUseCase(
        caseRepository: caseRepository,
        conversationRepository: conversationRepository,
        intakeAssistant: const MockCaseIntakeAssistant(),
      );

      final case_ = await useCase(
        userId: 'user1',
        category: CaseCategory.legalAssistance,
        problemDescription: 'x',
      );

      expect(case_, isNotNull);
    });
  });
}
