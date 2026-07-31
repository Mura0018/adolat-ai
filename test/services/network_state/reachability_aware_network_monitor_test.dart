import 'dart:async';

import 'package:adolat_ai/core/offline/network/network_status.dart';
import 'package:adolat_ai/services/network_state/connectivity_source.dart';
import 'package:adolat_ai/services/network_state/reachability_aware_network_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// Boshqariladigan interfeys manbai — `connectivity_plus` o'rnini
/// bosadi, shu bilan butun birlashtirish mantiqi sof Dart testlarida
/// (emulatorsiz CI'da) qoplanadi.
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

void main() {
  late _FakeConnectivitySource source;
  late ReachabilityAwareNetworkMonitor monitor;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  tearDown(() async {
    await monitor.dispose();
    await source.dispose();
  });

  ReachabilityAwareNetworkMonitor build({bool up = true, int threshold = 2}) {
    source = _FakeConnectivitySource(up: up);
    monitor = ReachabilityAwareNetworkMonitor(
      connectivitySource: source,
      initiallyInterfaceUp: up,
      unreachableAfterConsecutiveFailures: threshold,
    );
    return monitor;
  }

  group('birlashtirish qoidasi: interfeys VA yetish', () {
    test('interfeys ko\'tarilgan va yetib bo\'ladi -> onlayn', () async {
      final m = build();
      await m.start();

      expect(m.currentStatus, NetworkStatus.online);
    });

    test('interfeys tushgan -> oflayn (yetish holatidan qat\'i nazar)', () async {
      final m = build(up: false);
      await m.start();

      expect(m.currentStatus, NetworkStatus.offline);
    });

    test('interfeys ko\'tarilgan, lekin yetib bo\'lmaydi -> OFLAYN', () async {
      // ADR-008 ning markaziy holati: portal ortidagi Wi-Fi.
      final m = build(threshold: 1);
      await m.start();

      m.reportTransientFailure();

      expect(m.currentStatus, NetworkStatus.offline);
    });
  });

  group('yetish (haqiqat manbai)', () {
    test('bitta xatolik chegaraga yetmasa holat o\'zgarmaydi', () async {
      final m = build(threshold: 2);
      await m.start();

      m.reportTransientFailure();

      // Bitta 503 tarmoq uzilganini bildirmaydi.
      expect(m.currentStatus, NetworkStatus.online);
    });

    test('ketma-ket ikkita xatolik oflaynga o\'tkazadi', () async {
      final m = build(threshold: 2);
      await m.start();

      m.reportTransientFailure();
      m.reportTransientFailure();

      expect(m.currentStatus, NetworkStatus.offline);
    });

    test('muvaffaqiyat hisobni nolga qaytaradi', () async {
      final m = build(threshold: 2);
      await m.start();

      m.reportTransientFailure();
      m.reportReachable();
      m.reportTransientFailure();

      // Hisob nollangani uchun bu yana "birinchi" xatolik.
      expect(m.currentStatus, NetworkStatus.online);
    });

    test('muvaffaqiyat oflayndan onlaynga qaytaradi', () async {
      final m = build(threshold: 1);
      await m.start();
      m.reportTransientFailure();

      m.reportReachable();

      expect(m.currentStatus, NetworkStatus.online);
    });
  });

  group('interfeys o\'zgarishlari', () {
    test('interfeys tushsa oflayn bo\'ladi', () async {
      final m = build();
      await m.start();

      source.emit(false);
      await settle();

      expect(m.currentStatus, NetworkStatus.offline);
    });

    test('interfeys qaytganda yetish holati QAYTA TIKLANADI', () async {
      // Eski tarmoqda yetib bo'lmagani yangi tarmoqqa taalluqli emas.
      // Aks holda ilova bir marta muvaffaqiyatsizlikdan keyin abadiy
      // oflayn bo'lib qolardi.
      final m = build(threshold: 1);
      await m.start();
      m.reportTransientFailure();
      expect(m.currentStatus, NetworkStatus.offline);

      source.emit(false);
      await settle();
      source.emit(true);
      await settle();

      expect(m.currentStatus, NetworkStatus.online);
    });
  });

  group('o\'zgarish oqimi', () {
    test('faqat HAQIQIY o\'tishlar xabar qilinadi', () async {
      final m = build(threshold: 1);
      await m.start();
      final changes = <NetworkStatusChange>[];
      final sub = m.changes.listen(changes.add);

      m.reportReachable(); // allaqachon onlayn -- o'zgarish yo'q
      m.reportTransientFailure(); // onlayn -> oflayn
      m.reportTransientFailure(); // allaqachon oflayn -- o'zgarish yo'q
      m.reportReachable(); // oflayn -> onlayn
      await settle();
      await sub.cancel();

      expect(changes.map((c) => c.current), [
        NetworkStatus.offline,
        NetworkStatus.online,
      ]);
    });

    test('tiklanish (isRestored) sinxronizatsiya uchun to\'g\'ri belgilanadi', () async {
      final m = build(threshold: 1);
      await m.start();
      m.reportTransientFailure();
      final changes = <NetworkStatusChange>[];
      final sub = m.changes.listen(changes.add);

      m.reportReachable();
      await settle();
      await sub.cancel();

      expect(changes.single.isRestored, isTrue);
    });
  });

  group('refresh', () {
    test('interfeys holatini qayta o\'qiydi', () async {
      final m = build();
      await m.start();

      source.emit(false);
      await settle();

      expect(await m.refresh(), NetworkStatus.offline);
    });
  });

  group('start()', () {
    test('ikki marta chaqirilsa ikkinchi obuna yaratilmaydi', () async {
      final m = build();
      await m.start();
      await m.start();
      final changes = <NetworkStatusChange>[];
      final sub = m.changes.listen(changes.add);

      source.emit(false);
      await settle();
      await sub.cancel();

      expect(changes, hasLength(1));
    });
  });
}
