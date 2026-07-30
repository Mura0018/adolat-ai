import 'package:adolat_ai/core/offline/sync/sync_backoff_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('delayFor', () {
    const policy = SyncBackoffPolicy(
      initialDelay: Duration(seconds: 5),
      maxDelay: Duration(minutes: 30),
    );

    test('birinchi urinish uchun boshlang\'ich kutish', () {
      expect(policy.delayFor(0), const Duration(seconds: 5));
    });

    test('har urinishda ortib boradi (exponential)', () {
      expect(policy.delayFor(1), const Duration(seconds: 10));
      expect(policy.delayFor(2), const Duration(seconds: 20));
      expect(policy.delayFor(3), const Duration(seconds: 40));
    });

    test('yuqori chegaradan oshmaydi', () {
      // Cheksiz o'sish amalda "abadiy kutish" bo'lardi.
      expect(policy.delayFor(50), const Duration(minutes: 30));
      expect(policy.delayFor(1000), const Duration(minutes: 30));
    });

    test('manfiy qiymat boshlang\'ich kutish sifatida qaraladi', () {
      expect(policy.delayFor(-1), const Duration(seconds: 5));
    });

    test('kutish oralig\'i hech qachon kamaymaydi', () {
      var previous = Duration.zero;
      for (var attempt = 0; attempt <= 12; attempt++) {
        final delay = policy.delayFor(attempt);
        expect(delay >= previous, isTrue, reason: '$attempt-urinishda kutish kamaydi');
        previous = delay;
      }
    });
  });

  group('shouldRetry', () {
    const policy = SyncBackoffPolicy(maxAttempts: 3);

    test('chegaraga yetgunicha qayta uriniladi', () {
      expect(policy.shouldRetry(0), isTrue);
      expect(policy.shouldRetry(2), isTrue);
    });

    test('chegaradan keyin to\'xtaydi — jimgina cheksiz urinilmaydi', () {
      expect(policy.shouldRetry(3), isFalse);
      expect(policy.shouldRetry(10), isFalse);
    });

    test('tugagan urinish uchun foydalanuvchiga tushunarli sabab beriladi', () {
      final reason = policy.exhaustedReason(3);

      expect(reason.trim(), isNotEmpty);
      // Xom texnik matn emas -- foydalanuvchiga ko'rsatiladigan xabar.
      expect(reason.contains('Exception'), isFalse);
    });
  });

  group('xolislik (pure)', () {
    test('bir xil kirish har doim bir xil natija', () {
      const policy = SyncBackoffPolicy();

      expect(policy.delayFor(4), policy.delayFor(4));
    });
  });
}
