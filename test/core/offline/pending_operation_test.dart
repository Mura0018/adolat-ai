import 'package:adolat_ai/core/offline/queue/pending_operation.dart';
import 'package:flutter_test/flutter_test.dart';

PendingOperation _operation({
  String id = 'op-1',
  PendingOperationStatus status = PendingOperationStatus.pending,
  int attemptCount = 0,
}) {
  return PendingOperation(
    id: id,
    kind: PendingOperationKind.createRecord,
    entityType: 'appeal',
    entityId: 'appeal-1',
    payload: const {'title': 'Sinov'},
    createdAt: DateTime.utc(2026),
    status: status,
    attemptCount: attemptCount,
  );
}

void main() {
  group('holat o\'tishlari', () {
    test('markInProgress urinishlar sonini oshiradi va vaqtni yozadi', () {
      final started = _operation().markInProgress(at: DateTime.utc(2026, 1, 2));

      expect(started.status, PendingOperationStatus.inProgress);
      expect(started.attemptCount, 1);
      expect(started.lastAttemptAt, DateTime.utc(2026, 1, 2));
    });

    test('markCompleted oldingi xatolik matnini tozalaydi', () {
      final completed = _operation().markFailed('tarmoq uzildi').markCompleted();

      expect(completed.status, PendingOperationStatus.completed);
      expect(completed.lastError, isNull);
    });

    test('markFailed xatolikni saqlaydi va amal qayta sinxronlanadigan qoladi', () {
      final failed = _operation().markFailed('server javob bermadi');

      expect(failed.status, PendingOperationStatus.failed);
      expect(failed.lastError, 'server javob bermadi');
      // MUHIM: vaqtinchalik xatolik amalni navbatdan chiqarmaydi.
      expect(failed.isSyncable, isTrue);
    });

    test('markNeedsAttention amalni qayta sinxronlanadigan holatdan chiqaradi', () {
      final blocked = _operation().markNeedsAttention('validatsiya xatosi');

      expect(blocked.status, PendingOperationStatus.needsAttention);
      // Jimgina cheksiz qayta urinilmaydi -- amal endi avtomatik
      // olinmaydi, foydalanuvchi qaroriga qoldiriladi.
      expect(blocked.isSyncable, isFalse);
    });

    test('har bir o\'tish YANGI nusxa qaytaradi, asl nusxa o\'zgarmaydi', () {
      final original = _operation();

      original.markInProgress(at: DateTime.utc(2026, 1, 2));
      original.markCompleted();

      expect(original.status, PendingOperationStatus.pending);
      expect(original.attemptCount, 0);
    });
  });

  group('idempotentlik kaliti', () {
    test('id qayta urinishlar davomida hech qachon o\'zgarmaydi', () {
      // docs/ARCHITECTURE.md, "Sync Engine": bir xil amal ikki marta
      // yuborilsa ham backend uni BITTA amal sifatida tanishi kerak --
      // bu faqat id barqaror bo'lgandagina ishlaydi.
      final operation = _operation(id: 'stable-key');

      final afterRetries = operation
          .markInProgress(at: DateTime.utc(2026, 1, 2))
          .markFailed('uzildi')
          .markInProgress(at: DateTime.utc(2026, 1, 3))
          .markFailed('yana uzildi')
          .markCompleted();

      expect(afterRetries.id, 'stable-key');
      expect(afterRetries.attemptCount, 2);
    });
  });

  group('PendingOperationStatus', () {
    test('faqat pending va failed sinxronlanishi mumkin', () {
      expect(PendingOperationStatus.pending.isSyncable, isTrue);
      expect(PendingOperationStatus.failed.isSyncable, isTrue);
      expect(PendingOperationStatus.inProgress.isSyncable, isFalse);
      expect(PendingOperationStatus.needsAttention.isSyncable, isFalse);
      expect(PendingOperationStatus.completed.isSyncable, isFalse);
    });

    test('faqat completed yakuniy holat', () {
      for (final status in PendingOperationStatus.values) {
        expect(status.isTerminal, status == PendingOperationStatus.completed);
      }
    });
  });

  group('xavfsizlik: toString', () {
    test('payload mazmunini hech qachon chiqarmaydi', () {
      final operation = PendingOperation(
        id: 'op-1',
        kind: PendingOperationKind.createRecord,
        entityType: 'appeal',
        entityId: 'appeal-1',
        payload: const {'bodyText': 'juda maxfiy shaxsiy tafsilot'},
        createdAt: DateTime.utc(2026),
      );

      expect(operation.toString().contains('juda maxfiy shaxsiy tafsilot'), isFalse);
    });

    test('xom xatolik matnini chiqarmaydi', () {
      final failed = _operation().markFailed('relation "public.appeals" does not exist');

      expect(failed.toString().contains('public.appeals'), isFalse);
    });
  });

  group('bog\'liqlik', () {
    test('dependsOnOperationId belgilanmasa bog\'liqlik yo\'q', () {
      expect(_operation().hasDependency, isFalse);
    });

    test('bog\'liqlik holat o\'tishlarida saqlanadi', () {
      final operation = PendingOperation(
        id: 'op-2',
        kind: PendingOperationKind.uploadAttachment,
        entityType: 'attachment',
        entityId: 'file-1',
        payload: const {},
        createdAt: DateTime.utc(2026),
        dependsOnOperationId: 'op-1',
      );

      final afterRetry = operation.markInProgress(at: DateTime.utc(2026, 1, 2)).markFailed('x');

      expect(afterRetry.dependsOnOperationId, 'op-1');
      expect(afterRetry.hasDependency, isTrue);
    });
  });
}
