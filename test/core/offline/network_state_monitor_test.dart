import 'package:adolat_ai/core/offline/network/in_memory_network_state_monitor.dart';
import 'package:adolat_ai/core/offline/network/network_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkStatusChange', () {
    test('isRestored faqat oflayn -> onlayn o\'tishida true', () {
      const restored = NetworkStatusChange(
        previous: NetworkStatus.offline,
        current: NetworkStatus.online,
      );

      expect(restored.isRestored, isTrue);
      expect(restored.isLost, isFalse);
      expect(restored.isChanged, isTrue);
    });

    test('isLost faqat onlayn -> oflayn o\'tishida true', () {
      const lost = NetworkStatusChange(
        previous: NetworkStatus.online,
        current: NetworkStatus.offline,
      );

      expect(lost.isLost, isTrue);
      expect(lost.isRestored, isFalse);
    });

    test('bir xil holat o\'zgarish hisoblanmaydi', () {
      const same = NetworkStatusChange(
        previous: NetworkStatus.online,
        current: NetworkStatus.online,
      );

      expect(same.isChanged, isFalse);
      expect(same.isRestored, isFalse);
      expect(same.isLost, isFalse);
    });
  });

  group('NetworkStatus', () {
    test('faqat ikkita holat bor — texnik tafsilot modellashtirilmagan', () {
      // Hujjat: qurilma ulanmagani ham, backend'ga yetib bo'lmagani
      // ham ilova uchun BIR XIL xatti-harakat.
      expect(NetworkStatus.values, hasLength(2));
      expect(NetworkStatus.online.isOnline, isTrue);
      expect(NetworkStatus.offline.isOffline, isTrue);
    });
  });

  group('InMemoryNetworkStateMonitor', () {
    test('boshlang\'ich holat berilganidek bo\'ladi', () {
      final monitor = InMemoryNetworkStateMonitor(initialStatus: NetworkStatus.offline);

      expect(monitor.currentStatus, NetworkStatus.offline);
    });

    test('holat o\'zgarishi oqimga chiqadi', () async {
      final monitor = InMemoryNetworkStateMonitor(initialStatus: NetworkStatus.offline);
      final changes = <NetworkStatusChange>[];
      final subscription = monitor.changes.listen(changes.add);

      monitor.goOnline();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      await monitor.dispose();

      expect(changes, hasLength(1));
      expect(changes.single.isRestored, isTrue);
    });

    test('TAKRORIY holat signali oqimga chiqmaydi', () async {
      // Aks holda har bir platforma signali keraksiz sinxronizatsiya
      // sikliga sabab bo'lardi.
      final monitor = InMemoryNetworkStateMonitor();
      final changes = <NetworkStatusChange>[];
      final subscription = monitor.changes.listen(changes.add);

      monitor.goOnline(); // allaqachon onlayn
      monitor.goOnline();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      await monitor.dispose();

      expect(changes, isEmpty);
    });

    test('ketma-ket uzilish va tiklanish ikkita o\'zgarish beradi', () async {
      final monitor = InMemoryNetworkStateMonitor();
      final changes = <NetworkStatusChange>[];
      final subscription = monitor.changes.listen(changes.add);

      monitor.goOffline();
      monitor.goOnline();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();
      await monitor.dispose();

      expect(changes.map((c) => c.isLost), [true, false]);
      expect(changes.map((c) => c.isRestored), [false, true]);
    });

    test('refresh joriy holatni qaytaradi', () async {
      final monitor = InMemoryNetworkStateMonitor(initialStatus: NetworkStatus.offline);

      expect(await monitor.refresh(), NetworkStatus.offline);

      monitor.goOnline();

      expect(await monitor.refresh(), NetworkStatus.online);
      await monitor.dispose();
    });

    test('bir nechta tinglovchi qo\'llab-quvvatlanadi (broadcast)', () async {
      final monitor = InMemoryNetworkStateMonitor();
      final first = <NetworkStatusChange>[];
      final second = <NetworkStatusChange>[];
      final s1 = monitor.changes.listen(first.add);
      final s2 = monitor.changes.listen(second.add);

      monitor.goOffline();
      await Future<void>.delayed(Duration.zero);
      await s1.cancel();
      await s2.cancel();
      await monitor.dispose();

      expect(first, hasLength(1));
      expect(second, hasLength(1));
    });
  });
}
