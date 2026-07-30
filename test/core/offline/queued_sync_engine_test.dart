import 'package:adolat_ai/core/offline/conflict/sync_conflict.dart';
import 'package:adolat_ai/core/offline/queue/in_memory_offline_queue.dart';
import 'package:adolat_ai/core/offline/queue/pending_operation.dart';
import 'package:adolat_ai/core/offline/sync/queued_sync_engine.dart';
import 'package:adolat_ai/core/offline/sync/sync_backoff_policy.dart';
import 'package:adolat_ai/core/offline/sync/sync_engine.dart';
import 'package:adolat_ai/core/offline/sync/sync_operation_outcome.dart';
import 'package:adolat_ai/core/offline/sync/sync_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Test uchun boshqariladigan handler — `SyncOperationHandler`
/// chegarasining o'rnini bosadi. Haqiqiy implementatsiya (Supabase)
/// keyingi bosqichda shu interfeysni amalga oshiradi; dvigatelning
/// o'zi o'zgarmasligi kerak.
class _FakeHandler implements SyncOperationHandler {
  _FakeHandler({this.outcome = const SyncSuccess(), this.throwError = false});

  SyncOperationOutcome outcome;
  bool throwError;
  final List<String> performedOperationIds = <String>[];

  @override
  bool canHandle(PendingOperation operation) => true;

  @override
  Future<SyncOperationOutcome> perform(PendingOperation operation) async {
    performedOperationIds.add(operation.id);
    if (throwError) throw StateError('kutilmagan ichki xato');
    return outcome;
  }
}

class _RejectingHandler implements SyncOperationHandler {
  @override
  bool canHandle(PendingOperation operation) => false;

  @override
  Future<SyncOperationOutcome> perform(PendingOperation operation) async {
    throw StateError('chaqirilmasligi kerak');
  }
}

PendingOperation _operation({required String id, String? dependsOn}) {
  return PendingOperation(
    id: id,
    kind: PendingOperationKind.createRecord,
    entityType: 'appeal',
    entityId: 'appeal-1',
    payload: const {},
    createdAt: DateTime.utc(2026),
    dependsOnOperationId: dependsOn,
  );
}

