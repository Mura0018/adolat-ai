import 'package:adolat_ai/core/offline/conflict/sync_conflict.dart';
import 'package:adolat_ai/core/offline/network/in_memory_network_state_monitor.dart';
import 'package:adolat_ai/core/offline/network/network_status.dart';
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

  /// Boshqariladigan soat — Module 6B'dan beri dvigatel backoff
  /// kutish oralig'ini HAQIQATAN hurmat qiladi, shuning uchun qayta
  /// urinishni sinash uchun vaqtni oldinga surish kerak.
  late DateTime now;

  setUp(() {
    queue = InMemoryOfflineQueue();
    now = DateTime.utc(2026, 1, 2);
  });

  void advance(Duration duration) => now = now.add(duration);

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
      clock: () => now,
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

    test('backoff kutish oralig\'i o\'tgach qayta uriniladi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final handler = _FakeHandler(outcome: const SyncTransientFailure('uzildi'));
      final engine = engineWith([handler]);

      await engine.sync(trigger: SyncTrigger.appStart);
      handler.outcome = const SyncSuccess();
      advance(const Duration(seconds: 10)); // backoff oralig'i o'tdi
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
      advance(const Duration(minutes: 1));
      await engine.sync(trigger: SyncTrigger.appStart);
      advance(const Duration(minutes: 1));
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

  group('backoff kutish oralig\'i hurmat qilinadi (Module 6B)', () {
    test('kutish oralig\'i o\'tmaguncha amal qayta olinmaydi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final handler = _FakeHandler(outcome: const SyncTransientFailure('uzildi'));
      final engine = engineWith([handler]);

      await engine.sync(trigger: SyncTrigger.appStart);
      // Vaqt surilmadi -- backoff oralig'i hali o'tmagan.
      await engine.sync(trigger: SyncTrigger.appStart);

      expect(handler.performedOperationIds, ['op-1']);
    });

    test('kutish oralig\'i har urinishda ortadi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final handler = _FakeHandler(outcome: const SyncTransientFailure('uzildi'));
      final engine = engineWith([handler]);

      await engine.sync(trigger: SyncTrigger.appStart); // 1-urinish
      advance(const Duration(seconds: 5));
      await engine.sync(trigger: SyncTrigger.appStart); // 2-urinish (5s dan keyin)
      advance(const Duration(seconds: 5));
      // Endi 10s kerak -- 5s yetmaydi.
      await engine.sync(trigger: SyncTrigger.appStart);

      expect(handler.performedOperationIds, hasLength(2));
    });

    test('tayyor bo\'lmagan amal navbatdagi o\'rnini yo\'qotmaydi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.enqueue(_operation(id: 'op-2'));
      final handler = _FakeHandler(outcome: const SyncTransientFailure('uzildi'));
      final engine = engineWith([handler]);

      await engine.sync(trigger: SyncTrigger.appStart);
      handler.outcome = const SyncSuccess();
      advance(const Duration(minutes: 1));
      await engine.sync(trigger: SyncTrigger.appStart);

      // FIFO saqlanadi: op-1 baribir op-2 dan oldin.
      expect(handler.performedOperationIds, ['op-1', 'op-2', 'op-1', 'op-2']);
    });
  });

  group('sikl o\'rtasida tarmoq uzilishi (Module 6B)', () {
    test('qolgan amallar yuborilmaydi va navbatda saqlanadi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.enqueue(_operation(id: 'op-2'));

      final handler = _FakeHandler();
      final engine = QueuedSyncEngine(
        queue: queue,
        handlers: [handler],
        clock: () => now,
        // Tarmoq BIRINCHI amaldan keyin uziladi.
        isOnline: () async => handler.performedOperationIds.isEmpty,
      );

      final report = await engine.sync(trigger: SyncTrigger.appStart);

      expect(report.interruptedByOffline, isTrue);
      expect(handler.performedOperationIds, ['op-1']);
      // op-2 hech qachon boshlanmagani uchun pending holida qoladi.
      expect((await queue.getById('op-2'))!.status, PendingOperationStatus.pending);
    });

    test('uzilgan sikl SyncPausedOffline holatini beradi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.enqueue(_operation(id: 'op-2'));

      final handler = _FakeHandler();
      final engine = QueuedSyncEngine(
        queue: queue,
        handlers: [handler],
        clock: () => now,
        isOnline: () async => handler.performedOperationIds.isEmpty,
      );

      await engine.sync(trigger: SyncTrigger.appStart);

      expect(engine.currentState, isA<SyncPausedOffline>());
    });
  });

  group('uzilib qolgan amallarni tiklash (Module 6B)', () {
    test('inProgress da osilib qolgan amal qayta urinishga qaytariladi', () async {
      // Ilova sinxronizatsiya o'rtasida o'chib qolgan holatni
      // taqlid qiladi.
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.update(
        (await queue.getById('op-1'))!.markInProgress(at: DateTime.utc(2026)),
      );
      expect((await queue.getById('op-1'))!.isSyncable, isFalse);

      final handler = _FakeHandler();
      advance(const Duration(hours: 1));
      await engineWith([handler]).sync(trigger: SyncTrigger.appStart);

      // Bularsiz amal MANGU inProgress da qolib ketardi.
      expect(handler.performedOperationIds, ['op-1']);
      expect((await queue.getById('op-1'))!.status, PendingOperationStatus.completed);
    });

    test('tiklangan amalning idempotentlik kaliti o\'zgarmaydi', () async {
      await queue.enqueue(_operation(id: 'stable-key'));
      await queue.update(
        (await queue.getById('stable-key'))!.markInProgress(at: DateTime.utc(2026)),
      );

      advance(const Duration(hours: 1));
      await engineWith([_FakeHandler()]).sync(trigger: SyncTrigger.appStart);

      expect((await queue.getById('stable-key'))!.id, 'stable-key');
    });
  });

  group('NetworkStateMonitor bilan ishlash (Module 6B)', () {
    test('monitor oflayn bo\'lsa sikl boshlanmaydi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final monitor = InMemoryNetworkStateMonitor(initialStatus: NetworkStatus.offline);
      final handler = _FakeHandler();
      final engine = QueuedSyncEngine(
        queue: queue,
        handlers: [handler],
        networkMonitor: monitor,
        clock: () => now,
      );

      final report = await engine.sync(trigger: SyncTrigger.appStart);

      expect(report.skippedOffline, isTrue);
      expect(handler.performedOperationIds, isEmpty);
      await monitor.dispose();
    });

    test('monitor onlayn bo\'lsa sikl normal ishlaydi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final monitor = InMemoryNetworkStateMonitor();
      final handler = _FakeHandler();
      final engine = QueuedSyncEngine(
        queue: queue,
        handlers: [handler],
        networkMonitor: monitor,
        clock: () => now,
      );

      await engine.sync(trigger: SyncTrigger.appStart);

      expect(handler.performedOperationIds, ['op-1']);
      await monitor.dispose();
    });
  });

  group('bloklangan amalga bog\'liqlar kaskadi (Module 6C)', () {
    test('ota-amal needsAttention bo\'lsa, bog\'liq amal ham chiqariladi', () async {
      await queue.enqueue(_operation(id: 'record-op'));
      await queue.enqueue(_operation(id: 'file-op', dependsOn: 'record-op'));

      await engineWith([
        _FakeHandler(outcome: const SyncPermanentFailure('validatsiya xatosi')),
      ]).sync(trigger: SyncTrigger.appStart);

      // Bularsiz `file-op` MANGU pending holida navbatda qolib,
      // hech qayerda ko'rinmasdi.
      final dependent = (await queue.getById('file-op'))!;
      expect(dependent.status, PendingOperationStatus.needsAttention);
      expect(dependent.lastError, isNotNull);
    });

    test('kaskad butun zanjir bo\'ylab ishlaydi (A -> B -> C)', () async {
      await queue.enqueue(_operation(id: 'a'));
      await queue.enqueue(_operation(id: 'b', dependsOn: 'a'));
      await queue.enqueue(_operation(id: 'c', dependsOn: 'b'));

      await engineWith([
        _FakeHandler(outcome: const SyncPermanentFailure('xato')),
      ]).sync(trigger: SyncTrigger.appStart);

      expect((await queue.getById('b'))!.status, PendingOperationStatus.needsAttention);
      expect((await queue.getById('c'))!.status, PendingOperationStatus.needsAttention);
    });

    test('muvaffaqiyatli ota-amal bog\'liqlarni bloklamaydi', () async {
      await queue.enqueue(_operation(id: 'record-op'));
      await queue.enqueue(_operation(id: 'file-op', dependsOn: 'record-op'));

      await engineWith([_FakeHandler()]).sync(trigger: SyncTrigger.appStart);

      expect((await queue.getById('file-op'))!.status, PendingOperationStatus.pending);
    });

    test('vaqtinchalik xatolik bog\'liqlarni bloklamaydi', () async {
      // Faqat DOIMIY to'siq kaskadga sabab bo'ladi -- vaqtinchalik
      // xatolikda ota-amal baribir qayta uriniladi.
      await queue.enqueue(_operation(id: 'record-op'));
      await queue.enqueue(_operation(id: 'file-op', dependsOn: 'record-op'));

      await engineWith([
        _FakeHandler(outcome: const SyncTransientFailure('tarmoq')),
      ]).sync(trigger: SyncTrigger.appStart);

      expect((await queue.getById('file-op'))!.status, PendingOperationStatus.pending);
    });

    test('foydalanuvchi retryNow bilan zanjirni qayta ishga tushira oladi', () async {
      await queue.enqueue(_operation(id: 'record-op'));
      await queue.enqueue(_operation(id: 'file-op', dependsOn: 'record-op'));
      final handler = _FakeHandler(outcome: const SyncPermanentFailure('xato'));
      final engine = engineWith([handler]);
      await engine.sync(trigger: SyncTrigger.appStart);

      // Foydalanuvchi muammoni tuzatdi va ikkalasini qayta yubordi.
      await queue.retryNow('record-op');
      await queue.retryNow('file-op');
      handler.outcome = const SyncSuccess();
      advance(const Duration(minutes: 1));
      await engine.sync(trigger: SyncTrigger.manual);
      await engine.sync(trigger: SyncTrigger.manual);

      expect((await queue.getById('record-op'))!.status, PendingOperationStatus.completed);
      expect((await queue.getById('file-op'))!.status, PendingOperationStatus.completed);
    });
  });

  group('takroriy sikl (race) — Module 6C', () {
    test('band dvigatel aniq belgi bilan javob qaytaradi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final engine = engineWith([_FakeHandler()]);

      // Sikl ichida ikkinchi chaqiruv (handler orqali taqlid qilish
      // o'rniga to'g'ridan-to'g'ri tekshiramiz): birinchi sikl
      // tugagach `_isRunning` false bo'ladi, shuning uchun bu yerda
      // faqat bayroqning MAVJUDLIGI va standart qiymati tekshiriladi.
      final report = await engine.sync(trigger: SyncTrigger.appStart);

      expect(report.skippedAlreadyRunning, isFalse);
      expect(report.didNotRun, isFalse);
    });

    test('bir vaqtda ikkita sikl ishlamaydi va amal ikki marta yuborilmaydi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      final handler = _FakeHandler();
      final engine = engineWith([handler]);

      // Ikkala chaqiruv bir vaqtda boshlanadi.
      final results = await Future.wait([
        engine.sync(trigger: SyncTrigger.appStart),
        engine.sync(trigger: SyncTrigger.manual),
      ]);

      // Amal ATIGI bir marta yuborilgan.
      expect(handler.performedOperationIds, ['op-1']);
      expect(results.where((r) => r.skippedAlreadyRunning), hasLength(1));
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
