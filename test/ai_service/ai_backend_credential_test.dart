import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/protocol/ai_backend_credential.dart';

void main() {
  group('AIBackendCredential', () {
    test('round-trips through JSON, including expiresAt', () {
      const credential = AIBackendCredential(
        type: AIBackendCredentialType.supabaseAccessToken,
        token: 'jwt.token.value',
      );
      final withExpiry = AIBackendCredential(
        type: credential.type,
        token: credential.token,
        expiresAt: DateTime(2026, 1, 1, 12),
      );

      final decoded = AIBackendCredential.fromJson(withExpiry.toJson());

      expect(decoded, withExpiry);
    });

    test('round-trips without expiresAt', () {
      const credential = AIBackendCredential(
        type: AIBackendCredentialType.supabaseAccessToken,
        token: 'jwt.token.value',
      );

      final decoded = AIBackendCredential.fromJson(credential.toJson());

      expect(decoded, credential);
      expect(decoded.expiresAt, isNull);
    });

    test('toString never leaks the raw token', () {
      const credential = AIBackendCredential(
        type: AIBackendCredentialType.supabaseAccessToken,
        token: 'super-secret-value',
      );

      expect(credential.toString().contains('super-secret-value'), isFalse);
    });

    test('isExpiredAt is false when now is before expiresAt', () {
      final credential = AIBackendCredential(
        type: AIBackendCredentialType.supabaseAccessToken,
        token: 'x',
        expiresAt: DateTime(2026, 1, 1, 12),
      );

      expect(credential.isExpiredAt(DateTime(2026, 1, 1, 11)), isFalse);
    });

    test('isExpiredAt is true when now is at or after expiresAt', () {
      final credential = AIBackendCredential(
        type: AIBackendCredentialType.supabaseAccessToken,
        token: 'x',
        expiresAt: DateTime(2026, 1, 1, 12),
      );

      expect(credential.isExpiredAt(DateTime(2026, 1, 1, 12)), isTrue);
      expect(credential.isExpiredAt(DateTime(2026, 1, 1, 13)), isTrue);
    });

    test('isExpiredAt is false when expiresAt is unknown (null)', () {
      const credential = AIBackendCredential(
        type: AIBackendCredentialType.supabaseAccessToken,
        token: 'x',
      );

      expect(credential.isExpiredAt(DateTime(2099, 1, 1)), isFalse);
    });
  });
}
