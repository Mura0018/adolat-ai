import 'dart:async';

import 'package:adolat_ai/core/offline/network/network_status.dart';
import 'package:adolat_ai/core/offline/queue/local_store_offline_queue.dart';
import 'package:adolat_ai/core/offline/queue/offline_queue.dart';
import 'package:adolat_ai/core/offline/queue/pending_operation.dart';
import 'package:adolat_ai/core/offline/sync/queued_sync_engine.dart';
import 'package:adolat_ai/core/offline/sync/sync_coordinator.dart';
import 'package:adolat_ai/core/offline/sync/sync_engine.dart';
import 'package:adolat_ai/core/offline/sync/sync_operation_outcome.dart';
import 'package:adolat_ai/services/local_database/app_local_database.dart';
import 'package:adolat_ai/services/local_database/drift_local_store.dart';
import 'package:adolat_ai/services/network_state/connectivity_source.dart';
import 'package:adolat_ai/services/network_state/reachability_aware_network_monitor.dart';
import 'package:adolat_ai/services/network_state/reachability_reporting_sync_handler.dart';
import 'package:flutter_test/flutter_test.dart';

/// **Integration testi (Module 7B):** ADR-008ning ikki manbali modeli
/// haqiqiy stek bilan — Drift saqlash (7A), navbat, dvigatel,
/// koordinator va tarmoq monitori birgalikda.
///
/// Bu yerda tekshiriladigan asosiy narsa — **manbalar bir-biri bilan
/// to'g'ri ishlashi**: so'rov natijasi monitorga yetib boradimi,
/// monitor holati dvigatelni to'xtatadimi, interfeys qaytishi
/// sinxronizatsiyani ishga tushiradimi.
class _FakeConnectivitySource implements ConnectivitySource {
  _FakeConnectivitySource({bool up = true}) : _up = up;

  bool _up;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  Future<bool> isInterfaceUp() async => _up;

  @override
  Stream<bool> get interfaceChanges => _controller.stream;

  void emit(bool up) {
    _up = up;
    _controller.add(up);
  }

  Future<void> dispose() => _controller.close();
}

class _ScriptedHandler implements SyncOperationHandler {
  /// Testlar natijani yaratgandan KEYIN o'rnatadi (`inner.outcome = ...`).
  SyncOperationOutcome outcome = const SyncSuccess();
  final List<String> performed = <String>[];

  @override
  bool canHandle(PendingOperation operation) => true;

  @override
  Future<SyncOperationOutcome> perform(PendingOperation operation) async {
    performed.add(operation.id);
    return outcome;
  }
}

PendingOperation _operation({required String id, String entityId = 'appeal-1'}) {
  return PendingOperation(
    id: id,
    kind: PendingOperationKind.createRecord,
    entityType: 'appeal',
    entityId: entityId,
    payload: const {'title': 'Sinov murojaati'},
    createdAt: DateTime.utc(2026, 1, 1),
  );
}

