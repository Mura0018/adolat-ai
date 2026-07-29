import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/protocol/ai_attachment_upload_contract.dart';

void main() {
  group('AIAttachmentUploadRequest', () {
    test('round-trips through JSON', () {
      const request = AIAttachmentUploadRequest(
        fileName: 'ariza.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 2048,
      );

      final decoded = AIAttachmentUploadRequest.fromJson(request.toJson());

      expect(decoded, request);
    });
  });

  group('AIAttachmentUploadTicket', () {
    test('round-trips through JSON', () {
      final ticket = AIAttachmentUploadTicket(
        attachmentId: 'att1',
        uploadRef: 'opaque-ref',
        expiresAt: DateTime(2026, 1, 1, 12),
      );

      final decoded = AIAttachmentUploadTicket.fromJson(ticket.toJson());

      expect(decoded, ticket);
    });
  });

  group('AIAttachmentUploadConstraints', () {
    const constraints = AIAttachmentUploadConstraints(
      maxSizeBytes: 1024,
      allowedMimeTypes: {'application/pdf', 'image/png'},
    );

    test('allows a request within size and mime type constraints', () {
      const request = AIAttachmentUploadRequest(
        fileName: 'ariza.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 512,
      );

      expect(constraints.allows(request), isTrue);
    });

    test('rejects a request that exceeds the max size', () {
      const request = AIAttachmentUploadRequest(
        fileName: 'ariza.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 2048,
      );

      expect(constraints.allows(request), isFalse);
    });

    test('rejects a request with a disallowed mime type', () {
      const request = AIAttachmentUploadRequest(
        fileName: 'virus.exe',
        mimeType: 'application/x-msdownload',
        sizeBytes: 100,
      );

      expect(constraints.allows(request), isFalse);
    });

    test('rejects a non-positive maxSizeBytes', () {
      expect(
        () => AIAttachmentUploadConstraints(maxSizeBytes: 0, allowedMimeTypes: const {}),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('finalizeAttachmentUpload', () {
    test('combines the ticket and request into final attachment metadata', () {
      const request = AIAttachmentUploadRequest(
        fileName: 'ariza.pdf',
        mimeType: 'application/pdf',
        sizeBytes: 2048,
      );
      final ticket = AIAttachmentUploadTicket(
        attachmentId: 'att1',
        uploadRef: 'opaque-ref',
        expiresAt: DateTime(2026, 1, 1, 12),
      );

      final metadata = finalizeAttachmentUpload(
        ticket: ticket,
        request: request,
        storageRef: 'storage/path/ariza.pdf',
      );

      expect(metadata.id, 'att1');
      expect(metadata.fileName, 'ariza.pdf');
      expect(metadata.mimeType, 'application/pdf');
      expect(metadata.sizeBytes, 2048);
      expect(metadata.storageRef, 'storage/path/ariza.pdf');
    });
  });
}
