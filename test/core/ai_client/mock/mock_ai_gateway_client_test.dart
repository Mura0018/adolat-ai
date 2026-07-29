import 'package:adolat_ai/core/ai_client/mock/mock_ai_gateway_client.dart';
import 'package:adolat_ai/core/ai_client/protocol/ai_protocol_error.dart';
import 'package:adolat_ai/core/ai_client/protocol/ai_protocol_stream_event.dart';
import 'package:adolat_ai/core/ai_client/protocol/ai_request_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final request = AiRequestEnvelope(
    requestId: 'r1',
    conversationId: 'c1',
    userId: 'u1',
    message: 'Savol',
    requestedAt: DateTime.utc(2026, 1, 1),
  );

  group('MockAiGatewayClient', () {
    test('always yields started first', () async {
      const client = MockAiGatewayClient(chunkDelay: Duration.zero);

      final first = await client.sendMessage(request).first;

      expect(first, isA<AiProtocolStreamEventStarted>());
    });

    test('reassembling chunk deltaContent reproduces the full response text', () async {
      const client = MockAiGatewayClient(
        responseText: 'bir ikki uch to\'rt besh',
        wordsPerChunk: 2,
      );

      final events = await client.sendMessage(request).toList();
      final chunks = events.whereType<AiProtocolStreamEventChunk>().toList();

      expect(chunks.map((c) => c.sequence).toList(), [0, 1, 2]);
      expect(chunks.map((c) => c.deltaContent).join(), 'bir ikki uch to\'rt besh');
    });

    test('completes with the full response text as assistantMessage', () async {
      const client = MockAiGatewayClient(responseText: 'yakuniy javob');

      final events = await client.sendMessage(request).toList();
      final completed = events.whereType<AiProtocolStreamEventCompleted>().single;

      expect(completed.response.assistantMessage, 'yakuniy javob');
      expect(completed.response.conversationId, 'c1');
    });

    test('failWith short-circuits to a failed event without any chunks', () async {
      const error = AiProtocolError(
        code: AiProtocolErrorCode.providerError,
        message: 'test xatoligi',
        retryable: false,
      );
      const client = MockAiGatewayClient(failWith: error);

      final events = await client.sendMessage(request).toList();

      expect(events.whereType<AiProtocolStreamEventChunk>(), isEmpty);
      final failed = events.whereType<AiProtocolStreamEventFailed>().single;
      expect(failed.error, error);
    });
  });
}
