import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/entities/ai_failure.dart';
import '../../ai_service/domain/entities/ai_response.dart';
import '../../ai_service/domain/entities/ai_stream_event.dart';
import '../../ai_service/domain/entities/ai_provider_id.dart';
import '../../ai_service/domain/retry/ai_retry_executor.dart';
import '../../ai_service/domain/retry/ai_retry_policy.dart';

AIResponse _response() => AIResponse(
  id: 'r1',
  conversationId: 'c1',
  content: 'ok',
  providerId: AIProviderId.openAI,
  modelVersion: 'fake-v1',
  completedAt: DateTime(2026, 1, 1),
);

void main() {
  group('AIRetryExecutor', () {
    test('passes events through untouched when the operation succeeds first try', () async {
      const executor = AIRetryExecutor(AIRetryPolicy());
      var calls = 0;

      final events = await executor.run(() async* {
        calls += 1;
        yield AIStreamEventDone(response: _response());
      }).toList();

      expect(calls, 1);
      expect(events.single, isA<AIStreamEventDone>());
    });

    test('retries a retryable failure that produced no chunks', () async {
      const executor = AIRetryExecutor(
        AIRetryPolicy(maxAttempts: 3, initialDelay: Duration.zero),
      );
      var calls = 0;

      final events = await executor.run(() async* {
        calls += 1;
        if (calls == 1) {
          yield const AIStreamEventError(failure: AINetworkFailure());
        } else {
          yield AIStreamEventDone(response: _response());
        }
      }).toList();

      expect(calls, 2);
      expect(events, hasLength(1));
      expect(events.single, isA<AIStreamEventDone>());
    });

    test('yields the terminal error once retries are exhausted', () async {
      const executor = AIRetryExecutor(
        AIRetryPolicy(maxAttempts: 2, initialDelay: Duration.zero),
      );
      var calls = 0;

      final events = await executor.run(() async* {
        calls += 1;
        yield const AIStreamEventError(failure: AINetworkFailure());
      }).toList();

      expect(calls, 2); // 1 original + 1 retry, then gives up
      expect(events.single, isA<AIStreamEventError>());
    });

    test('does not retry once any chunk has already been emitted', () async {
      const executor = AIRetryExecutor(
        AIRetryPolicy(maxAttempts: 3, initialDelay: Duration.zero),
      );
      var calls = 0;

      final events = await executor.run(() async* {
        calls += 1;
        yield const AIStreamEventChunk(deltaContent: 'partial');
        yield const AIStreamEventError(failure: AINetworkFailure());
      }).toList();

      expect(calls, 1); // no retry despite a retryable failure
      expect(events, hasLength(2));
      expect(events[0], isA<AIStreamEventChunk>());
      expect(events[1], isA<AIStreamEventError>());
    });

    test('does not retry a non-retryable failure', () async {
      const executor = AIRetryExecutor(
        AIRetryPolicy(maxAttempts: 3, initialDelay: Duration.zero),
      );
      var calls = 0;

      final events = await executor.run(() async* {
        calls += 1;
        yield const AIStreamEventError(
          failure: AISafetyRejectionFailure(reason: 'blocked'),
        );
      }).toList();

      expect(calls, 1);
      expect(events.single, isA<AIStreamEventError>());
    });

    test('passes a cancelled event through without retrying', () async {
      const executor = AIRetryExecutor(
        AIRetryPolicy(maxAttempts: 3, initialDelay: Duration.zero),
      );
      var calls = 0;

      final events = await executor.run(() async* {
        calls += 1;
        yield const AIStreamEventCancelled();
      }).toList();

      expect(calls, 1);
      expect(events.single, isA<AIStreamEventCancelled>());
    });
  });
}
