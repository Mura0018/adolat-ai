import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/quota/ai_usage_quota.dart';
import '../../ai_service/protocol/ai_usage_quota_contract.dart';

void main() {
  group('evaluateUsageQuota', () {
    final policy = AIUsageQuotaPolicy(maxRequestsPerWindow: 3, window: const Duration(days: 1));

    test('allows requests while under the limit', () {
      final state = AIUsageQuotaState(usedInWindow: 1, windowStartedAt: DateTime(2026, 1, 1));

      final decision = evaluateUsageQuota(
        policy: policy,
        state: state,
        now: DateTime(2026, 1, 1, 6),
      );

      expect(decision.allowed, isTrue);
      expect(decision.remaining, 1); // 3 - 1 used - 1 for this request
    });

    test('denies requests once the limit is reached', () {
      final state = AIUsageQuotaState(usedInWindow: 3, windowStartedAt: DateTime(2026, 1, 1));

      final decision = evaluateUsageQuota(
        policy: policy,
        state: state,
        now: DateTime(2026, 1, 1, 6),
      );

      expect(decision.allowed, isFalse);
      expect(decision.remaining, 0);
    });

    test('resets and allows once the window has expired', () {
      final state = AIUsageQuotaState(usedInWindow: 3, windowStartedAt: DateTime(2026, 1, 1));

      final decision = evaluateUsageQuota(
        policy: policy,
        state: state,
        now: DateTime(2026, 1, 3), // more than one day after windowStartedAt
      );

      expect(decision.allowed, isTrue);
      expect(decision.remaining, 2);
    });
  });

  group('AIUsageQuotaPolicy', () {
    test('requires a positive maxRequestsPerWindow and window', () {
      expect(
        () => AIUsageQuotaPolicy(maxRequestsPerWindow: 0, window: const Duration(days: 1)),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => AIUsageQuotaPolicy(maxRequestsPerWindow: 5, window: Duration.zero),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('AIUsageQuotaStatus', () {
    test('round-trips through JSON', () {
      final status = AIUsageQuotaStatus(limit: 10, used: 4, resetAt: DateTime(2026, 1, 2));

      final decoded = AIUsageQuotaStatus.fromJson(status.toJson());

      expect(decoded, status);
    });

    test('remaining never goes negative even if used exceeds limit', () {
      final status = AIUsageQuotaStatus(limit: 5, used: 7, resetAt: DateTime(2026, 1, 2));

      expect(status.remaining, 0);
      expect(status.isExceeded, isTrue);
    });

    test('isExceeded is false while used is below limit', () {
      final status = AIUsageQuotaStatus(limit: 5, used: 4, resetAt: DateTime(2026, 1, 2));

      expect(status.isExceeded, isFalse);
      expect(status.remaining, 1);
    });
  });
}
