import 'package:adolat_ai/core/ai_client/protocol/ai_protocol_error.dart';
import 'package:adolat_ai/core/ai_client/protocol/ai_protocol_status.dart';
import 'package:adolat_ai/core/ai_client/protocol/ai_protocol_stream_event.dart';
import 'package:adolat_ai/core/ai_client/protocol/ai_response_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiProtocolStreamEvent JSON round-trip', () {
    test('started', () {
      const event = AiProtocolStreamEventStarted(requestId: 'r1', conversationId: 'c1');
      final restored = AiProtocolStreamEvent.fromJson(event.toJson());
      expect(restored, event);
    });

    test('chunk', () {
      const event = AiProtocolStreamEventChunk(
        requestId: 'r1',
        conversationId: 'c1',
        sequence: 2,
        deltaContent: 'salom',
      );
      final restored = AiProtocolStreamEvent.fromJson(event.toJson());
      expect(restored, event);
    });

    test('completed', () {
      final event = AiProtocolStreamEventCompleted(
        requestId: 'r1',
        response: AiResponseEnvelope(
          responseId: 'resp1',
          requestId: 'r1',
          conversationId: 'c1',
          assistantMessage: 'javob',
          status: AiProtocolStatus.completed,
          receivedAt: DateTime.utc(2026, 1, 1),
          respondedAt: DateTime.utc(2026, 1, 1, 0, 0, 2),
        ),
      );
      final restored = AiProtocolStreamEvent.fromJson(event.toJson());
      expect(restored, event);
      expect(restored.conversationId, 'c1');
    });

    test('cancelled', () {
      const event = AiProtocolStreamEventCancelled(requestId: 'r1', conversationId: 'c1');
      final restored = AiProtocolStreamEvent.fromJson(event.toJson());
      expect(restored, event);
    });

    test('failed', () {
      const event = AiProtocolStreamEventFailed(
        requestId: 'r1',
        conversationId: 'c1',
        error: AiProtocolError(
          code: AiProtocolErrorCode.network,
          message: 'tarmoq xatosi',
          retryable: true,
        ),
      );
      final restored = AiProtocolStreamEvent.fromJson(event.toJson());
      expect(restored, event);
    });

    test('unknown type throws FormatException', () {
      expect(
        () => AiProtocolStreamEvent.fromJson({'type': 'not_a_real_type'}),
        throwsFormatException,
      );
    });
  });
}
