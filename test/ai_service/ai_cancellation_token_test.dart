import 'package:flutter_test/flutter_test.dart';

import '../../ai_service/domain/entities/ai_cancellation_token.dart';

void main() {
  group('AICancellationToken', () {
    test('starts out not cancelled', () {
      final token = AICancellationToken();

      expect(token.isCancelled, isFalse);
    });

    test('cancel() sets isCancelled and notifies listeners once', () {
      final token = AICancellationToken();
      var callCount = 0;
      token.onCancel(() => callCount++);

      token.cancel();
      token.cancel(); // idempotent -- must not notify twice

      expect(token.isCancelled, isTrue);
      expect(callCount, 1);
    });

    test('onCancel invokes immediately if already cancelled', () {
      final token = AICancellationToken()..cancel();
      var called = false;

      token.onCancel(() => called = true);

      expect(called, isTrue);
    });
  });
}
