import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/entities/ai_failure.dart';
import '../../ai_service/domain/retry/ai_retry_policy.dart';

void main() {
  group('AIRetryPolicy.delayForAttempt', () {
    test('applies exponential backoff from initialDelay', () {
      const policy = AIRetryPolicy(
        initialDelay: Duration(seconds: 1),
        backoffMultiplier: 2.0,
      );

      expect(policy.delayForAttempt(1), const Duration(seconds: 1));
      expect(policy.delayForAttempt(2), const Duration(seconds: 2));
      expect(policy.delayForAttempt(3), const Duration(seconds: 4));
    });

    test('backoffMultiplier of 1.0 keeps a constant delay', () {
      const policy = AIRetryPolicy(
        initialDelay: Duration(seconds: 1),
        backoffMultiplier: 1.0,
      );

      expect(policy.delayForAttempt(1), const Duration(seconds: 1));
      expect(policy.delayForAttempt(5), const Duration(seconds: 1));
    });
  });

  group('AIRetryPolicy.shouldRetry', () {
    test('allows retrying a retryable failure while attempts remain', () {
      const policy = AIRetryPolicy(maxAttempts: 3);

      expect(
        policy.shouldRetry(failure: const AINetworkFailure(), attemptNumber: 1),
        isTrue,
      );
      expect(
        policy.shouldRetry(failure: const AINetworkFailure(), attemptNumber: 2),
        isTrue,
      );
    });

    test('refuses once maxAttempts is reached, even for a retryable failure', () {
      const policy = AIRetryPolicy(maxAttempts: 3);

      expect(
        policy.shouldRetry(failure: const AINetworkFailure(), attemptNumber: 3),
        isFalse,
      );
    });

    test('refuses a non-retryable failure regardless of attempts remaining', () {
      const policy = AIRetryPolicy(maxAttempts: 5);

      expect(
        policy.shouldRetry(
          failure: const AISafetyRejectionFailure(reason: 'x'),
          attemptNumber: 1,
        ),
        isFalse,
      );
    });
  });
}
