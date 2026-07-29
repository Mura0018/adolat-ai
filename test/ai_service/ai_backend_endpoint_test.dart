import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/gateway/endpoint/ai_backend_endpoint.dart';

void main() {
  group('AIBackendEndpointRegistry', () {
    test('describes every AIBackendEndpointId with a matching id', () {
      for (final id in AIBackendEndpointId.values) {
        final descriptor = AIBackendEndpointRegistry.describe(id);
        expect(descriptor.id, id);
      }
    });

    test('all yields the same number of descriptors as AIBackendEndpointId.values', () {
      expect(AIBackendEndpointRegistry.all.length, AIBackendEndpointId.values.length);
    });

    test('negotiateProtocolVersion is the only endpoint that does not require authentication', () {
      final unauthenticated = AIBackendEndpointRegistry.all.where(
        (d) => !d.requiresAuthentication,
      );

      expect(unauthenticated.map((d) => d.id), [AIBackendEndpointId.negotiateProtocolVersion]);
    });

    test('sendMessage and requestAttachmentUpload are rate limited', () {
      expect(
        AIBackendEndpointRegistry.describe(AIBackendEndpointId.sendMessage).isRateLimited,
        isTrue,
      );
      expect(
        AIBackendEndpointRegistry.describe(
          AIBackendEndpointId.requestAttachmentUpload,
        ).isRateLimited,
        isTrue,
      );
    });

    test('cancelConversation and closeConversation are idempotent', () {
      expect(
        AIBackendEndpointRegistry.describe(AIBackendEndpointId.cancelConversation).isIdempotent,
        isTrue,
      );
      expect(
        AIBackendEndpointRegistry.describe(AIBackendEndpointId.closeConversation).isIdempotent,
        isTrue,
      );
    });
  });
}
