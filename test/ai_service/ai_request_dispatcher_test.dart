import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_cancellation_registry.dart';
import '../../ai_service/data/session/in_memory_conversation_repository.dart';
import '../../ai_service/domain/entities/ai_cancellation_token.dart';
import '../../ai_service/domain/entities/ai_context.dart';
import '../../ai_service/domain/entities/ai_conversation.dart';
import '../../ai_service/domain/entities/ai_failure.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';
import '../../ai_service/domain/entities/ai_response.dart';
import '../../ai_service/domain/entities/ai_stream_event.dart';
import '../../ai_service/domain/repositories/ai_repository.dart';
import '../../ai_service/domain/usecases/send_conversation_message_usecase.dart';
import '../../ai_service/gateway/auth/ai_auth_context.dart';
import '../../ai_service/gateway/dispatch/ai_request_dispatcher.dart';
import '../../ai_service/protocol/ai_request_envelope.dart';

class _ScriptedAIRepository implements AIRepository {
  _ScriptedAIRepository(this.events);

  final List<AIStreamEvent> events;
  AIContext? capturedContext;
  AIProviderId? capturedProviderId;

  @override
  Stream<AIStreamEvent> sendMessage({
    required AIConversation conversation,
    required AIContext context,
    required AIProviderId providerId,
    AICancellationToken? cancellationToken,
  }) async* {
    capturedContext = context;
    capturedProviderId = providerId;
    for (final event in events) {
      yield event;
    }
  }
}

AIRequestEnvelope _requestFor(
  String conversationId, {
  String userId = 'user1',
  Map<String, dynamic> context = const {},
}) {
  return AIRequestEnvelope(
    requestId: 'req1',
    conversationId: conversationId,
    userId: userId,
    message: 'savol',
    context: context,
    requestedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('AIRequestDispatcher -- authentication boundary', () {
    test('rejects with AIUnauthorizedFailure when not authenticated', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final repository = _ScriptedAIRepository([]);
      final dispatcher = AIRequestDispatcher(
        sendMessageUseCase: SendConversationMessageUseCase(
          repository: repository,
          conversationRepository: conversationRepository,
          cancellationRegistry: InMemoryCancellationRegistry(),
        ),
        selectProvider: (_) => AIProviderId.openAI,
      );

      final events = await dispatcher
          .dispatch(_requestFor(conversation.id), auth: AIAuthContext.unauthenticated)
          .toList();

      expect(events.single, isA<AIStreamEventError>());
      expect(
        (events.single as AIStreamEventError).failure,
        isA<AIUnauthorizedFailure>(),
      );
      expect(repository.capturedProviderId, isNull); // provider never called
    });

    test('rejects with AIUnauthorizedFailure when userId does not match auth', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final repository = _ScriptedAIRepository([]);
      final dispatcher = AIRequestDispatcher(
        sendMessageUseCase: SendConversationMessageUseCase(
          repository: repository,
          conversationRepository: conversationRepository,
          cancellationRegistry: InMemoryCancellationRegistry(),
        ),
        selectProvider: (_) => AIProviderId.openAI,
      );

      final events = await dispatcher
          .dispatch(
            _requestFor(conversation.id, userId: 'claimed-user'),
            auth: const AIAuthContext(isAuthenticated: true, userId: 'real-user'),
          )
          .toList();

      expect(
        (events.single as AIStreamEventError).failure,
        isA<AIUnauthorizedFailure>(),
      );
    });
  });

  group('AIRequestDispatcher -- request validation', () {
    test('rejects malformed context with AIInvalidRequestFailure', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final repository = _ScriptedAIRepository([]);
      final dispatcher = AIRequestDispatcher(
        sendMessageUseCase: SendConversationMessageUseCase(
          repository: repository,
          conversationRepository: conversationRepository,
          cancellationRegistry: InMemoryCancellationRegistry(),
        ),
        selectProvider: (_) => AIProviderId.openAI,
      );

      final events = await dispatcher
          .dispatch(
            _requestFor(
              conversation.id,
              context: {'system': 'not a map'}, // malformed -- should be a Map
            ),
            auth: const AIAuthContext(isAuthenticated: true, userId: 'user1'),
          )
          .toList();

      expect(
        (events.single as AIStreamEventError).failure,
        isA<AIInvalidRequestFailure>(),
      );
    });
  });

  group('AIRequestDispatcher -- happy path', () {
    test('translates context and delegates to the usecase with the selected provider', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final repository = _ScriptedAIRepository([
        AIStreamEventDone(
          response: AIResponse(
            id: 'r1',
            conversationId: conversation.id,
            content: 'javob',
            providerId: AIProviderId.gemini,
            modelVersion: 'fake-v1',
            completedAt: DateTime(2026, 1, 1),
          ),
        ),
      ]);
      final dispatcher = AIRequestDispatcher(
        sendMessageUseCase: SendConversationMessageUseCase(
          repository: repository,
          conversationRepository: conversationRepository,
          cancellationRegistry: InMemoryCancellationRegistry(),
        ),
        selectProvider: (_) => AIProviderId.gemini,
      );

      final events = await dispatcher
          .dispatch(
            _requestFor(
              conversation.id,
              context: {
                'system': {'locale': 'uz'},
              },
            ),
            auth: const AIAuthContext(isAuthenticated: true, userId: 'user1'),
          )
          .toList();

      expect(events.single, isA<AIStreamEventDone>());
      expect(repository.capturedProviderId, AIProviderId.gemini);
      expect(repository.capturedContext!.sectionFor('system'), {'locale': 'uz'});
    });
  });
}
