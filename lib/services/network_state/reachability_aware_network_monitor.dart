import 'dart:async';

import '../../core/offline/network/network_state_monitor.dart';
import '../../core/offline/network/network_status.dart';
import 'connectivity_source.dart';

/// `NetworkStateMonitor`ning IKKI MANBALI implementatsiyasi —
/// `docs/adr/ADR-008-network-signal-source.md` (Qabul qilingan
/// 2026-07-31) qarorining amalga oshirilishi.
///
/// | Manba | Roli | Nima aytadi |
/// |---|---|---|
/// | `ConnectivitySource` (`connectivity_plus`) | **turtki (hint)** | Interfeys ko'tarilganmi |
/// | So'rov natijalari (`report*` metodlari) | **haqiqat** | Backend'ga yetib bo'ladimi |
///
/// **Nega ikkita manba kerak:** `docs/ARCHITECTURE.md` oflaynni
/// *"backend'ga yeta olmaslik"* deb ta'riflaydi. Interfeys holatini
/// o'lchaydigan paket bunga javob bera olmaydi — mehmonxona/aeroport
/// portaliga ulangan qurilma "ulangan" bo'lib ko'rinadi, lekin hech
/// qayerga yeta olmaydi. Teskarisi ham to'g'ri: faqat so'rov
/// natijalariga tayansak, tarmoq QAYTGANINI o'zimiz sezmaymiz.
///
/// **Birlashtirish qoidasi:** `online` = interfeys ko'tarilgan **VA**
/// yetib bo'ladi deb hisoblanadi. Ikkisidan biri yo'q bo'lsa —
/// `offline`.
///
/// **Bu klass `lib/core/offline/` ICHIDA EMAS — ataylab** (7A dagi
/// `DriftLocalStore` bilan bir xil sabab): yadro tashqi paketga
/// bog'lanmasligi shart va buni chegara testi majburlaydi. Yadro
/// faqat `NetworkStateMonitor` shartnomasini biladi.
class ReachabilityAwareNetworkMonitor implements NetworkStateMonitor {
  ReachabilityAwareNetworkMonitor({
    required ConnectivitySource connectivitySource,
    bool initiallyInterfaceUp = true,
    int unreachableAfterConsecutiveFailures = 2,
  }) : _source = connectivitySource,
       _interfaceUp = initiallyInterfaceUp,
       _failureThreshold = unreachableAfterConsecutiveFailures,
       assert(unreachableAfterConsecutiveFailures >= 1);

  final ConnectivitySource _source;

  /// Ketma-ket nechta vaqtinchalik xatolikdan keyin "yetib
  /// bo'lmaydi" deb hisoblanadi.
  ///
  /// **Nega standart qiymat 1 emas:** bitta muvaffaqiyatsiz so'rov
  /// tarmoq uzilganini bildirmasligi mumkin (masalan server vaqtincha
  /// 503 qaytardi — tarmoq esa joyida). Darhol `offline`ga o'tish
  /// butun sikini to'xtatardi. Ikkita ketma-ket xatolik esa allaqachon
  /// ishonchli belgi.
  final int _failureThreshold;

  bool _interfaceUp;
  bool _reachable = true;
  int _consecutiveFailures = 0;

  StreamSubscription<bool>? _subscription;

  final StreamController<NetworkStatusChange> _controller =
      StreamController<NetworkStatusChange>.broadcast();

  @override
  NetworkStatus get currentStatus =>
      (_interfaceUp && _reachable) ? NetworkStatus.online : NetworkStatus.offline;

  @override
  Stream<NetworkStatusChange> get changes => _controller.stream;

  /// Interfeys o'zgarishlarini tinglashni boshlaydi.
  ///
  /// **Interfeys QAYTGANDA yetish holati ham qayta tiklanadi:**
  /// avvalgi tarmoqda backend'ga yetib bo'lmagani, yangi tarmoqda
  /// ham yetib bo'lmasligini bildirmaydi. Aks holda ilova bir marta
  /// muvaffaqiyatsizlikdan keyin, tarmoq almashtirilsa ham, abadiy
  /// `offline` bo'lib qolardi.
  Future<void> start() async {
    if (_subscription != null) return;

    _subscription = _source.interfaceChanges.listen((isUp) {
      if (isUp && !_interfaceUp) {
        _resetReachability();
      }
      _apply(interfaceUp: isUp);
    });

    _apply(interfaceUp: await _source.isInterfaceUp());
  }

  @override
  Future<NetworkStatus> refresh() async {
    _apply(interfaceUp: await _source.isInterfaceUp());
    return currentStatus;
  }

  /// So'rov MUVAFFAQIYATLI tugadi — backend'ga yetib bo'ladi.
  void reportReachable() {
    _consecutiveFailures = 0;
    _apply(reachable: true);
  }

  /// So'rov VAQTINCHALIK xatolik bilan tugadi.
  ///
  /// Chegaraga yetgandagina `offline`ga o'tiladi (yuqoridagi
  /// [_failureThreshold] izohiga qarang).
  void reportTransientFailure() {
    _consecutiveFailures += 1;
    if (_consecutiveFailures >= _failureThreshold) {
      _apply(reachable: false);
    }
  }

  void _resetReachability() {
    _consecutiveFailures = 0;
    _reachable = true;
  }

  /// Holatni qayta hisoblaydi va FAQAT haqiqiy o'zgarishda xabar
  /// beradi (`NetworkStateMonitor` shartnomasi talabi).
  void _apply({bool? interfaceUp, bool? reachable}) {
    final previous = currentStatus;

    if (interfaceUp != null) _interfaceUp = interfaceUp;
    if (reachable != null) _reachable = reachable;

    final current = currentStatus;
    if (current == previous) return;

    if (!_controller.isClosed) {
      _controller.add(NetworkStatusChange(previous: previous, current: current));
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
    await _controller.close();
  }
}
