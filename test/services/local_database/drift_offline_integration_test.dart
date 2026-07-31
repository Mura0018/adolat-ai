import 'package:adolat_ai/core/offline/queue/local_store_offline_queue.dart';
import 'package:adolat_ai/core/offline/queue/offline_queue.dart';
import 'package:adolat_ai/core/offline/queue/pending_operation.dart';
import 'package:adolat_ai/core/offline/sync/queued_sync_engine.dart';
import 'package:adolat_ai/core/offline/sync/sync_engine.dart';
import 'package:adolat_ai/core/offline/sync/sync_operation_outcome.dart';
import 'package:adolat_ai/services/local_database/app_local_database.dart';
import 'package:adolat_ai/services/local_database/drift_local_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// **Integration testi (Module 7A):** butun offline steki — navbat,
/// sinxronizatsiya dvigateli va haqiqiy SQLite saqlash — birgalikda.
///
/// Birlik testlaridan farqi: bu yerda hech qanday xotiradagi soxta
/// saqlash yo'q. Ma'lumot haqiqiy SQLite bazasiga yoziladi va
/// **yangi obyektlar orqali qayta o'qiladi** — ya'ni "ilova yopildi
/// va qayta ochildi" stsenariysi taqlid qilinadi. Aynan shu
/// `docs/ARCHITECTURE.md`ning "Doimiylik (persistence)" talabi
/// Module 6'da tekshirib bo'lmaydigan yagona narsa edi.
class _FakeHandler implements SyncOperationHandler {
  _FakeHandler({this.outcome = const SyncSuccess()});

  SyncOperationOutcome outcome;
  final List<String> performed = <String>[];

  @override
  bool canHandle(PendingOperation operation) => true;

  @override
  Future<SyncOperationOutcome> perform(PendingOperation operation) async {
    performed.add(operation.id);
    return outcome;
  }
}

PendingOperation _operation({
  required String id,
  PendingOperationKind kind = PendingOperationKind.createRecord,
  String entityId = 'appeal-1',
  String? dependsOn,
}) {
  return PendingOperation(
    id: id,
    kind: kind,
    entityType: 'appeal',
    entityId: entityId,
    payload: {'title': 'Ishdan asossiz bo\'shatildim', 'bodyText': 'Batafsil matn'},
    createdAt: DateTime.utc(2026, 1, 1),
    dependsOnOperationId: dependsOn,
  );
}

