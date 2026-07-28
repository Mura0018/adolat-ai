import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/protocol/ai_protocol_error.dart';
import '../../ai_service/protocol/ai_protocol_status.dart';
import '../../ai_service/protocol/ai_protocol_stream_event.dart';
import '../../ai_service/protocol/ai_response_envelope.dart';

void main() {
  group('AIProtocolStreamEvent JSON round-trip', () {
    test('started', () {
      const event = AIProtocolStreamEventStarted(
        requestId: 'req1',
        conversationId: 'conv1',
      );

      final decoded = AIProtocolStreamEvent.fromJson(event.toJson());

      expect(decoded, event);
      expect(decoded, isA<AIProtocolStreamEventStarted>());
    });

    test('chunk', () {
      const event = AIProtocolStreamEventChunk(
        requestId: 'req1',
        conversationId: 'conv1',
        sequence: 3,
        deltaContent: 'salom',
      );

      final decoded = AIProtocolStreamEvent.fromJson(event.toJson());

      expect(decoded, event);
    });

    test('completed', () {
      final event = AIProtocolStreamEventCompleted(
        requestId: 'req1',
        response: AIResponseEnvelope(
          responseId: 'resp1',
          requestId: 'req1',
          conversationId: 'conv1',
          assistantMessage: 'javob',
          status: AIProtocolStatus.completed,
          receivedAt: DateTime(2026, 1, 1),
          respondedAt: DateTime(2026, 1, 1, 0, 0, 1),
        ),
      );

      final decoded = AIProtocolStreamEvent.fromJson(event.toJson());

      expect(decoded, event);
      expect(decoded.conversationId, 'conv1'); // derived from response
    });

    test('cancelled', () {
      const event = AIProtocolStreamEventCancelled(
        requestId: 'req1',
        conversationId: 'conv1',
      );

      final decoded = AIProtocolStreamEvent.fromJson(event.toJson());

      expect(decoded, event);
    });

    test('failed', () {
      const event = AIProtocolStreamEventFailed(
        requestId: 'req1',
        conversationId: 'conv1',
        error: AIProtocolError(
          code: AIProtocolErrorCode.timeout,
          message: 'timed out',
          retryable: true,
        ),
      );

      final decoded = AIProtocolStreamEvent.fromJson(event.toJson());

      expect(decoded, event);
    });

    test('an unknown type throws FormatException', () {
      expect(
        () => AIProtocolStreamEvent.fromJson({'type': 'bogus'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('AIProtocolStreamEvent.toJson discriminator', () {
    test('each variant writes its own type tag', () {
      const started = AIProtocolStreamEventStarted(requestId: 'r', conversationId: 'c');
      const chunk = AIProtocolStreamEventChunk(
        requestId: 'r',
        conversationId: 'c',
        sequence: 0,
        deltaContent: 'x',
      );
      const cancelled = AIProtocolStreamEventCancelled(requestId: 'r', conversationId: 'c');
      const failed = AIProtocolStreamEventFailed(
        requestId: 'r',
        conversationId: 'c',
        error: AIProtocolError(
          code: AIProtocolErrorCode.unknown,
          message: 'x',
          retryable: false,
        ),
      );

      expect(started.toJson()['type'], 'started');
      expect(chunk.toJson()['type'], 'chunk');
      expect(cancelled.toJson()['type'], 'cancelled');
      expect(failed.toJson()['type'], 'failed');
    });
  });
}
