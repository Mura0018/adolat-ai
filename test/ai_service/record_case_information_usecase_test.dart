import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_case_repository.dart';
import '../../ai_service/data/session/in_memory_conversation_repository.dart';
import '../../ai_service/data/workflow/static_information_requirement_catalog.dart';
import '../../ai_service/domain/case/case.dart';
import '../../ai_service/domain/case/case_category.dart';
import '../../ai_service/domain/case/case_exceptions.dart';
import '../../ai_service/domain/case/case_timeline.dart';
import '../../ai_service/domain/entities/ai_message.dart';
import '../../ai_service/domain/repositories/case_repository.dart';
import '../../ai_service/domain/usecases/get_case_usecase.dart';
import '../../ai_service/domain/usecases/record_case_answer_usecase.dart';
import '../../ai_service/domain/usecases/record_case_information_usecase.dart';
import '../../ai_service/domain/workflow/workflow_exceptions.dart';

class _Fixture {
  _Fixture({CaseCategory category = CaseCategory.complaint}) {
    caseRepository = InMemoryCaseRepository();
    conversationRepository = InMemoryConversationRepository();
    final conversation = conversationRepository.create();
    case_ = caseRepository.create(
      userId: 'user1',
      category: category,
      problemSummary: 'muammo',
      conversationId: conversation.id,
    );
    useCase = RecordCaseInformationUseCase(
      caseRepository: caseRepository,
      getCase: GetCaseUseCase(caseRepository),
      recordAnswer: RecordCaseAnswerUseCase(
        caseRepository: caseRepository,
        conversationRepository: conversationRepository,
      ),
      catalog: const StaticInformationRequirementCatalog(),
    );
  }

  late final CaseRepository caseRepository;
  late final InMemoryConversationRepository conversationRepository;
  late final Case case_;
  late final RecordCaseInformationUseCase useCase;
}

void main() {
  group('RecordCaseInformationUseCase', () {
    test('binds the answer to the requirement it belongs to', () {
      final fixture = _Fixture();

      final updated = fixture.useCase(
        caseId: fixture.case_.id,
        requestingUserId: 'user1',
        requirementId: 'complaint_target',
        value: 'Tuman hokimligi',
      );

      expect(updated.collectedInformation.has('complaint_target'), isTrue);
      expect(updated.collectedInformation.valueFor('complaint_target'), 'Tuman hokimligi');
    });

    test('also writes the answer to the conversation and the timeline', () {
      final fixture = _Fixture();

      final updated = fixture.useCase(
        caseId: fixture.case_.id,
        requestingUserId: 'user1',
        requirementId: 'complaint_target',
        value: 'Tuman hokimligi',
      );

      final conversation = fixture.conversationRepository.getById(fixture.case_.conversationId)!;
      expect(conversation.messages.last.role, AIMessageRole.user);
      expect(conversation.messages.last.content, 'Tuman hokimligi');
      expect(
        updated.timeline.events.last.type,
        CaseTimelineEventType.userAnswered,
      );
    });

    test('overwrites a previously given answer', () {
      final fixture = _Fixture();

      fixture.useCase(
        caseId: fixture.case_.id,
        requestingUserId: 'user1',
        requirementId: 'complaint_target',
        value: 'eski javob',
      );
      final updated = fixture.useCase(
        caseId: fixture.case_.id,
        requestingUserId: 'user1',
        requirementId: 'complaint_target',
        value: 'yangi javob',
      );

      expect(updated.collectedInformation.valueFor('complaint_target'), 'yangi javob');
      expect(updated.collectedInformation.filledCount, 1);
      // Tarix esa ikkala javobni ham saqlaydi -- audit izi o'chmaydi.
      expect(
        updated.timeline.events
            .where((e) => e.type == CaseTimelineEventType.userAnswered)
            .length,
        2,
      );
    });

    test('rejects a requirement that does not belong to the case category', () {
      final fixture = _Fixture();

      expect(
        () => fixture.useCase(
          caseId: fixture.case_.id,
          requestingUserId: 'user1',
          // `document_type` -- documentGeneration toifasining bo'lagi.
          requirementId: 'document_type',
          value: 'ariza',
        ),
        throwsA(isA<UnknownInformationRequirementException>()),
      );
    });

    test('writes nothing at all when the requirement is unknown', () {
      final fixture = _Fixture();

      try {
        fixture.useCase(
          caseId: fixture.case_.id,
          requestingUserId: 'user1',
          requirementId: 'nomavjud_bolak',
          value: 'javob',
        );
      } on UnknownInformationRequirementException {
        // kutilgan
      }

      final stored = fixture.caseRepository.getById(fixture.case_.id)!;
      final conversation = fixture.conversationRepository.getById(fixture.case_.conversationId)!;
      expect(stored.collectedInformation.isEmpty, isTrue);
      expect(conversation.messages, isEmpty);
    });

    test('refuses to write into another user\'s case', () {
      final fixture = _Fixture();

      expect(
        () => fixture.useCase(
          caseId: fixture.case_.id,
          requestingUserId: 'boshqa_user',
          requirementId: 'complaint_target',
          value: 'javob',
        ),
        throwsA(isA<CaseAccessDeniedException>()),
      );
    });

    test('throws when the case does not exist', () {
      final fixture = _Fixture();

      expect(
        () => fixture.useCase(
          caseId: 'nomavjud',
          requestingUserId: 'user1',
          requirementId: 'complaint_target',
          value: 'javob',
        ),
        throwsA(isA<CaseNotFoundException>()),
      );
    });
  });
}