void main() {
  late AppLocalDatabase db;
  late OfflineQueue queue;
  late _FakeConnectivitySource source;
  late ReachabilityAwareNetworkMonitor monitor;
  late _ScriptedHandler inner;
  late QueuedSyncEngine engine;

  /// Boshqariladigan soat -- dvigatel backoff kutish oralig'ini
  /// hurmat qiladi (Module 6B), shuning uchun qayta urinishni sinash
  /// uchun vaqtni oldinga surish kerak.
  late DateTime now;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<void> build({bool interfaceUp = true, int threshold = 1}) async {
    now = DateTime.utc(2026, 1, 2);
    db = AppLocalDatabase.memory();
    queue = LocalStoreOfflineQueue(DriftLocalStore(db, 'pending_operations'));
    source = _FakeConnectivitySource(up: interfaceUp);
    monitor = ReachabilityAwareNetworkMonitor(
      connectivitySource: source,
      initiallyInterfaceUp: interfaceUp,
      unreachableAfterConsecutiveFailures: threshold,
    );
    await monitor.start();
    inner = _ScriptedHandler();
    engine = QueuedSyncEngine(
      queue: queue,
      handlers: [ReachabilityReportingSyncHandler(inner: inner, monitor: monitor)],
      networkMonitor: monitor,
      clock: () => now,
    );
  }

  tearDown(() async {
    await engine.dispose();
    await monitor.dispose();
    await source.dispose();
    await db.close();
  });

  group('tarmoq holati dvigatelga ta\'sir qiladi', () {
    test('interfeys tushgan bo\'lsa sikl umuman boshlanmaydi', () async {
      await build(interfaceUp: false);
      await queue.enqueue(_operation(id: 'op-1'));

      final report = await engine.sync(trigger: SyncTrigger.appStart);

      expect(report.skippedOffline, isTrue);
      expect(inner.performed, isEmpty);
      // Ish yo'qolmadi.
      expect((await queue.getById('op-1'))!.status, PendingOperationStatus.pending);
    });

    test('onlayn holatda sikl normal ishlaydi', () async {
      await build();
      await queue.enqueue(_operation(id: 'op-1'));

      await engine.sync(trigger: SyncTrigger.appStart);

      expect(inner.performed, ['op-1']);
      expect((await queue.getById('op-1'))!.status, PendingOperationStatus.completed);
    });
  });

  group('so\'rov natijasi haqiqat manbai sifatida', () {
    test('vaqtinchalik xatolik monitorni oflaynga o\'tkazadi', () async {
      await build(threshold: 1);
      await queue.enqueue(_operation(id: 'op-1'));
      inner.outcome = const SyncTransientFailure('tarmoq uzildi');

      await engine.sync(trigger: SyncTrigger.appStart);

      // Interfeys hamon "ko'tarilgan", lekin backend'ga yetib
      // bo'lmadi -- ADR-008 ning markaziy holati.
      expect(await source.isInterfaceUp(), isTrue);
      expect(monitor.currentStatus, NetworkStatus.offline);
    });

    test('oflaynga o\'tgach keyingi sikl to\'xtatiladi (ish saqlanadi)', () async {
      await build(threshold: 1);
      await queue.enqueue(_operation(id: 'op-1'));
      await queue.enqueue(_operation(id: 'op-2', entityId: 'appeal-2'));
      inner.outcome = const SyncTransientFailure('uzildi');

      await engine.sync(trigger: SyncTrigger.appStart);
      final report = await engine.sync(trigger: SyncTrigger.appStart);

      expect(report.skippedOffline, isTrue);
      expect((await queue.getById('op-2'))!.status, PendingOperationStatus.pending);
    });

    test('DOIMIY xatolik tarmoqni oflayn deb belgilamaydi', () async {
      // Server javob berdi (rad etdi) -- demak yetib bo'ladi.
      await build(threshold: 1);
      await queue.enqueue(_operation(id: 'op-1'));
      inner.outcome = const SyncPermanentFailure('validatsiya xatosi');

      await engine.sync(trigger: SyncTrigger.appStart);

      expect(monitor.currentStatus, NetworkStatus.online);
    });

    test('muvaffaqiyat oflayndan qaytaradi', () async {
      await build(threshold: 1);
      await queue.enqueue(_operation(id: 'op-1'));
      inner.outcome = const SyncTransientFailure('uzildi');
      await engine.sync(trigger: SyncTrigger.appStart);
      expect(monitor.currentStatus, NetworkStatus.offline);

      // Interfeys qaytdi -> yetish holati tiklanadi.
      source.emit(false);
      await settle();
      source.emit(true);
      await settle();
      inner.outcome = const SyncSuccess();
      now = now.add(const Duration(minutes: 1)); // backoff oralig'i o'tdi
      await engine.sync(trigger: SyncTrigger.appStart);

      expect(monitor.currentStatus, NetworkStatus.online);
      expect((await queue.getById('op-1'))!.status, PendingOperationStatus.completed);
    });
  });

  group('koordinator bilan to\'liq oqim', () {
    test('tarmoq tiklanishi navbatni avtomatik yuboradi', () async {
      await build(interfaceUp: false);
      final coordinator = SyncCoordinator(
        engine: engine,
        queue: queue,
        networkMonitor: monitor,
      );
      coordinator.start();

      // Foydalanuvchi oflaynda murojaat yaratdi.
      await coordinator.submit(_operation(id: 'op-1'));
      await settle();
      expect(inner.performed, isEmpty);

      // Internet qaytdi -- hech kim tugma bosmaydi.
      source.emit(true);
      await settle();
      await settle();

      expect(inner.performed, ['op-1']);
      expect((await queue.getById('op-1'))!.status, PendingOperationStatus.completed);
      await coordinator.dispose();
    });

    test('oflaynda yuborilgan ish Drift bazasida saqlanib qoladi', () async {
      await build(interfaceUp: false);
      final coordinator = SyncCoordinator(
        engine: engine,
        queue: queue,
        networkMonitor: monitor,
      );

      await coordinator.submit(_operation(id: 'op-1'));
      await settle();

      // "Ilova qayta ochildi" -- yangi navbat obyekti, bir xil baza.
      final reopened = LocalStoreOfflineQueue(DriftLocalStore(db, 'pending_operations'));

      expect((await reopened.getAll()).map((o) => o.id), ['op-1']);
      await coordinator.dispose();
    });
  });
}
