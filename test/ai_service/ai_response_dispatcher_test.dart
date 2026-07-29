import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/entities/ai_failure.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';
import '../../ai_service/domain/entities/ai_response.dart';
import '../../ai_service/domain/entities/ai_stream_event.dart';
import '../../ai_service/gateway/dispatch/ai_response_dispatcher.dart';
import '../../ai_service/protocol/ai_protocol_error.dart';
import '../../ai_service/protocol/ai_protocol_stream_event.dart';
import '../../ai_service/protocol/ai_request_envelope.dart';

AIRequestEnvelope _request() {
  return AIRequestEnvelope(
    requestId: 'req1',
    conversationId: 'conv1',
    userId: 'user1',
    message: 'savol',
    requestedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('AIResponseDispatcher', () {
    test('always yields started first', () async {
      const dispatcher = AIResponseDispatcher();

      final events = await dispatcher
          .dispatch(request: _request(), receivedAt: DateTime(2026, 1, 1), events: const Stream.empty())
          .toList();

      expect(events.single, isA<AIProtocolStreamEventStarted>());
    });

    test('assigns increasing sequence numbers to chunks', () async {
      const dispatcher = AIResponseDispatcher();
      final internal = Stream<AIStreamEvent>.fromIterable([
        const AIStreamEventChunk(deltaContent: 'a'),
        const AIStreamEventChunk(deltaContent: 'b'),
        const AIStreamEventChunk(deltaContent: 'c'),
      ]);

      final events = await dispatcher
          .dispatch(request: _request(), receivedAt: DateTime(2026, 1, 1), events: internal)
          .toList();

      final chunks = events.whereType<AIProtocolStreamEventChunk>().toList();
      expect(chunks.map((c) => c.sequence), [0, 1, 2]);
      expect(chunks.map((c) => c.deltaContent), ['a', 'b', 'c']);
    });

    test('maps AIStreamEventDone to a completed response envelope', () async {
      const dispatcher = AIResponseDispatcher();
      final internal = Stream<AIStreamEvent>.fromIterable([
        AIStreamEventDone(
          response: AIResponse(
            id: 'r1',
            conversationId: 'conv1',
            content: 'javob matni',
            providerId: AIProviderId.openAI,
            modelVersion: 'fake-v1',
            completedAt: DateTime(2026, 1, 1, 0, 0, 5),
          ),
        ),
      ]);

      final events = await dispatcher
          .dispatch(
            request: _request(),
            receivedAt: DateTime(2026, 1, 1),
            events: internal,
          )
          .toList();

      final completed = events.whereType<AIProtocolStreamEventCompleted>().single;
      expect(completed.response.assistantMessage, 'javob matni');
      expect(completed.response.requestId, 'req1');
      expect(completed.response.respondedAt, DateTime(2026, 1, 1, 0, 0, 5));
    });

    test('maps AIStreamEventCancelled to cancelled', () async {
      const dispatcher = AIResponseDispatcher();
      final internal = Stream<AIStreamEvent>.fromIterable(const [AIStreamEventCancelled()]);

      final events = await dispatcher
          .dispatch(request: _request(), receivedAt: DateTime(2026, 1, 1), events: internal)
          .toList();

      expect(events.whereType<AIProtocolStreamEventCancelled>().length, 1);
    });

    test('every AIFailure variant maps to a distinct AIProtocolErrorCode with matching retryable', () async {
      const dispatcher = AIResponseDispatcher();
      final cases = <AIFailure, AIProtocolErrorCode>{
        const AINetworkFailure(): AIProtocolErrorCode.network,
        const AITimeoutFailure(): AIProtocolErrorCode.timeout,
        const AIRateLimitFailure(): AIProtocolErrorCode.rateLimited,
        const AIProviderFailure(message: 'x', providerId: AIProviderId.openAI):
            AIProtocolErrorCode.providerError,
        const AISafetyRejectionFailure(reason: 'x'): AIProtocolErrorCode.safetyRejected,
        const AIProviderNotConfiguredFailure(providerId: AIProviderId.openAI):
            AIProtocolErrorCode.providerNotConfigured,
        const AIConversationNotFoundFailure(conversationId: 'c1'):
            AIProtocolErrorCode.conversationNotFound,
        const AIConversationClosedFailure(conversationId: 'c1'):
            AIProtocolErrorCode.conversationClosed,
        const AIUnauthorizedFailure(): AIProtocolErrorCode.unauthorized,
        const AIInvalidRequestFailure(reason: 'x'): AIProtocolErrorCode.invalidRequest,
        const AIUnknownFailure(): AIProtocolErrorCode.unknown,
      };

      for (final entry in cases.entries) {
        final internal = Stream<AIStreamEvent>.fromIterable([
          AIStreamEventError(failure: entry.key),
        ]);

        final events = await dispatcher
            .dispatch(request: _request(), receivedAt: DateTime(2026, 1, 1), events: internal)
            .toList();

        final failed = events.whereType<AIProtocolStreamEventFailed>().single;
        expect(failed.error.code, entry.value, reason: '${entry.key} -> ${entry.value}');
        expect(failed.error.retryable, entry.key.isRetryable, reason: '${entry.key} retryable mismatch');
      }
    });
  });
}
