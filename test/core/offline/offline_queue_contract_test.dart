import 'package:adolat_ai/core/offline/queue/in_memory_offline_queue.dart';
import 'package:adolat_ai/core/offline/queue/local_store_offline_queue.dart';
import 'package:adolat_ai/core/offline/queue/offline_queue.dart';
import 'package:adolat_ai/core/offline/queue/pending_operation.dart';
import 'package:adolat_ai/core/offline/storage/in_memory_local_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// `OfflineQueue` SHARTNOMASINING testlari — **ikkala implementatsiya
/// ustida bir xil bajariladi** (Module 6C).
///
/// **Nega shunday:** `LocalStoreOfflineQueue` doimiy saqlashga o'tish
/// yo'li; agar u `InMemoryOfflineQueue`dan boshqacha xatti-harakat
/// qilsa, doimiylik yoqilgan kuni offline oqim jimgina buzilardi.
/// Yagona shartnoma testi bu farqni paydo bo'lgan zahoti ushlaydi va
/// kelgusi (Drift/Isar/Hive) implementatsiyasi uchun ham tayyor
/// mezon bo'lib qoladi.
PendingOperation _operation({
  required String id,
  PendingOperationKind kind = PendingOperationKind.createRecord,
  PendingOperationStatus status = PendingOperationStatus.pending,
  String entityId = 'appeal-1',
  String? dependsOn,
  int attemptCount = 0,
}) {
  return PendingOperation(
    id: id,
    kind: kind,
    entityType: 'appeal',
    entityId: entityId,
    payload: const {'title': 'Sinov'},
    createdAt: DateTime.utc(2026),
    status: status,
    attemptCount: attemptCount,
    dependsOnOperationId: dependsOn,
  );
}