void main() {
  late InMemoryOfflineQueue queue;

  setUp(() => queue = InMemoryOfflineQueue());

  QueuedSyncEngine engineWith(
    List<SyncOperationHandler> handlers, {
    Future<bool> Function()? isOnline,
    SyncBackoffPolicy backoff = const SyncBackoffPolicy(),
  }) {
    return QueuedSyncEngine(
      queue: queue,
      handlers: handlers,
      isOnline: isOnline,
      backoffPolicy: backoff,
      clock: () => DateTime.utc(2026, 1, 2),
    );
  }

  group('muvaffaqiyatli sikl', () {
    test('navbatdagi amallarni FIFO tartibida bajaradi', () async {
      final handler = _FakeHandler();
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.enqueue(_operation(id: 'op-2'));

      final report = await engineWith([handler]).sync(trigger: SyncTrigger.appStart);

      expect(handler.performedOperationIds, ['op-1', 'op-2']);
      expect(report.succeeded, 2);
      expect(report.hasFailures, isFalse);
    });

    test('muvaffaqiyatli amal completed holatiga o\'tadi', () async {
      await queue.enqueue(_operation(id: 'op-1'));

      await engineWith([_FakeHandler()]).sync(trigger: SyncTrigger.manual);

      expect((await queue.getById('op-1'))!.status, PendingOperationStatus.completed);
    });

    test('bo\'sh navbat xatolik emas', () async {
      final report = await engineWith([_FakeHandler()]).sync(trigger: SyncTrigger.appStart);

      expect(report.processed, 0);
      expect(report.hasFailures, isFalse);
    });
  });

  group('vaqtinchalik xatolik — amal navbatda qoladi', () {
    test('failed holatiga o\'tadi va qayta sinxronlanadigan qoladi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final handler = _FakeHandler(outcome: const SyncTransientFailure('tarmoq uzildi'));

      final report = await engineWith([handler]).sync(trigger: SyncTrigger.appStart);

      final stored = (await queue.getById('op-1'))!;
      expect(stored.status, PendingOperationStatus.failed);
      expect(stored.isSyncable, isTrue);
      expect(report.transientFailures, 1);
    });

    test('keyingi siklda qayta uriniladi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final handler = _FakeHandler(outcome: const SyncTransientFailure('uzildi'));
      final engine = engineWith([handler]);

      await engine.sync(trigger: SyncTrigger.appStart);
      handler.outcome = const SyncSuccess();
      await engine.sync(trigger: SyncTrigger.connectivityRestored);

      expect(handler.performedOperationIds, ['op-1', 'op-1']);
      expect((await queue.getById('op-1'))!.status, PendingOperationStatus.completed);
    });

    test('urinishlar chegarasiga yetganda needsAttention bo\'ladi', () async {
      // "Jimgina cheksiz qayta urinilmaydi" talabi.
      await queue.enqueue(_operation(id: 'op-1'));
      final engine = engineWith(
        [_FakeHandler(outcome: const SyncTransientFailure('uzildi'))],
        backoff: const SyncBackoffPolicy(maxAttempts: 2),
      );

      await engine.sync(trigger: SyncTrigger.appStart);
      await engine.sync(trigger: SyncTrigger.appStart);
      await engine.sync(trigger: SyncTrigger.appStart);

      final stored = (await queue.getById('op-1'))!;
      expect(stored.status, PendingOperationStatus.needsAttention);
      expect(stored.lastError, isNotNull);
    });

    test('handler kutilmagan exception tashlasa, ma\'lumot yo\'qolmaydi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final handler = _FakeHandler(throwError: true);

      await engineWith([handler]).sync(trigger: SyncTrigger.appStart);

      // Ehtiyotkorlik: kutilmagan xatolik VAQTINCHALIK deb qaraladi,
      // amal navbatda qoladi.
      final stored = (await queue.getById('op-1'))!;
      expect(stored.status, PendingOperationStatus.failed);
      expect(stored.isSyncable, isTrue);
    });
  });

  group('doimiy xatolik', () {
    test('needsAttention holatiga o\'tadi va qayta urinilmaydi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final handler = _FakeHandler(
        outcome: const SyncPermanentFailure('validatsiya xatosi: sarlavha bo\'sh'),
      );
      final engine = engineWith([handler]);

      await engine.sync(trigger: SyncTrigger.appStart);
      await engine.sync(trigger: SyncTrigger.appStart);

      expect(handler.performedOperationIds, ['op-1']); // ikkinchi marta urinilmadi
      expect((await queue.getById('op-1'))!.status, PendingOperationStatus.needsAttention);
    });
  });

  group('ziddiyat', () {
    SyncConflict conflict(ConflictKind kind, RecordEditability editability) {
      return SyncConflict(
        operationId: 'op-1',
        entityType: 'appeal',
        entityId: 'appeal-1',
        kind: kind,
        serverEditability: editability,
      );
    }

    test('holat ziddiyatida server yutadi va foydalanuvchiga ko\'rsatiladi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final handler = _FakeHandler(
        outcome: SyncConflictDetected(
          conflict(ConflictKind.status, RecordEditability.locked),
        ),
      );

      await engineWith([handler]).sync(trigger: SyncTrigger.appStart);

      final stored = (await queue.getById('op-1'))!;
      expect(stored.status, PendingOperationStatus.needsAttention);
      expect(stored.lastError, isNotNull); // sabab saqlanadi
    });

    test('mahalliy foydasiga hal qilinsa, amal qayta yuborish uchun qoladi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final handler = _FakeHandler(
        outcome: SyncConflictDetected(
          conflict(ConflictKind.content, RecordEditability.editable),
        ),
      );

      await engineWith([handler]).sync(trigger: SyncTrigger.appStart);

      final stored = (await queue.getById('op-1'))!;
      expect(stored.status, PendingOperationStatus.failed);
      expect(stored.isSyncable, isTrue);
    });
  });

  group('offline holat', () {
    test('tarmoq yo\'q bo\'lsa sikl umuman ishlamaydi va amal saqlanadi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final handler = _FakeHandler();

      final report = await engineWith(
        [handler],
        isOnline: () async => false,
      ).sync(trigger: SyncTrigger.appStart);

      expect(report.skippedOffline, isTrue);
      expect(handler.performedOperationIds, isEmpty);
      expect((await queue.getById('op-1'))!.status, PendingOperationStatus.pending);
    });

    test('offline holat xatolik emas, alohida holat sifatida ko\'rsatiladi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final engine = engineWith([_FakeHandler()], isOnline: () async => false);

      await engine.sync(trigger: SyncTrigger.appStart);

      expect(engine.currentState, isA<SyncPausedOffline>());
      expect((engine.currentState as SyncPausedOffline).pendingCount, 1);
    });
  });

  group('handler topilmasa', () {
    test('amal jimgina yo\'qolmaydi, foydalanuvchi e\'tiboriga chiqadi', () async {
      await queue.enqueue(_operation(id: 'op-1'));

      await engineWith([_RejectingHandler()]).sync(trigger: SyncTrigger.appStart);

      expect((await queue.getById('op-1'))!.status, PendingOperationStatus.needsAttention);
    });
  });

  group('holat oqimi', () {
    test('sikl yakunida SyncCompleted hisobot bilan chiqadi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final engine = engineWith([_FakeHandler()]);

      await engine.sync(trigger: SyncTrigger.appStart);

      expect(engine.currentState, isA<SyncCompleted>());
      expect((engine.currentState as SyncCompleted).succeeded, 1);
    });

    test('holat o\'zgarishlari oqimga uzatiladi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final engine = engineWith([_FakeHandler()]);
      final states = <SyncState>[];
      final subscription = engine.state.listen(states.add);

      await engine.sync(trigger: SyncTrigger.appStart);
      // Broadcast oqim hodisalarni mikrotaskda yetkazadi -- obunani
      // bekor qilishdan oldin navbat bo'shatiladi, aks holda oxirgi
      // hodisa ("yakunlandi") tinglovchiga yetib bormaydi.
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      await engine.dispose();

      expect(states.any((s) => s is SyncInProgress), isTrue);
      expect(states.last, isA<SyncCompleted>());
    });
  });

  group('bog\'liq amallar', () {
    test('bog\'liq amal, bog\'liqligi tugagandan keyingina yuboriladi', () async {
      await queue.enqueue(_operation(id: 'record-op'));
      await queue.enqueue(_operation(id: 'file-op', dependsOn: 'record-op'));
      final handler = _FakeHandler();
      final engine = engineWith([handler]);

      await engine.sync(trigger: SyncTrigger.appStart);

      // Birinchi siklda faqat yozuv yuborildi.
      expect(handler.performedOperationIds, ['record-op']);

      await engine.sync(trigger: SyncTrigger.appStart);

      expect(handler.performedOperationIds, ['record-op', 'file-op']);
    });
  });
}
