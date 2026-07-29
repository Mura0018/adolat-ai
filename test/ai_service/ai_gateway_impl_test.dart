import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_cancellation_registry.dart';
import '../../ai_service/data/session/in_memory_conversation_repository.dart';
import '../../ai_service/domain/entities/ai_cancellation_token.dart';
import '../../ai_service/domain/entities/ai_context.dart';
import '../../ai_service/domain/entities/ai_conversation.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';
import '../../ai_service/domain/entities/ai_response.dart';
import '../../ai_service/domain/entities/ai_stream_event.dart';
import '../../ai_service/domain/quota/ai_usage_quota.dart';
import '../../ai_service/domain/repositories/ai_repository.dart';
import '../../ai_service/domain/usecases/send_conversation_message_usecase.dart';
import '../../ai_service/gateway/ai_gateway_impl.dart';
import '../../ai_service/gateway/auth/ai_auth_context.dart';
import '../../ai_service/gateway/dispatch/ai_request_dispatcher.dart';
import '../../ai_service/gateway/endpoint/ai_backend_endpoint.dart';
import '../../ai_service/gateway/ratelimit/ai_rate_limiter.dart';
import '../../ai_service/protocol/ai_protocol_error.dart';
import '../../ai_service/protocol/ai_protocol_stream_event.dart';
import '../../ai_service/protocol/ai_rate_limit_contract.dart';
import '../../ai_service/protocol/ai_request_envelope.dart';

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

class _FixedRateLimiter implements AIRateLimiter {
  _FixedRateLimiter(this.decision);

  final AIRateLimitDecision decision;

  @override
  Future<AIRateLimitDecision> checkAndConsume({
    required String userId,
    required AIBackendEndpointId endpoint,
  }) async => decision;
}

class _FixedQuotaStore implements AIUsageQuotaStore {
  _FixedQuotaStore(this.state);

  final AIUsageQuotaState state;
  final List<String> recordedUserIds = [];

  @override
  Future<AIUsageQuotaState> getState(String userId) async => state;

  @override
  Future<void> recordUsage({required String userId, required DateTime at}) async {
    recordedUserIds.add(userId);
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

    test('short-circuits to unauthenticated when authenticated but userId is null', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final repository = _ScriptedAIRepository([]);
      final gateway = AIGatewayImpl(
        requestDispatcher: AIRequestDispatcher(
          sendMessageUseCase: SendConversationMessageUseCase(
            repository: repository,
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
            auth: const AIAuthContext(isAuthenticated: true),
          )
          .toList();

      expect(
        (events.single as AIProtocolStreamEventFailed).error.code,
        AIProtocolErrorCode.unauthenticated,
      );
      expect(repository.wasCalled, isFalse);
    });

    test('rejects with rateLimited when the rate limiter denies, without calling the dispatcher', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final repository = _ScriptedAIRepository([]);
      final gateway = AIGatewayImpl(
        requestDispatcher: AIRequestDispatcher(
          sendMessageUseCase: SendConversationMessageUseCase(
            repository: repository,
            conversationRepository: conversationRepository,
            cancellationRegistry: InMemoryCancellationRegistry(),
          ),
          selectProvider: (_) => AIProviderId.openAI,
        ),
        rateLimiter: _FixedRateLimiter(
          AIRateLimitDecision(
            allowed: false,
            status: AIRateLimitStatus(
              limit: 5,
              remaining: 0,
              resetAt: DateTime.now().add(const Duration(minutes: 1)),
            ),
          ),
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

      expect(events.single, isA<AIProtocolStreamEventFailed>());
      expect(
        (events.single as AIProtocolStreamEventFailed).error.code,
        AIProtocolErrorCode.rateLimited,
      );
      expect(repository.wasCalled, isFalse);
    });

    test('proceeds normally when the rate limiter allows the request', () async {
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
        rateLimiter: _FixedRateLimiter(
          AIRateLimitDecision(
            allowed: true,
            status: AIRateLimitStatus(
              limit: 5,
              remaining: 4,
              resetAt: DateTime.now().add(const Duration(minutes: 1)),
            ),
          ),
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

      expect(events.last, isA<AIProtocolStreamEventCompleted>());
    });

    test(
      'rejects with quotaExceeded when the quota store denies, without calling the dispatcher or recording usage',
      () async {
        final conversationRepository = InMemoryConversationRepository();
        final conversation = conversationRepository.create();
        final repository = _ScriptedAIRepository([]);
        final quotaStore = _FixedQuotaStore(
          AIUsageQuotaState(usedInWindow: 5, windowStartedAt: DateTime.now()),
        );
        final gateway = AIGatewayImpl(
          requestDispatcher: AIRequestDispatcher(
            sendMessageUseCase: SendConversationMessageUseCase(
              repository: repository,
              conversationRepository: conversationRepository,
              cancellationRegistry: InMemoryCancellationRegistry(),
            ),
            selectProvider: (_) => AIProviderId.openAI,
          ),
          quotaStore: quotaStore,
          quotaPolicy: AIUsageQuotaPolicy(maxRequestsPerWindow: 5, window: const Duration(days: 1)),
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

        expect(events.single, isA<AIProtocolStreamEventFailed>());
        expect(
          (events.single as AIProtocolStreamEventFailed).error.code,
          AIProtocolErrorCode.quotaExceeded,
        );
        expect(repository.wasCalled, isFalse);
        expect(quotaStore.recordedUserIds, isEmpty);
      },
    );

    test('records usage and proceeds when the quota store allows the request', () async {
      final conversationRepository = InMemoryConversationRepository();
      final conversation = conversationRepository.create();
      final quotaStore = _FixedQuotaStore(
        AIUsageQuotaState(usedInWindow: 0, windowStartedAt: DateTime.now()),
      );
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
        quotaStore: quotaStore,
        quotaPolicy: AIUsageQuotaPolicy(maxRequestsPerWindow: 5, window: const Duration(days: 1)),
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

      expect(events.last, isA<AIProtocolStreamEventCompleted>());
      expect(quotaStore.recordedUserIds, ['user1']);
    });
  });
}
