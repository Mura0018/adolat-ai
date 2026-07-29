import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/protocol/ai_protocol_version.dart';
import '../../ai_service/protocol/ai_version_negotiation_contract.dart';

void main() {
  group('AIVersionNegotiationRequest', () {
    test('round-trips through JSON', () {
      final request = AIVersionNegotiationRequest(
        clientSupportedVersions: const [AIProtocolVersion(1), AIProtocolVersion(2)],
      );

      final decoded = AIVersionNegotiationRequest.fromJson(request.toJson());

      expect(decoded, request);
    });

    test('rejects an empty clientSupportedVersions list', () {
      expect(
        () => AIVersionNegotiationRequest(clientSupportedVersions: const []),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('AIVersionNegotiationResult', () {
    test('negotiated requires a negotiatedVersion', () {
      expect(
        () => AIVersionNegotiationResult(status: AIVersionNegotiationStatus.negotiated),
        throwsA(isA<AssertionError>()),
      );
    });

    test('unsupported must not carry a negotiatedVersion', () {
      expect(
        () => AIVersionNegotiationResult(
          status: AIVersionNegotiationStatus.unsupported,
          negotiatedVersion: const AIProtocolVersion(1),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('round-trips through JSON when negotiated', () {
      const result = AIVersionNegotiationResult(
        status: AIVersionNegotiationStatus.negotiated,
        negotiatedVersion: AIProtocolVersion(1),
      );

      final decoded = AIVersionNegotiationResult.fromJson(result.toJson());

      expect(decoded, result);
    });

    test('round-trips through JSON when unsupported', () {
      const result = AIVersionNegotiationResult(status: AIVersionNegotiationStatus.unsupported);

      final decoded = AIVersionNegotiationResult.fromJson(result.toJson());

      expect(decoded, result);
    });
  });

  group('negotiateProtocolVersion', () {
    test('picks the highest mutually supported version', () {
      final request = AIVersionNegotiationRequest(
        clientSupportedVersions: const [AIProtocolVersion(1), AIProtocolVersion(2)],
      );

      final result = negotiateProtocolVersion(
        request: request,
        serverSupportedVersions: {const AIProtocolVersion(1), const AIProtocolVersion(2)},
      );

      expect(result.status, AIVersionNegotiationStatus.negotiated);
      expect(result.negotiatedVersion, const AIProtocolVersion(2));
    });

    test('returns unsupported when there is no overlap', () {
      final request = AIVersionNegotiationRequest(
        clientSupportedVersions: const [AIProtocolVersion(1)],
      );

      final result = negotiateProtocolVersion(
        request: request,
        serverSupportedVersions: {const AIProtocolVersion(2)},
      );

      expect(result.status, AIVersionNegotiationStatus.unsupported);
      expect(result.negotiatedVersion, isNull);
    });
  });
}
