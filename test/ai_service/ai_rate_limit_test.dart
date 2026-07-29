import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/gateway/ratelimit/ai_rate_limiter.dart';
import '../../ai_service/protocol/ai_rate_limit_contract.dart';

void main() {
  group('AIRateLimitPolicy', () {
    test('requires a positive maxRequests and window', () {
      expect(
        () => AIRateLimitPolicy(maxRequests: 0, window: const Duration(minutes: 1)),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => AIRateLimitPolicy(maxRequests: 10, window: Duration.zero),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('AIRateLimitStatus', () {
    test('round-trips through JSON', () {
      final status = AIRateLimitStatus(
        limit: 10,
        remaining: 3,
        resetAt: DateTime(2026, 1, 1, 12),
      );

      final decoded = AIRateLimitStatus.fromJson(status.toJson());

      expect(decoded, status);
    });

    test('isExceeded is true only when remaining is zero', () {
      final exhausted = AIRateLimitStatus(limit: 5, remaining: 0, resetAt: DateTime(2026, 1, 1));
      final available = AIRateLimitStatus(limit: 5, remaining: 1, resetAt: DateTime(2026, 1, 1));

      expect(exhausted.isExceeded, isTrue);
      expect(available.isExceeded, isFalse);
    });

    test('rejects negative limit or remaining', () {
      expect(
        () => AIRateLimitStatus(limit: -1, remaining: 0, resetAt: DateTime(2026, 1, 1)),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => AIRateLimitStatus(limit: 5, remaining: -1, resetAt: DateTime(2026, 1, 1)),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('AIRateLimitDecision', () {
    test('equality compares allowed and status', () {
      final status = AIRateLimitStatus(limit: 5, remaining: 4, resetAt: DateTime(2026, 1, 1));
      final a = AIRateLimitDecision(allowed: true, status: status);
      final b = AIRateLimitDecision(allowed: true, status: status);

      expect(a, b);
    });
  });
}
