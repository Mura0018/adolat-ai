import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_cancellation_registry.dart';
import '../../ai_service/data/session/in_memory_conversation_repository.dart';
import '../../ai_service/domain/entities/ai_cancellation_token.dart';
import '../../ai_service/domain/entities/ai_context.dart';
import '../../ai_service/domain/entities/ai_conversation.dart';
import '../../ai_service/domain/entities/ai_failure.dart';
import '../../ai_service/domain/entities/ai_message.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';
import '../../ai_service/domain/entities/ai_response.dart';
import '../../ai_service/domain/entities/ai_stream_event.dart';
import '../../ai_service/domain/repositories/ai_repository.dart';
import '../../ai_service/domain/retry/ai_retry_policy.dart';
import '../../ai_service/domain/usecases/send_conversation_message_usecase.dart';

/// Beriladigan hodisalar ketma-ketligini (event ro'yxati) qaytaruvchi
/// soxta (fake) `AIRepository` — provayder/xavfsizlik mantig'ini emas,
/// faqat usecase'ning suhbat tarixi/qayta urinish bilan bog'lanishini
/// tekshirish uchun. Har bir chaqiruvda scriptlar ro'yxatidan navbatdagisi
/// ishlatiladi -- shuning uchun qayta urinishni skriptlash mumkin.
class _ScriptedAIRepository implements AIRepository {
  _ScriptedAIRepository(this._scripts);

  final List<List<AIStreamEvent>> _scripts;
  int callCount = 0;

  @override
  Stream<AIStreamEvent> sendMessage({
    required AIConversation conversation,
    required AIContext context,
    required AIProviderId providerId,
    AICancellationToken? cancellationToken,
  }) async* {
    final events = _scripts[callCount];
    callCount += 1;
    for (final event in events) {
      yield event;
    }
  }
}

