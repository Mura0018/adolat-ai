import 'package:adolat_ai/core/offline/network/in_memory_network_state_monitor.dart';
import 'package:adolat_ai/core/offline/network/network_status.dart';
import 'package:adolat_ai/core/offline/sync/sync_engine.dart';
import 'package:adolat_ai/core/offline/sync/sync_scheduler.dart';
import 'package:adolat_ai/core/offline/sync/sync_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Rejalashtiruvchi qaysi SABAB bilan sinxronizatsiya chaqirganini
/// yozib boruvchi soxta dvigatel.
class _RecordingSyncEngine implements SyncEngine {
  final List<SyncTrigger> triggers = <SyncTrigger>[];
  bool throwOnSync = false;

  @override
  SyncState get currentState => const SyncIdle();

  @override
  Stream<SyncState> get state => const Stream<SyncState>.empty();

  @override
  Future<SyncReport> sync({required SyncTrigger trigger}) async {
    triggers.add(trigger);
    if (throwOnSync) throw StateError('dvigatel yiqildi');
    return SyncReport(
      trigger: trigger,
      processed: 1,
      succeeded: 1,
      transientFailures: 0,
      needsAttention: 0,
    );
  }
}

void main() {
  late _RecordingSyncEngine engine;
  late InMemoryNetworkStateMonitor monitor;
  late SyncScheduler scheduler;

  setUp(() {
    engine = _RecordingSyncEngine();
    monitor = InMemoryNetworkStateMonitor(initialStatus: NetworkStatus.offline);
    scheduler = SyncScheduler(engine: engine, networkMonitor: monitor);
  });

  tearDown(() async {
    await scheduler.dispose();
    await monitor.dispose();
  });

  group('tarmoq tiklanishi', () {
    test('oflayn -> onlayn o\'tishida sinxronizatsiya avtomatik ishga tushadi', () async {
      scheduler.start();

      monitor.goOnline();
      await Future<void>.delayed(Duration.zero);

      expect(engine.triggers, [SyncTrigger.connectivityRestored]);
      expect(scheduler.connectivityTriggeredSyncCount, 1);
    });

    test('onlayn -> oflayn o\'tishida sinxronizatsiya ishga TUSHMAYDI', () async {
      final onlineMonitor = InMemoryNetworkStateMonitor();
      final onlineScheduler = SyncScheduler(engine: engine, networkMonitor: onlineMonitor);
      onlineScheduler.start();

      onlineMonitor.goOffline();
      await Future<void>.delayed(Duration.zero);

      expect(engine.triggers, isEmpty);
      await onlineScheduler.dispose();
      await onlineMonitor.dispose();
    });

    test('takroriy onlayn signali qo\'shimcha sikl boshlamaydi', () async {
      scheduler.start();

      monitor.goOnline();
      monitor.goOnline(); // takroriy -- monitor uni yutadi
      await Future<void>.delayed(Duration.zero);

      expect(engine.triggers, hasLength(1));
    });

    test('har bir uzilish-tiklanish sikli yangi sinxronizatsiya beradi', () async {
      scheduler.start();

      monitor.goOnline();
      monitor.goOffline();
      monitor.goOnline();
      await Future<void>.delayed(Duration.zero);

      expect(engine.triggers, [
        SyncTrigger.connectivityRestored,
        SyncTrigger.connectivityRestored,
      ]);
    });

    test('start() chaqirilmaguncha tarmoq o\'zgarishi e\'tiborsiz qoladi', () async {
      monitor.goOnline();
      await Future<void>.delayed(Duration.zero);

      expect(engine.triggers, isEmpty);
    });

    test('start() ikki marta chaqirilsa ham bitta obuna bo\'ladi', () async {
      scheduler.start();
      scheduler.start();

      monitor.goOnline();
      await Future<void>.delayed(Duration.zero);

      // Ikkita obuna bo'lsa, bitta o'zgarish ikkita siklga sabab
      // bo'lardi.
      expect(engine.triggers, hasLength(1));
      expect(scheduler.isListening, isTrue);
    });

    test('dispose() dan keyin tarmoq o\'zgarishi sinxronizatsiya chaqirmaydi', () async {
      scheduler.start();
      await scheduler.dispose();

      monitor.goOnline();
      await Future<void>.delayed(Duration.zero);

      expect(engine.triggers, isEmpty);
      expect(scheduler.isListening, isFalse);
    });
  });

  group('ilova hayot davri sabablari', () {
    test('onAppStart appStart sababi bilan chaqiradi', () async {
      await scheduler.onAppStart();

      expect(engine.triggers, [SyncTrigger.appStart]);
    });

    test('onAppForeground appForeground sababi bilan chaqiradi', () async {
      await scheduler.onAppForeground();

      expect(engine.triggers, [SyncTrigger.appForeground]);
    });

    test('syncNow manual sababi bilan chaqiradi', () async {
      await scheduler.syncNow();

      expect(engine.triggers, [SyncTrigger.manual]);
    });

    test('ilova ochilganda navbat tarmoq signalisiz ham tekshiriladi', () async {
      // "Fon rejimidagi cheklovlar" talabi: platforma fon ishini
      // to'xtatgan bo'lsa ham, ilova ochilganda navbat ALBATTA
      // qayta tekshiriladi.
      await scheduler.onAppStart();

      expect(engine.triggers, isNotEmpty);
    });
  });

  group('xatolikka chidamlilik', () {
    test('dvigatel exception tashlasa, rejalashtiruvchi uni yutadi', () async {
      engine.throwOnSync = true;

      // Hodisa tinglovchisidan tashlangan xatolik ilova darajasidagi
      // ushlanmagan xatolikka aylanardi.
      await expectLater(scheduler.onAppStart(), completes);
    });

    test('tarmoq tiklanganda dvigatel yiqilsa ham oqim buzilmaydi', () async {
      engine.throwOnSync = true;
      scheduler.start();

      monitor.goOnline();
      await Future<void>.delayed(Duration.zero);
      engine.throwOnSync = false;
      monitor.goOffline();
      monitor.goOnline();
      await Future<void>.delayed(Duration.zero);

      // Birinchi urinish yiqildi, lekin obuna tirik qoldi.
      expect(engine.triggers, hasLength(2));
    });
  });
}
