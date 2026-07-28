import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_cancellation_registry.dart';
import '../../ai_service/data/session/in_memory_conversation_repository.dart';
import '../../ai_service/domain/entities/ai_cancellation_token.dart';
import '../../ai_service/domain/entities/ai_context.dart';
import '../../ai_service/domain/entities/ai_conversation.dart';
import '../../ai_service/domain/entities/ai_message.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';
import '../../ai_service/domain/entities/ai_response.dart';
import '../../ai_service/domain/entities/ai_stream_event.dart';
import '../../ai_service/domain/repositories/ai_repository.dart';
import '../../ai_service/presentation/ai_service_handler.dart';

/// Beriladigan hodisalar ketma-ketligini (event ro'yxati) qaytaruvchi
/// soxta (fake) `AIRepository` — provayder/xavfsizlik mantig'ini emas,
/// faqat `AIServiceHandler`ning suhbat tarixi bilan bog'lanishini
/// tekshirish uchun.
class _ScriptedAIRepository implements AIRepository {
  _ScriptedAIRepository(this.events);

  final List<AIStreamEvent> events;
  bool wasCalled = false;

  @override
  Stream<AIStreamEvent> sendMessage({
    required AIConversation conversation,
    required AIContext context,
    required AIProviderId providerId,
    AICancellationToken? cancellationToken,
  }) async* {
    wasCalled = true;
    for (final event in events) {
      yield event;
    }
  }
}

void main() {
  group('AIServiceHandler.handleRequest', () {
    test('records the user message immediately, before the response arrives', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final repository = _ScriptedAIRepository([
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
      ]);
      final handler = AIServiceHandler(
        repository: repository,
        conversationRepository: conversationRepository,
        cancellationRegistry: InMemoryCancellationRegistry(),
      );

      final events = await handler
          .handleRequest(
            conversationId: conversation.id,
            userMessageContent: 'user question',
            context: const AIContext(sections: {}),
            providerId: AIProviderId.openAI,
          )
          .toList();

      expect(events.single, isA<AIStreamEventDone>());

      final finalConversation = conversationRepository.getById(conversation.id)!;
      expect(finalConversation.messages, hasLength(2));
      expect(finalConversation.messages[0].role, AIMessageRole.user);
      expect(finalConversation.messages[0].content, 'user question');
      expect(finalConversation.messages[1].role, AIMessageRole.assistant);
      expect(finalConversation.messages[1].content, 'assistant reply');
    });

    test('does not append an assistant message on error', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final repository = _ScriptedAIRepository([
        const AIStreamEventError(message: 'provider failed'),
      ]);
      final handler = AIServiceHandler(
        repository: repository,
        conversationRepository: conversationRepository,
        cancellationRegistry: InMemoryCancellationRegistry(),
      );

      await handler
          .handleRequest(
            conversationId: conversation.id,
            userMessageContent: 'user question',
            context: const AIContext(sections: {}),
            providerId: AIProviderId.openAI,
          )
          .toList();

      final finalConversation = conversationRepository.getById(conversation.id)!;
      expect(finalConversation.messages, hasLength(1)); // only the user message
      expect(finalConversation.messages.single.role, AIMessageRole.user);
    });

    test('does not append an assistant message on cancellation', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final repository = _ScriptedAIRepository([const AIStreamEventCancelled()]);
      final handler = AIServiceHandler(
        repository: repository,
        conversationRepository: conversationRepository,
        cancellationRegistry: InMemoryCancellationRegistry(),
      );

      await handler
          .handleRequest(
            conversationId: conversation.id,
            userMessageContent: 'user question',
            context: const AIContext(sections: {}),
            providerId: AIProviderId.openAI,
          )
          .toList();

      final finalConversation = conversationRepository.getById(conversation.id)!;
      expect(finalConversation.messages, hasLength(1));
    });

    test('errors without calling the repository when the conversation is unknown', () async {
      final repository = _ScriptedAIRepository([]);
      final handler = AIServiceHandler(
        repository: repository,
        conversationRepository: InMemoryConversationRepository(),
        cancellationRegistry: InMemoryCancellationRegistry(),
      );

      final events = await handler
          .handleRequest(
            conversationId: 'unknown',
            userMessageContent: 'hi',
            context: const AIContext(sections: {}),
            providerId: AIProviderId.openAI,
          )
          .toList();

      expect(repository.wasCalled, isFalse);
      expect(events.single, isA<AIStreamEventError>());
    });

    test('errors without calling the repository when the conversation is closed', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      conversationRepository.close(conversation.id);
      final repository = _ScriptedAIRepository([]);
      final handler = AIServiceHandler(
        repository: repository,
        conversationRepository: conversationRepository,
        cancellationRegistry: InMemoryCancellationRegistry(),
      );

      final events = await handler
          .handleRequest(
            conversationId: conversation.id,
            userMessageContent: 'hi',
            context: const AIContext(sections: {}),
            providerId: AIProviderId.openAI,
          )
          .toList();

      expect(repository.wasCalled, isFalse);
      expect(events.single, isA<AIStreamEventError>());
    });
  });

  group('AIServiceHandler.startConversation / cancelRequest', () {
    test('startConversation creates a conversation via the repository', () {
      final conversationRepository = InMemoryConversationRepository();
      final handler = AIServiceHandler(
        repository: _ScriptedAIRepository([]),
        conversationRepository: conversationRepository,
        cancellationRegistry: InMemoryCancellationRegistry(),
      );

      final id = handler.startConversation();

      expect(conversationRepository.getById(id), isNotNull);
    });

    test('cancelRequest delegates to the cancellation registry', () {
      final cancellationRegistry = InMemoryCancellationRegistry();
      final handler = AIServiceHandler(
        repository: _ScriptedAIRepository([]),
        conversationRepository: InMemoryConversationRepository(),
        cancellationRegistry: cancellationRegistry,
      );
      final token = cancellationRegistry.register('c1');

      handler.cancelRequest('c1');

      expect(token.isCancelled, isTrue);
    });
  });
}
