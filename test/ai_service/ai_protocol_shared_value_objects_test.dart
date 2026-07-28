import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/protocol/ai_attachment_metadata.dart';
import '../../ai_service/protocol/ai_protocol_version.dart';
import '../../ai_service/protocol/ai_token_usage.dart';

void main() {
  group('AIProtocolVersion', () {
    test('current defaults to v1', () {
      expect(AIProtocolVersion.current.value, 1);
      expect(AIProtocolVersion.current.toString(), 'v1');
    });

    test('round-trips through JSON', () {
      const version = AIProtocolVersion(2);

      final decoded = AIProtocolVersion.fromJson(version.toJson());

      expect(decoded, version);
    });

    test('rejects a value below 1', () {
      expect(() => AIProtocolVersion(0), throwsA(isA<AssertionError>()));
    });
  });

  group('AITokenUsage', () {
    test('unknown constant has all-null fields', () {
      expect(AITokenUsage.unknown.promptTokens, isNull);
      expect(AITokenUsage.unknown.completionTokens, isNull);
      expect(AITokenUsage.unknown.totalTokens, isNull);
    });

    test('round-trips through JSON', () {
      const usage = AITokenUsage(promptTokens: 10, completionTokens: 20, totalTokens: 30);

      final decoded = AITokenUsage.fromJson(usage.toJson());

      expect(decoded, usage);
    });

    test('round-trips an all-null instance through JSON', () {
      const usage = AITokenUsage();

      final decoded = AITokenUsage.fromJson(usage.toJson());

      expect(decoded, usage);
    });
  });

  group('AIAttachmentMetadata', () {
    test('round-trips through JSON, including a null storageRef', () {
      const attachment = AIAttachmentMetadata(
        id: 'a1',
        fileName: 'ariza.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 1024,
      );

      final decoded = AIAttachmentMetadata.fromJson(attachment.toJson());

      expect(decoded, attachment);
      expect(decoded.storageRef, isNull);
    });

    test('round-trips a populated storageRef', () {
      const attachment = AIAttachmentMetadata(
        id: 'a1',
        fileName: 'ariza.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 1024,
        storageRef: 'attachments/a1.pdf',
      );

      final decoded = AIAttachmentMetadata.fromJson(attachment.toJson());

      expect(decoded, attachment);
    });
  });
}