void main() {
  late AppLocalDatabase db;
  late OfflineQueue queue;

  /// Bir xil baza ustida YANGI navbat obyekti — "ilova qayta ochildi".
  OfflineQueue reopenQueue() =>
      LocalStoreOfflineQueue(DriftLocalStore(db, 'pending_operations'));

  setUp(() {
    db = AppLocalDatabase.memory();
    queue = reopenQueue();
  });

  tearDown(() async => db.close());

  group('doimiylik (persistence)', () {
    test('navbatga qo\'yilgan amal qayta ochilgandan keyin ham turadi', () async {
      await queue.enqueue(_operation(id: 'op-1'));

      final afterRestart = reopenQueue();

      expect((await afterRestart.getAll()).map((o) => o.id), ['op-1']);
    });

    test('amal mazmuni to\'liq saqlanadi (payload, sana, bog\'liqlik)', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.enqueue(
        _operation(id: 'op-2', kind: PendingOperationKind.uploadAttachment, dependsOn: 'op-1'),
      );

      final restored = (await reopenQueue().getById('op-2'))!;

      expect(restored.kind, PendingOperationKind.uploadAttachment);
      expect(restored.entityType, 'appeal');
      expect(restored.dependsOnOperationId, 'op-1');
      expect(restored.createdAt, DateTime.utc(2026, 1, 1));
      expect(restored.payload['title'], 'Ishdan asossiz bo\'shatildim');
    });

    test('holat va urinishlar tarixi ham saqlanadi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.update(
        (await queue.getById('op-1'))!
            .markInProgress(at: DateTime.utc(2026, 1, 2))
            .markFailed('tarmoq uzildi'),
      );

      final restored = (await reopenQueue().getById('op-1'))!;

      expect(restored.status, PendingOperationStatus.failed);
      expect(restored.attemptCount, 1);
      expect(restored.lastAttemptAt, DateTime.utc(2026, 1, 2));
      expect(restored.lastError, 'tarmoq uzildi');
    });

    test('FIFO tartibi qayta ochilgandan keyin ham saqlanadi', () async {
      for (var i = 1; i <= 5; i++) {
        await queue.enqueue(_operation(id: 'op-$i', entityId: 'appeal-$i'));
      }

      expect((await reopenQueue().nextBatch()).map((o) => o.id), [
        'op-1',
        'op-2',
        'op-3',
        'op-4',
        'op-5',
      ]);
    });

    test('o\'chirilgan amal qayta ochilganda qaytmaydi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.remove('op-1');

      expect(await reopenQueue().getAll(), isEmpty);
    });
  });

  group('to\'liq oqim: oflaynda yaratish -> qayta ochish -> yuborish', () {
    test('foydalanuvchi ishi ilova yopilishidan omon qoladi va yuboriladi', () async {
      // 1. Foydalanuvchi tarmoqsiz murojaat yaratdi.
      await queue.enqueue(_operation(id: 'appeal-op'));
      await queue.enqueue(
        _operation(
          id: 'file-op',
          kind: PendingOperationKind.uploadAttachment,
          entityId: 'file-1',
          dependsOn: 'appeal-op',
        ),
      );

      // 2. Ilova yopildi va qayta ochildi.
      final restored = reopenQueue();
      final handler = _FakeHandler();
      final engine = QueuedSyncEngine(
        queue: restored,
        handlers: [handler],
        clock: () => DateTime.utc(2026, 1, 3),
      );

      // 3. Internet qaytdi -- sinxronizatsiya ishga tushdi.
      await engine.sync(trigger: SyncTrigger.connectivityRestored);
      await engine.sync(trigger: SyncTrigger.connectivityRestored);

      // Yozuv avval, fayl keyin -- bog'liqlik tartibi saqlangan.
      expect(handler.performed, ['appeal-op', 'file-op']);
      expect((await restored.getById('appeal-op'))!.status, PendingOperationStatus.completed);
      expect((await restored.getById('file-op'))!.status, PendingOperationStatus.completed);
      await engine.dispose();
    });

    test('yakunlangan amallar tozalanadi va baza bo\'shaydi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final engine = QueuedSyncEngine(
        queue: queue,
        handlers: [_FakeHandler()],
        clock: () => DateTime.utc(2026, 1, 3),
      );
      await engine.sync(trigger: SyncTrigger.appStart);

      expect(await queue.removeCompleted(), 1);
      expect(await reopenQueue().getAll(), isEmpty);
      await engine.dispose();
    });

    test('bloklangan amal qayta ochilgandan keyin ham e\'tibor kutadi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final engine = QueuedSyncEngine(
        queue: queue,
        handlers: [_FakeHandler(outcome: const SyncPermanentFailure('validatsiya xatosi'))],
        clock: () => DateTime.utc(2026, 1, 3),
      );
      await engine.sync(trigger: SyncTrigger.appStart);

      final restored = (await reopenQueue().getById('op-1'))!;

      expect(restored.status, PendingOperationStatus.needsAttention);
      expect(restored.lastError, 'validatsiya xatosi');
      // Foydalanuvchi uchun chiqish yo'li ham saqlanadi.
      await reopenQueue().retryNow('op-1');
      expect((await reopenQueue().getById('op-1'))!.status, PendingOperationStatus.pending);
      await engine.dispose();
    });
  });

  group('takrorlanish qoidalari doimiy saqlashda ham amal qiladi', () {
    test('ketma-ket tahrirlar bittaga birlashadi', () async {
      for (var i = 1; i <= 3; i++) {
        await queue.enqueue(
          _operation(id: 'edit-$i', kind: PendingOperationKind.updateRecord),
        );
      }

      expect((await reopenQueue().getAll()).map((o) => o.id), ['edit-3']);
    });

    test('boshlangan amal ustiga yozilmaydi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.update(
        (await queue.getById('op-1'))!.markInProgress(at: DateTime.utc(2026, 1, 2)),
      );

      await queue.enqueue(_operation(id: 'op-1'));

      final stored = (await reopenQueue().getById('op-1'))!;
      expect(stored.status, PendingOperationStatus.inProgress);
      expect(stored.attemptCount, 1);
    });
  });

  group('sxema va migratsiya', () {
    test('sxema versiyasi 1', () {
      expect(db.schemaVersion, 1);
    });

    test('bo\'sh bazada navbat bo\'sh, xatolik yo\'q', () async {
      expect(await queue.getAll(), isEmpty);
      expect(await queue.nextBatch(), isEmpty);
      expect(await queue.pendingCount(), 0);
    });

    test('katta hajmdagi navbat tartibni saqlaydi', () async {
      for (var i = 1; i <= 100; i++) {
        await queue.enqueue(_operation(id: 'op-$i', entityId: 'appeal-$i'));
      }

      final all = await reopenQueue().getAll();

      expect(all, hasLength(100));
      expect(all.first.id, 'op-1');
      expect(all.last.id, 'op-100');
    });
  });
}
