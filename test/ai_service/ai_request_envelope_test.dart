import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/protocol/ai_attachment_metadata.dart';
import '../../ai_service/protocol/ai_protocol_version.dart';
import '../../ai_service/protocol/ai_request_envelope.dart';

AIRequestEnvelope _envelope({
  Map<String, dynamic> context = const {},
  List<AIAttachmentMetadata> attachments = const [],
}) {
  return AIRequestEnvelope(
    requestId: 'req1',
    conversationId: 'conv1',
    userId: 'user1',
    message: 'Nafaqa haqida savol',
    context: context,
    attachments: attachments,
    requestedAt: DateTime(2026, 1, 1, 12),
  );
}

void main() {
  group('AIRequestEnvelope', () {
    test('defaults to the current protocol version, empty context/attachments', () {
      final envelope = AIRequestEnvelope(
        requestId: 'req1',
        conversationId: 'conv1',
        userId: 'user1',
        message: 'hi',
        requestedAt: DateTime(2026, 1, 1),
      );

      expect(envelope.protocolVersion, AIProtocolVersion.current);
      expect(envelope.context, isEmpty);
      expect(envelope.attachments, isEmpty);
    });

    test('does not select a provider -- there is no providerId field', () {
      // Compile-time guarantee: AIRequestEnvelope has no providerId
      // constructor parameter. This test exists to make that
      // architectural decision explicit and searchable.
      final envelope = _envelope();
      expect(envelope, isNotNull);
    });

    test('round-trips through JSON, including context and attachments', () {
      final envelope = _envelope(
        context: {
          'system': {'locale': 'uz'},
        },
        attachments: const [
          AIAttachmentMetadata(
            id: 'a1',
            fileName: 'ariza.pdf',
            mimeType: 'application/pdf',
            sizeBytes: 2048,
          ),
        ],
      );

      final decoded = AIRequestEnvelope.fromJson(envelope.toJson());

      expect(decoded, envelope);
    });

    test('round-trips an envelope with no attachments and empty context', () {
      final envelope = _envelope();

      final decoded = AIRequestEnvelope.fromJson(envelope.toJson());

      expect(decoded, envelope);
    });
  });
}
