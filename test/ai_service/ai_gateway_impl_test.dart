import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_cancellation_registry.dart';
import '../../ai_service/data/session/in_memory_conversation_repository.dart';
import '../../ai_service/domain/entities/ai_cancellation_token.dart';
import '../../ai_service/domain/entities/ai_context.dart';
import '../../ai_service/domain/entities/ai_conversation.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';
import '../../ai_service/domain/entities/ai_response.dart';
import '../../ai_service/domain/entities/ai_stream_event.dart';
import '../../ai_service/domain/repositories/ai_repository.dart';
import '../../ai_service/domain/usecases/send_conversation_message_usecase.dart';
import '../../ai_service/gateway/ai_gateway_impl.dart';
import '../../ai_service/gateway/auth/ai_auth_context.dart';
import '../../ai_service/gateway/dispatch/ai_request_dispatcher.dart';
import '../../ai_service/protocol/ai_protocol_error.dart';
import '../../ai_service/protocol/ai_protocol_stream_event.dart';
import '../../ai_service/protocol/ai_request_envelope.dart';

class _ScriptedAIRepository implements AIRepository {
  _ScriptedAIRepository(this.events);

  final List<AIStreamEvent> events;

  @override
  Stream<AIStreamEvent> sendMessage({
    required AIConversation conversation,
    required AIContext context,
    required AIProviderId providerId,
    AICancellationToken? cancellationToken,
  }) async* {
    for (final event in events) {
      yield event;
    }
  }
}

void main() {
  group('AIGatewayImpl', () {
    test('short-circuits to unauthenticated without calling the dispatcher', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final gateway = AIGatewayImpl(
        requestDispatcher: AIRequestDispatcher(
          sendMessageUseCase: SendConversationMessageUseCase(
            repository: _ScriptedAIRepository([]),
            conversationRepository: conversationRepository,
            cancellationRegistry: InMemoryCancellationRegistry(),
          ),
          selectProvider: (_) => AIProviderId.openAI,
        ),
      );

      final events = await gateway
          .handle(
            request: AIRequestEnvelope(
              requestId: 'req1',
              conversationId: conversation.id,
              userId: 'user1',
              message: 'hi',
              requestedAt: DateTime(2026, 1, 1),
            ),
            auth: AIAuthContext.unauthenticated,
          )
          .toList();

      expect(events.single, isA<AIProtocolStreamEventFailed>());
      expect(
        (events.single as AIProtocolStreamEventFailed).error.code,
        AIProtocolErrorCode.unauthenticated,
      );
    });

    test('an authenticated, valid request flows through to a completed response', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final gateway = AIGatewayImpl(
        requestDispatcher: AIRequestDispatcher(
          sendMessageUseCase: SendConversationMessageUseCase(
            repository: _ScriptedAIRepository([
              AIStreamEventDone(
                response: AIResponse(
                  id: 'r1',
                  conversationId: conversation.id,
                  content: 'javob',
                  providerId: AIProviderId.openAI,
                  modelVersion: 'fake-v1',
                  completedAt: DateTime(2026, 1, 1),
                ),
              ),
            ]),
            conversationRepository: conversationRepository,
            cancellationRegistry: InMemoryCancellationRegistry(),
          ),
          selectProvider: (_) => AIProviderId.openAI,
        ),
      );

      final events = await gateway
          .handle(
            request: AIRequestEnvelope(
              requestId: 'req1',
              conversationId: conversation.id,
              userId: 'user1',
              message: 'hi',
              requestedAt: DateTime(2026, 1, 1),
            ),
            auth: const AIAuthContext(isAuthenticated: true, userId: 'user1'),
          )
          .toList();

      expect(events.first, isA<AIProtocolStreamEventStarted>());
      expect(events.last, isA<AIProtocolStreamEventCompleted>());
    });
  });
}
