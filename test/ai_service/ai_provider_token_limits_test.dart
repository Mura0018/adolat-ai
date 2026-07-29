import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/config/domain/ai_provider_token_limits.dart';

void main() {
  group('AIProviderTokenLimits', () {
    test('round-trips through JSON', () {
      const limits = AIProviderTokenLimits(maxPromptTokens: 4000, maxCompletionTokens: 2000);

      final decoded = AIProviderTokenLimits.fromJson(limits.toJson());

      expect(decoded, limits);
    });

    test('maxTotalTokens sums prompt and completion limits', () {
      const limits = AIProviderTokenLimits(maxPromptTokens: 4000, maxCompletionTokens: 2000);

      expect(limits.maxTotalTokens, 6000);
    });

    test('rejects a non-positive maxPromptTokens', () {
      expect(
        () => AIProviderTokenLimits(maxPromptTokens: 0, maxCompletionTokens: 2000),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a non-positive maxCompletionTokens', () {
      expect(
        () => AIProviderTokenLimits(maxPromptTokens: 4000, maxCompletionTokens: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
