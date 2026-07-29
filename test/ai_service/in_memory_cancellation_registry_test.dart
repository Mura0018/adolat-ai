import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/data/session/in_memory_cancellation_registry.dart';

void main() {
  group('InMemoryCancellationRegistry', () {
    test('cancel triggers the token registered for that conversation', () {
      final registry = InMemoryCancellationRegistry();
      final token = registry.register('c1');

      expect(token.isCancelled, isFalse);

      registry.cancel('c1');

      expect(token.isCancelled, isTrue);
    });

    test('cancel is a no-op for an unregistered conversation', () {
      final registry = InMemoryCancellationRegistry();

      expect(() => registry.cancel('unknown'), returnsNormally);
    });

    test(
      'register cancels the previous token for the same conversation before replacing it',
      () {
        final registry = InMemoryCancellationRegistry();
        final first = registry.register('c1');
        final second = registry.register('c1');

        // Concurrency edge case fix: registering a second in-flight
        // request for the same conversation must not orphan the first
        // token in an uncancellable, silently-still-running state.
        expect(first.isCancelled, isTrue);
        expect(second.isCancelled, isFalse);

        registry.cancel('c1');

        expect(second.isCancelled, isTrue);
      },
    );

    test('release removes the token without cancelling it', () {
      final registry = InMemoryCancellationRegistry();
      final token = registry.register('c1');

      registry.release('c1');
      registry.cancel('c1'); // nothing left to cancel

      expect(token.isCancelled, isFalse);
    });
  });
}
