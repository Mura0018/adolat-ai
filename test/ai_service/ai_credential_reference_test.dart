import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/config/domain/ai_credential_reference.dart';

void main() {
  group('AICredentialReference', () {
    test('round-trips through JSON', () {
      const ref = AICredentialReference(
        storeKind: AICredentialStoreKind.supabaseVault,
        referenceKey: 'openai-api-key',
      );

      final decoded = AICredentialReference.fromJson(ref.toJson());

      expect(decoded, ref);
    });

    test('every store kind round-trips by name', () {
      for (final kind in AICredentialStoreKind.values) {
        final ref = AICredentialReference(storeKind: kind, referenceKey: 'x');

        final decoded = AICredentialReference.fromJson(ref.toJson());

        expect(decoded.storeKind, kind);
      }
    });

    test('never carries the actual secret value -- only a reference key', () {
      // Compile-time guarantee: there is no `secretValue`/`apiKey` field
      // on this class, only `referenceKey`. This test exists to make
      // that architectural decision explicit and searchable.
      const ref = AICredentialReference(
        storeKind: AICredentialStoreKind.environmentVariable,
        referenceKey: 'OPENAI_API_KEY',
      );
      expect(ref.toJson().keys, ['storeKind', 'referenceKey']);
    });
  });
}
