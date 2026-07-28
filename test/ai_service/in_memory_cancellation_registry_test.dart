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

    test('register replaces a previous token for the same conversation', () {
      final registry = InMemoryCancellationRegistry();
      final first = registry.register('c1');
      final second = registry.register('c1');

      registry.cancel('c1');

      expect(second.isCancelled, isTrue);
      expect(first.isCancelled, isFalse); // no longer tracked, not touched
    });

    test('release removes the token without cancelling it', () {
      final registry = InMemoryCancellationRegistry();
      final token = registry.register('c1');

      registry.release('c1');
      registry.cancel('c1'); // nothing left to cancel

      expect(token.isCancelled, isFalse);
    });
  });
}
