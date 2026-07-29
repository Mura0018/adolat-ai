import 'package:adolat_ai/core/ai_client/protocol/ai_request_envelope.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiRequestEnvelope', () {
    test('round-trips through JSON, including context', () {
      final envelope = AiRequestEnvelope(
        requestId: 'r1',
        conversationId: 'c1',
        userId: 'u1',
        message: 'Salom',
        context: {
          'system': {'locale': 'uz'},
          'user': {'role': 'citizen'},
        },
        requestedAt: DateTime.utc(2026, 1, 1),
      );

      final restored = AiRequestEnvelope.fromJson(envelope.toJson());

      expect(restored, envelope);
    });

    test('does not have a providerId field', () {
      final envelope = AiRequestEnvelope(
        requestId: 'r1',
        conversationId: 'c1',
        userId: 'u1',
        message: 'Salom',
        requestedAt: DateTime.utc(2026, 1, 1),
      );

      expect(envelope.toJson().containsKey('providerId'), isFalse);
    });
  });
}
