import 'package:adolat_ai/core/offline/queue/in_memory_offline_queue.dart';
import 'package:adolat_ai/core/offline/queue/pending_operation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Bu testlar `OfflineQueue` SHARTNOMASINI tekshiradi — doimiy
/// (persistent) implementatsiya kelganda xuddi shu xatti-harakat
/// takrorlanishi kerak.
PendingOperation _operation({
  required String id,
  PendingOperationKind kind = PendingOperationKind.createRecord,
  PendingOperationStatus status = PendingOperationStatus.pending,
  String? dependsOn,
  DateTime? createdAt,
}) {
  return PendingOperation(
    id: id,
    kind: kind,
    entityType: 'appeal',
    entityId: 'appeal-1',
    payload: const {},
    createdAt: createdAt ?? DateTime.utc(2026),
    status: status,
    dependsOnOperationId: dependsOn,
  );
}

void main() {
  late InMemoryOfflineQueue queue;

  setUp(() => queue = InMemoryOfflineQueue());

  group('FIFO tartibi', () {
    test('amallar navbatga qo\'yilgan tartibda qaytariladi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.enqueue(_operation(id: 'op-2'));
      await queue.enqueue(_operation(id: 'op-3'));

      final batch = await queue.nextBatch();

      expect(batch.map((o) => o.id), ['op-1', 'op-2', 'op-3']);
    });

    test('qayta navbatga qo\'yilgan amal navbat oxiriga sakramaydi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.enqueue(_operation(id: 'op-2'));

      // op-1 muvaffaqiyatsiz bo'ldi va yangilandi.
      await queue.update(_operation(id: 'op-1').markFailed('tarmoq'));

      final batch = await queue.nextBatch();

      // Adolat: op-1 hamon birinchi -- aks holda muvaffaqiyatsiz amal
      // har safar oxiriga surilib, "hech qachon yuborilmaydigan"
      // holatga tushib qolardi.
      expect(batch.map((o) => o.id), ['op-1', 'op-2']);
    });

    test('limit hurmat qilinadi', () async {
      for (var i = 1; i <= 5; i++) {
        await queue.enqueue(_operation(id: 'op-$i'));
      }

      expect(await queue.nextBatch(limit: 2), hasLength(2));
    });
  });

  group('bog\'liqlik tartibi', () {
    test('bog\'langan amal, bog\'liqligi tugamaguncha qaytarilmaydi', () async {
      await queue.enqueue(_operation(id: 'record-op'));
      await queue.enqueue(
        _operation(
          id: 'file-op',
          kind: PendingOperationKind.uploadAttachment,
          dependsOn: 'record-op',
        ),
      );

      final batch = await queue.nextBatch();

      // Fayl hali mavjud bo'lmagan yozuvga bog'lanib qolmasligi kerak.
      expect(batch.map((o) => o.id), ['record-op']);
    });

    test('bog\'liqlik tugagach, bog\'langan amal chiqadi', () async {
      await queue.enqueue(_operation(id: 'record-op'));
      await queue.enqueue(
        _operation(
          id: 'file-op',
          kind: PendingOperationKind.uploadAttachment,
          dependsOn: 'record-op',
        ),
      );

      await queue.update(_operation(id: 'record-op').markCompleted());

      expect((await queue.nextBatch()).map((o) => o.id), ['file-op']);
    });

    test('bog\'liqlik tozalangan bo\'lsa, amal bloklanib qolmaydi', () async {
      // record-op muvaffaqiyatli tugagan va removeCompleted() bilan
      // tozalangan -- bog'langan amal MANGU kutib qolmasligi kerak
      // (boshi berk holat bo'lardi).
      await queue.enqueue(
        _operation(
          id: 'file-op',
          kind: PendingOperationKind.uploadAttachment,
          dependsOn: 'allaqachon-tozalangan',
        ),
      );

      expect((await queue.nextBatch()).map((o) => o.id), ['file-op']);
    });
  });

  group('holat bo\'yicha filtrlash', () {
    test('faqat pending va failed amallar sinxronizatsiyaga olinadi', () async {
      await queue.enqueue(_operation(id: 'pending-op'));
      await queue.enqueue(_operation(id: 'failed-op', status: PendingOperationStatus.failed));
      await queue.enqueue(
        _operation(id: 'attention-op', status: PendingOperationStatus.needsAttention),
      );
      await queue.enqueue(
        _operation(id: 'done-op', status: PendingOperationStatus.completed),
      );

      final batch = await queue.nextBatch();

      expect(batch.map((o) => o.id), ['pending-op', 'failed-op']);
    });

    test('getByStatus aniq holatdagilarni qaytaradi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.enqueue(
        _operation(id: 'op-2', status: PendingOperationStatus.needsAttention),
      );

      final blocked = await queue.getByStatus(PendingOperationStatus.needsAttention);

      expect(blocked.map((o) => o.id), ['op-2']);
    });
  });

  group('amal jimgina yo\'qolmaydi', () {
    test('muvaffaqiyatsiz amal navbatda qoladi', () async {
      await queue.enqueue(_operation(id: 'op-1'));

      await queue.update(_operation(id: 'op-1').markFailed('tarmoq uzildi'));

      expect(await queue.getById('op-1'), isNotNull);
      expect(await queue.pendingCount(), 1);
    });

    test('needsAttention amali ham navbatda qoladi', () async {
      await queue.enqueue(_operation(id: 'op-1'));

      await queue.update(_operation(id: 'op-1').markNeedsAttention('validatsiya'));

      expect(await queue.getById('op-1'), isNotNull);
      expect(await queue.pendingCount(), 1);
    });

    test('faqat aniq remove() amalni o\'chiradi', () async {
      await queue.enqueue(_operation(id: 'op-1'));

      await queue.remove('op-1');

      expect(await queue.getById('op-1'), isNull);
    });
  });

  group('idempotentlik va tozalash', () {
    test('bir xil id bilan qayta enqueue yangi yozuv yaratmaydi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.enqueue(_operation(id: 'op-1'));

      expect(await queue.getAll(), hasLength(1));
    });

    test('removeCompleted faqat tugaganlarni tozalaydi va sonini qaytaradi', () async {
      await queue.enqueue(_operation(id: 'op-1', status: PendingOperationStatus.completed));
      await queue.enqueue(_operation(id: 'op-2'));

      final removed = await queue.removeCompleted();

      expect(removed, 1);
      expect((await queue.getAll()).map((o) => o.id), ['op-2']);
    });

    test('pendingCount tugallanmagan amallarni sanaydi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.enqueue(_operation(id: 'op-2', status: PendingOperationStatus.completed));
      await queue.enqueue(
        _operation(id: 'op-3', status: PendingOperationStatus.needsAttention),
      );

      expect(await queue.pendingCount(), 2);
    });

    test('mavjud bo\'lmagan amalni update qilish yangi yozuv yaratmaydi', () async {
      await queue.update(_operation(id: 'yo\'q-amal'));

      expect(await queue.getAll(), isEmpty);
    });
  });
}