void main() {
  group('SendConversationMessageUseCase -- conversation history', () {
    test('records the user message immediately, before the response arrives', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final repository = _ScriptedAIRepository([
        [
          AIStreamEventDone(
            response: AIResponse(
              id: 'r1',
              conversationId: conversation.id,
              content: 'assistant reply',
              providerId: AIProviderId.openAI,
              modelVersion: 'fake-v1',
              completedAt: DateTime(2026, 1, 1),
            ),
          ),
        ],
      ]);
      final useCase = SendConversationMessageUseCase(
        repository: repository,
        conversationRepository: conversationRepository,
        cancellationRegistry: InMemoryCancellationRegistry(),
      );

      final events = await useCase(
        conversationId: conversation.id,
        userMessageContent: 'user question',
        context: const AIContext(sections: {}),
        providerId: AIProviderId.openAI,
      ).toList();

      expect(events.single, isA<AIStreamEventDone>());

      final finalConversation = conversationRepository.getById(conversation.id)!;
      expect(finalConversation.messages, hasLength(2));
      expect(finalConversation.messages[0].role, AIMessageRole.user);
      expect(finalConversation.messages[0].content, 'user question');
      expect(finalConversation.messages[1].role, AIMessageRole.assistant);
      expect(finalConversation.messages[1].content, 'assistant reply');
    });

    test('does not append an assistant message on a terminal error', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final repository = _ScriptedAIRepository([
        [
          const AIStreamEventError(
            failure: AISafetyRejectionFailure(reason: 'blocked'),
          ),
        ],
      ]);
      final useCase = SendConversationMessageUseCase(
        repository: repository,
        conversationRepository: conversationRepository,
        cancellationRegistry: InMemoryCancellationRegistry(),
      );

      await useCase(
        conversationId: conversation.id,
        userMessageContent: 'user question',
        context: const AIContext(sections: {}),
        providerId: AIProviderId.openAI,
      ).toList();

      final finalConversation = conversationRepository.getById(conversation.id)!;
      expect(finalConversation.messages, hasLength(1)); // only the user message
      expect(finalConversation.messages.single.role, AIMessageRole.user);
    });

    test('does not append an assistant message on cancellation', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final repository = _ScriptedAIRepository([
        [const AIStreamEventCancelled()],
      ]);
      final useCase = SendConversationMessageUseCase(
        repository: repository,
        conversationRepository: conversationRepository,
        cancellationRegistry: InMemoryCancellationRegistry(),
      );

      await useCase(
        conversationId: conversation.id,
        userMessageContent: 'user question',
        context: const AIContext(sections: {}),
        providerId: AIProviderId.openAI,
      ).toList();

      final finalConversation = conversationRepository.getById(conversation.id)!;
      expect(finalConversation.messages, hasLength(1));
    });

    test(
      'yields AIConversationNotFoundFailure without calling the repository when the conversation is unknown',
      () async {
        final repository = _ScriptedAIRepository([]);
        final useCase = SendConversationMessageUseCase(
          repository: repository,
          conversationRepository: InMemoryConversationRepository(),
          cancellationRegistry: InMemoryCancellationRegistry(),
        );

        final events = await useCase(
          conversationId: 'unknown',
          userMessageContent: 'hi',
          context: const AIContext(sections: {}),
          providerId: AIProviderId.openAI,
        ).toList();

        expect(repository.callCount, 0);
        expect(events.single, isA<AIStreamEventError>());
        expect(
          (events.single as AIStreamEventError).failure,
          isA<AIConversationNotFoundFailure>(),
        );
      },
    );

    test(
      'yields AIConversationClosedFailure without calling the repository when the conversation is closed',
      () async {
        final conversationRepository = InMemoryConversationRepository();
        final conversation = conversationRepository.create();
        conversationRepository.close(conversation.id);
        final repository = _ScriptedAIRepository([]);
        final useCase = SendConversationMessageUseCase(
          repository: repository,
          conversationRepository: conversationRepository,
          cancellationRegistry: InMemoryCancellationRegistry(),
        );

        final events = await useCase(
          conversationId: conversation.id,
          userMessageContent: 'hi',
          context: const AIContext(sections: {}),
          providerId: AIProviderId.openAI,
        ).toList();

        expect(repository.callCount, 0);
        expect(events.single, isA<AIStreamEventError>());
        expect(
          (events.single as AIStreamEventError).failure,
          isA<AIConversationClosedFailure>(),
        );
      },
    );
  });

  group('SendConversationMessageUseCase -- retry', () {
    test('retries a retryable failure that produced no chunks, then succeeds', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final repository = _ScriptedAIRepository([
        [const AIStreamEventError(failure: AINetworkFailure())], // attempt 1
        [
          AIStreamEventDone(
            response: AIResponse(
              id: 'r1',
              conversationId: conversation.id,
              content: 'reply after retry',
              providerId: AIProviderId.openAI,
              modelVersion: 'fake-v1',
              completedAt: DateTime(2026, 1, 1),
            ),
          ),
        ], // attempt 2
      ]);
      final useCase = SendConversationMessageUseCase(
        repository: repository,
        conversationRepository: conversationRepository,
        cancellationRegistry: InMemoryCancellationRegistry(),
        retryPolicy: const AIRetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration.zero,
        ),
      );

      final events = await useCase(
        conversationId: conversation.id,
        userMessageContent: 'user question',
        context: const AIContext(sections: {}),
        providerId: AIProviderId.openAI,
      ).toList();

      expect(repository.callCount, 2);
      expect(events.single, isA<AIStreamEventDone>());

      final finalConversation = conversationRepository.getById(conversation.id)!;
      expect(finalConversation.messages, hasLength(2));
      expect(finalConversation.messages[1].content, 'reply after retry');
    });

    test('does not retry a non-retryable failure', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final repository = _ScriptedAIRepository([
        [const AIStreamEventError(failure: AISafetyRejectionFailure(reason: 'no'))],
      ]);
      final useCase = SendConversationMessageUseCase(
        repository: repository,
        conversationRepository: conversationRepository,
        cancellationRegistry: InMemoryCancellationRegistry(),
        retryPolicy: const AIRetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration.zero,
        ),
      );

      final events = await useCase(
        conversationId: conversation.id,
        userMessageContent: 'user question',
        context: const AIContext(sections: {}),
        providerId: AIProviderId.openAI,
      ).toList();

      expect(repository.callCount, 1);
      expect(events.single, isA<AIStreamEventError>());
    });
  });
}
