import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/protocol/ai_protocol_error.dart';
import '../../ai_service/protocol/ai_protocol_status.dart';
import '../../ai_service/protocol/ai_response_envelope.dart';
import '../../ai_service/protocol/ai_token_usage.dart';

AIResponseEnvelope _completed({String? assistantMessage = 'javob matni'}) {
  return AIResponseEnvelope(
    responseId: 'resp1',
    requestId: 'req1',
    conversationId: 'conv1',
    assistantMessage: assistantMessage,
    status: AIProtocolStatus.completed,
    receivedAt: DateTime(2026, 1, 1, 12),
    respondedAt: DateTime(2026, 1, 1, 12, 0, 2),
  );
}

void main() {
  group('AIResponseEnvelope invariants', () {
    test('a failed status requires a non-null error', () {
      expect(
        () => AIResponseEnvelope(
          responseId: 'resp1',
          requestId: 'req1',
          conversationId: 'conv1',
          status: AIProtocolStatus.failed,
          receivedAt: DateTime(2026, 1, 1),
          respondedAt: DateTime(2026, 1, 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a failed status with an error is accepted', () {
      expect(
        () => AIResponseEnvelope(
          responseId: 'resp1',
          requestId: 'req1',
          conversationId: 'conv1',
          status: AIProtocolStatus.failed,
          error: const AIProtocolError(
            code: AIProtocolErrorCode.network,
            message: 'x',
            retryable: true,
          ),
          receivedAt: DateTime(2026, 1, 1),
          respondedAt: DateTime(2026, 1, 1),
        ),
        returnsNormally,
      );
    });

    test('a non-completed status rejects a non-null assistantMessage', () {
      expect(
        () => AIResponseEnvelope(
          responseId: 'resp1',
          requestId: 'req1',
          conversationId: 'conv1',
          assistantMessage: 'partial',
          status: AIProtocolStatus.cancelled,
          receivedAt: DateTime(2026, 1, 1),
          respondedAt: DateTime(2026, 1, 1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('a completed status is accepted without an assistantMessage', () {
      expect(() => _completed(assistantMessage: null), returnsNormally);
    });
  });

  group('AIResponseEnvelope JSON round-trip', () {
    test('round-trips a completed response', () {
      final response = _completed();

      final decoded = AIResponseEnvelope.fromJson(response.toJson());

      expect(decoded, response);
    });

    test('round-trips a response with token usage and latency', () {
      final response = AIResponseEnvelope(
        responseId: 'resp1',
        requestId: 'req1',
        conversationId: 'conv1',
        assistantMessage: 'javob',
        status: AIProtocolStatus.completed,
        tokenUsage: const AITokenUsage(
          promptTokens: 5,
          completionTokens: 10,
          totalTokens: 15,
        ),
        latencyMs: 842,
        receivedAt: DateTime(2026, 1, 1),
        respondedAt: DateTime(2026, 1, 1, 0, 0, 1),
      );

      final decoded = AIResponseEnvelope.fromJson(response.toJson());

      expect(decoded, response);
    });

    test('round-trips a failed response with its error', () {
      final response = AIResponseEnvelope(
        responseId: 'resp1',
        requestId: 'req1',
        conversationId: 'conv1',
        status: AIProtocolStatus.failed,
        error: const AIProtocolError(
          code: AIProtocolErrorCode.providerError,
          message: 'provider down',
          retryable: false,
        ),
        receivedAt: DateTime(2026, 1, 1),
        respondedAt: DateTime(2026, 1, 1),
      );

      final decoded = AIResponseEnvelope.fromJson(response.toJson());

      expect(decoded, response);
      expect(decoded.error!.code, AIProtocolErrorCode.providerError);
    });
  });
}
