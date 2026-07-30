import 'dart:async';

import 'network_state_monitor.dart';
import 'network_status.dart';

/// `NetworkStateMonitor`ning boshqariladigan POYDEVOR
/// implementatsiyasi.
///
/// Haqiqiy platforma signaliga ULANMAGAN — holat faqat [setStatus]
/// orqali dasturiy tarzda o'zgartiriladi. Ikki maqsadi bor:
///
/// 1. **Testlar** — tarmoq uzilishi/tiklanishini aniq boshqarish
///    (haqiqiy tarmoq bilan buni ishonchli takrorlab bo'lmaydi);
/// 2. **Vaqtinchalik ishlash** — platforma paketi tanlanmaguncha
///    ilova butun oqimni (navbat → rejalashtiruvchi → dvigatel)
///    to'liq yig'a oladi, faqat holat manbai "qo'lda" bo'ladi.
///
/// `InMemoryLocalStore`/`InMemoryOfflineQueue` (6A) bilan bir xil
/// naqsh va bir xil ochiq cheklov.
class InMemoryNetworkStateMonitor implements NetworkStateMonitor {
  InMemoryNetworkStateMonitor({NetworkStatus initialStatus = NetworkStatus.online})
    : _status = initialStatus;

  NetworkStatus _status;

  final StreamController<NetworkStatusChange> _controller =
      StreamController<NetworkStatusChange>.broadcast();

  @override
  NetworkStatus get currentStatus => _status;

  @override
  Stream<NetworkStatusChange> get changes => _controller.stream;

  @override
  Future<NetworkStatus> refresh() async => _status;

  /// Holatni o'zgartiradi va (faqat HAQIQIY o'zgarish bo'lsa)
  /// oqimga xabar beradi.
  void setStatus(NetworkStatus next) {
    if (next == _status) {
      // Takroriy signal yuborilmaydi -- shartnoma talabi.
      return;
    }

    final change = NetworkStatusChange(previous: _status, current: next);
    _status = next;

    if (!_controller.isClosed) {
      _controller.add(change);
    }
  }

  void goOffline() => setStatus(NetworkStatus.offline);

  void goOnline() => setStatus(NetworkStatus.online);

  Future<void> dispose() => _controller.close();
}