void main() {
  final implementations = <String, OfflineQueue Function()>{
    'InMemoryOfflineQueue': InMemoryOfflineQueue.new,
    'LocalStoreOfflineQueue': () =>
        LocalStoreOfflineQueue(InMemoryLocalStore<Map<String, Object?>>()),
  };

  implementations.forEach((name, create) {
    group('$name — OfflineQueue shartnomasi', () {
      late OfflineQueue queue;

      setUp(() => queue = create());

      group('FIFO va asosiy amallar', () {
        test('navbatga qo\'yilgan tartibda qaytaradi', () async {
          await queue.enqueue(_operation(id: 'op-1'));
          await queue.enqueue(_operation(id: 'op-2'));
          await queue.enqueue(_operation(id: 'op-3'));

          expect((await queue.nextBatch()).map((o) => o.id), ['op-1', 'op-2', 'op-3']);
        });

        test('limit hurmat qilinadi', () async {
          for (var i = 1; i <= 4; i++) {
            await queue.enqueue(_operation(id: 'op-$i'));
          }

          expect(await queue.nextBatch(limit: 2), hasLength(2));
        });

        test('faqat pending/failed sinxronizatsiyaga olinadi', () async {
          await queue.enqueue(_operation(id: 'pending-op'));
          await queue.enqueue(
            _operation(id: 'failed-op', status: PendingOperationStatus.failed),
          );
          await queue.enqueue(
            _operation(id: 'blocked-op', status: PendingOperationStatus.needsAttention),
          );
          await queue.enqueue(
            _operation(id: 'done-op', status: PendingOperationStatus.completed),
          );

          expect((await queue.nextBatch()).map((o) => o.id), ['pending-op', 'failed-op']);
        });

        test('update mavjud bo\'lmagan amal uchun yozuv yaratmaydi', () async {
          await queue.update(_operation(id: 'yo\'q'));

          expect(await queue.getAll(), isEmpty);
        });
      });

      group('idempotentlik va takrorlanish (Module 6C)', () {
        test('bir xil id ikkinchi yozuv yaratmaydi', () async {
          await queue.enqueue(_operation(id: 'op-1'));
          await queue.enqueue(_operation(id: 'op-1'));

          expect(await queue.getAll(), hasLength(1));
        });

        test('BOSHLANGAN amal ustiga yozilmaydi — ikki marta yuborish xavfi', () async {
          await queue.enqueue(_operation(id: 'op-1'));
          await queue.update(
            (await queue.getById('op-1'))!.markInProgress(at: DateTime.utc(2026, 2)),
          );

          // Bir vaqtda kelgan takroriy enqueue holatni nolga
          // qaytarmasligi shart.
          await queue.enqueue(_operation(id: 'op-1'));

          final stored = (await queue.getById('op-1'))!;
          expect(stored.status, PendingOperationStatus.inProgress);
          expect(stored.attemptCount, 1);
        });

        test('YAKUNLANGAN amal ustiga yozilmaydi', () async {
          await queue.enqueue(_operation(id: 'op-1'));
          await queue.update((await queue.getById('op-1'))!.markCompleted());

          await queue.enqueue(_operation(id: 'op-1'));

          expect((await queue.getById('op-1'))!.status, PendingOperationStatus.completed);
        });

        test('ketma-ket tahrirlar bittaga birlashadi (eng so\'nggisi qoladi)', () async {
          await queue.enqueue(
            _operation(id: 'edit-1', kind: PendingOperationKind.updateRecord),
          );
          await queue.enqueue(
            _operation(id: 'edit-2', kind: PendingOperationKind.updateRecord),
          );
          await queue.enqueue(
            _operation(id: 'edit-3', kind: PendingOperationKind.updateRecord),
          );

          expect((await queue.getAll()).map((o) => o.id), ['edit-3']);
        });

        test('BOSHQA yozuvning tahriri birlashtirilmaydi', () async {
          await queue.enqueue(
            _operation(
              id: 'edit-a',
              kind: PendingOperationKind.updateRecord,
              entityId: 'appeal-1',
            ),
          );
          await queue.enqueue(
            _operation(
              id: 'edit-b',
              kind: PendingOperationKind.updateRecord,
              entityId: 'appeal-2',
            ),
          );

          expect(await queue.getAll(), hasLength(2));
        });

        test('BOSHLANGAN tahrir birlashtirilmaydi — u allaqachon yuborilyapti', () async {
          await queue.enqueue(
            _operation(id: 'edit-1', kind: PendingOperationKind.updateRecord),
          );
          await queue.update(
            (await queue.getById('edit-1'))!.markInProgress(at: DateTime.utc(2026, 2)),
          );

          await queue.enqueue(
            _operation(id: 'edit-2', kind: PendingOperationKind.updateRecord),
          );

          expect((await queue.getAll()).map((o) => o.id), ['edit-1', 'edit-2']);
        });

        test('fayl yuklash va AI so\'rovi HECH QACHON birlashtirilmaydi', () async {
          // Ular qo'shimcha qiluvchi amallar -- birlashtirish
          // foydalanuvchi ishini jimgina yo'qotardi.
          for (final kind in [
            PendingOperationKind.uploadAttachment,
            PendingOperationKind.requestAiAnalysis,
            PendingOperationKind.createRecord,
            PendingOperationKind.submitRecord,
            PendingOperationKind.deleteRecord,
          ]) {
            final fresh = create();
            await fresh.enqueue(_operation(id: 'op-1', kind: kind));
            await fresh.enqueue(_operation(id: 'op-2', kind: kind));

            expect(
              await fresh.getAll(),
              hasLength(2),
              reason: '${kind.name} birlashtirilmasligi kerak',
            );
          }
        });
      });

      group('bog\'liqlik', () {
        test('bog\'liqligi tugamagan amal qaytarilmaydi', () async {
          await queue.enqueue(_operation(id: 'record-op'));
          await queue.enqueue(
            _operation(
              id: 'file-op',
              kind: PendingOperationKind.uploadAttachment,
              dependsOn: 'record-op',
            ),
          );

          expect((await queue.nextBatch()).map((o) => o.id), ['record-op']);
        });

        test('bog\'liqlik tugagach chiqadi', () async {
          await queue.enqueue(_operation(id: 'record-op'));
          await queue.enqueue(
            _operation(
              id: 'file-op',
              kind: PendingOperationKind.uploadAttachment,
              dependsOn: 'record-op',
            ),
          );
          await queue.update((await queue.getById('record-op'))!.markCompleted());

          expect((await queue.nextBatch()).map((o) => o.id), ['file-op']);
        });

        test('tozalangan bog\'liqlik amalni bloklamaydi', () async {
          await queue.enqueue(
            _operation(
              id: 'file-op',
              kind: PendingOperationKind.uploadAttachment,
              dependsOn: 'allaqachon-tozalangan',
            ),
          );

          expect((await queue.nextBatch()).map((o) => o.id), ['file-op']);
        });

        test('dependentsOf bog\'liq amallarni topadi', () async {
          await queue.enqueue(_operation(id: 'parent'));
          await queue.enqueue(
            _operation(
              id: 'child',
              kind: PendingOperationKind.uploadAttachment,
              dependsOn: 'parent',
            ),
          );

          expect((await queue.dependentsOf('parent')).map((o) => o.id), ['child']);
          expect(await queue.dependentsOf('child'), isEmpty);
        });
      });

      group('lifecycle (Module 6C)', () {
        test('retryNow bloklangan amalni navbatga qaytaradi va urinishlarni nollaydi', () async {
          await queue.enqueue(_operation(id: 'op-1', attemptCount: 5));
          await queue.update(
            (await queue.getById('op-1'))!.markNeedsAttention('validatsiya xatosi'),
          );

          await queue.retryNow('op-1');

          final stored = (await queue.getById('op-1'))!;
          expect(stored.status, PendingOperationStatus.pending);
          expect(stored.attemptCount, 0);
          expect(stored.lastError, isNull);
          expect(stored.isSyncable, isTrue);
        });

        test('retryNow boshqa holatdagi amalga ta\'sir qilmaydi', () async {
          await queue.enqueue(_operation(id: 'op-1'));
          await queue.update((await queue.getById('op-1'))!.markCompleted());

          await queue.retryNow('op-1');

          expect((await queue.getById('op-1'))!.status, PendingOperationStatus.completed);
        });

        test('retryNow mavjud bo\'lmagan amal uchun xatolik bermaydi', () async {
          await expectLater(queue.retryNow('yo\'q'), completes);
        });

        test('remove faqat so\'ralgan amalni o\'chiradi', () async {
          await queue.enqueue(_operation(id: 'op-1'));
          await queue.enqueue(_operation(id: 'op-2'));

          await queue.remove('op-1');

          expect((await queue.getAll()).map((o) => o.id), ['op-2']);
        });

        test('removeCompleted faqat tugaganlarni tozalaydi', () async {
          await queue.enqueue(_operation(id: 'op-1'));
          await queue.enqueue(_operation(id: 'op-2'));
          await queue.update((await queue.getById('op-1'))!.markCompleted());

          expect(await queue.removeCompleted(), 1);
          expect((await queue.getAll()).map((o) => o.id), ['op-2']);
        });

        test('pendingCount tugallanmaganlarni sanaydi', () async {
          await queue.enqueue(_operation(id: 'op-1'));
          await queue.enqueue(
            _operation(id: 'op-2', status: PendingOperationStatus.needsAttention),
          );
          await queue.enqueue(
            _operation(id: 'op-3', status: PendingOperationStatus.completed),
          );

          expect(await queue.pendingCount(), 2);
        });
      });
    });
  });

  group('LocalStoreOfflineQueue doimiylik yo\'li', () {
    test('bir xil LocalStore ustidagi yangi navbat ma\'lumotni ko\'radi', () async {
      // Doimiy `LocalStore` implementatsiyasi kelganda AYNAN shu
      // stsenariy "ilova qayta ochildi" degani bo'ladi.
      final store = InMemoryLocalStore<Map<String, Object?>>();
      final first = LocalStoreOfflineQueue(store);
      await first.enqueue(_operation(id: 'op-1'));

      final second = LocalStoreOfflineQueue(store);

      expect((await second.getAll()).map((o) => o.id), ['op-1']);
      expect((await second.nextBatch()).map((o) => o.id), ['op-1']);
    });

    test('holat o\'zgarishi ham saqlanadi', () async {
      final store = InMemoryLocalStore<Map<String, Object?>>();
      final queue = LocalStoreOfflineQueue(store);
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.update(
        (await queue.getById('op-1'))!.markInProgress(at: DateTime.utc(2026, 3)),
      );

      final reopened = LocalStoreOfflineQueue(store);
      final stored = (await reopened.getById('op-1'))!;

      expect(stored.status, PendingOperationStatus.inProgress);
      expect(stored.attemptCount, 1);
      expect(stored.lastAttemptAt, DateTime.utc(2026, 3));
    });
  });
}
