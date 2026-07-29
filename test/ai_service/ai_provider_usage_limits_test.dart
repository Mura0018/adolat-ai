import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/config/domain/ai_provider_usage_limits.dart';

void main() {
  group('AIProviderUsageLimits', () {
    test('round-trips through JSON', () {
      const limits = AIProviderUsageLimits(maxRequestsPerDay: 1000, maxConcurrentRequests: 10);

      final decoded = AIProviderUsageLimits.fromJson(limits.toJson());

      expect(decoded, limits);
    });

    test('rejects a non-positive maxRequestsPerDay', () {
      expect(
        () => AIProviderUsageLimits(maxRequestsPerDay: 0, maxConcurrentRequests: 10),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a non-positive maxConcurrentRequests', () {
      expect(
        () => AIProviderUsageLimits(maxRequestsPerDay: 1000, maxConcurrentRequests: 0),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
