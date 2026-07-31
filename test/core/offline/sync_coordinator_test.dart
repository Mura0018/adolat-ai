import 'dart:async';

import 'package:adolat_ai/core/offline/network/in_memory_network_state_monitor.dart';
import 'package:adolat_ai/core/offline/network/network_status.dart';
import 'package:adolat_ai/core/offline/queue/in_memory_offline_queue.dart';
import 'package:adolat_ai/core/offline/queue/pending_operation.dart';
import 'package:adolat_ai/core/offline/sync/sync_coordinator.dart';
import 'package:adolat_ai/core/offline/sync/sync_engine.dart';
import 'package:adolat_ai/core/offline/sync/sync_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Boshqariladigan dvigatel: siklni ataylab "ushlab turish" mumkin,
/// shu bilan sikl DAVOMIDA kelgan signallarni sinash imkoni bo'ladi.
class _ControllableSyncEngine implements SyncEngine {
  final List<SyncTrigger> triggers = <SyncTrigger>[];
  Completer<void>? _gate;

  /// Keyingi `sync()` chaqiruvini `release()` chaqirilguncha ushlab
  /// turadi.
  void hold() => _gate = Completer<void>();

  void release() {
    _gate?.complete();
    _gate = null;
  }

  @override
  SyncState get currentState => const SyncIdle();

  @override
  Stream<SyncState> get state => const Stream<SyncState>.empty();

  @override
  Future<SyncReport> sync({required SyncTrigger trigger}) async {
    triggers.add(trigger);
    final gate = _gate;
    if (gate != null) await gate.future;
    return SyncReport(
      trigger: trigger,
      processed: 1,
      succeeded: 1,
      transientFailures: 0,
      needsAttention: 0,
    );
  }
}

PendingOperation _operation({required String id}) {
  return PendingOperation(
    id: id,
    kind: PendingOperationKind.createRecord,
    entityType: 'appeal',
    entityId: 'appeal-1',
    payload: const {},
    createdAt: DateTime.utc(2026),
  );
}

void main() {
  late _ControllableSyncEngine engine;
  late InMemoryOfflineQueue queue;
  late InMemoryNetworkStateMonitor monitor;
  late SyncCoordinator coordinator;

  setUp(() {
    engine = _ControllableSyncEngine();
    queue = InMemoryOfflineQueue();
    monitor = InMemoryNetworkStateMonitor();
    coordinator = SyncCoordinator(engine: engine, queue: queue, networkMonitor: monitor);
  });

  tearDown(() async {
    await coordinator.dispose();
    await monitor.dispose();
  });

  group('yo\'qolgan signal poygasi (race) — Module 6C', () {
    test('sikl davomida kelgan sabab e\'tiborsiz qolmaydi', () async {
      engine.hold();
      final first = coordinator.run(SyncTrigger.appStart);

      // Sikl ishlayotgan paytda yangi sabab keldi.
      final second = await coordinator.run(SyncTrigger.connectivityRestored);
      expect(second.skippedAlreadyRunning, isTrue);

      engine.release();
      await first;

      // 6A/6B'da bu signal butunlay yo'qolardi.
      expect(engine.triggers, [SyncTrigger.appStart, SyncTrigger.connectivityRestored]);
      expect(coordinator.coalescedRunCount, 1);
    });

    test('bir nechta signal AYNAN bitta qo\'shimcha siklga birlashadi', () async {
      engine.hold();
      final first = coordinator.run(SyncTrigger.appStart);

      await coordinator.run(SyncTrigger.connectivityRestored);
      await coordinator.run(SyncTrigger.appForeground);
      await coordinator.run(SyncTrigger.manual);

      engine.release();
      await first;

      // Uchta signal -> bitta qo'shimcha sikl (ortiqcha yuk yo'q,
      // lekin hech narsa ham yo'qolmaydi).
      expect(engine.triggers, hasLength(2));
      expect(coordinator.coalescedRunCount, 1);
    });

    test('signal kelmasa qo\'shimcha sikl bo\'lmaydi', () async {
      await coordinator.run(SyncTrigger.appStart);

      expect(engine.triggers, hasLength(1));
      expect(coordinator.coalescedRunCount, 0);
    });

    test('ketma-ket chaqiruvlar bir-birini bloklamaydi', () async {
      await coordinator.onAppStart();
      await coordinator.onAppForeground();

      expect(engine.triggers, [SyncTrigger.appStart, SyncTrigger.appForeground]);
      expect(coordinator.coalescedRunCount, 0);
    });
  });

  group('tarmoq tiklanishi', () {
    test('start() dan keyin tarmoq tiklanishi siklni ishga tushiradi', () async {
      final offlineMonitor = InMemoryNetworkStateMonitor(initialStatus: NetworkStatus.offline);
      final localCoordinator = SyncCoordinator(
        engine: engine,
        queue: queue,
        networkMonitor: offlineMonitor,
      );
      localCoordinator.start();

      offlineMonitor.goOnline();
      await Future<void>.delayed(Duration.zero);

      expect(engine.triggers, [SyncTrigger.connectivityRestored]);
      await localCoordinator.dispose();
      await offlineMonitor.dispose();
    });
  });

  group('foydalanuvchi amallari', () {
    test('submit amalni navbatga qo\'yadi', () async {
      await coordinator.submit(_operation(id: 'op-1'));
      await Future<void>.delayed(Duration.zero);

      expect((await queue.getAll()).map((o) => o.id), ['op-1']);
    });

    test('submit tarmoq bo\'lmasa ham xatolik bermaydi', () async {
      monitor.goOffline();

      await expectLater(coordinator.submit(_operation(id: 'op-1')), completes);
      expect(await queue.pendingCount(), 1);
    });

    test('retryOperation bloklangan amalni qaytaradi va sinxronizatsiya boshlaydi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.update((await queue.getById('op-1'))!.markNeedsAttention('xato'));

      await coordinator.retryOperation('op-1');

      expect((await queue.getById('op-1'))!.status, PendingOperationStatus.pending);
      expect(engine.triggers, [SyncTrigger.manual]);
    });

    test('cancelOperation amalni navbatdan o\'chiradi', () async {
      await queue.enqueue(_operation(id: 'op-1'));

      await coordinator.cancelOperation('op-1');

      expect(await queue.getAll(), isEmpty);
    });

    test('operationsNeedingAttention e\'tibor kutayotganlarni beradi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.enqueue(_operation(id: 'op-2'));
      await queue.update((await queue.getById('op-2'))!.markNeedsAttention('xato'));

      expect((await coordinator.operationsNeedingAttention()).map((o) => o.id), ['op-2']);
    });

    test('cleanUpCompleted yakunlanganlarni tozalaydi', () async {
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.update((await queue.getById('op-1'))!.markCompleted());

      expect(await coordinator.cleanUpCompleted(), 1);
      expect(await queue.getAll(), isEmpty);
    });

    test('pendingCount navbat hajmini beradi', () async {
      await queue.enqueue(_operation(id: 'op-1'));

      expect(await coordinator.pendingCount(), 1);
    });
  });
}
