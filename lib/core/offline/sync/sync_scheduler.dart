import 'dart:async';

import '../network/network_state_monitor.dart';
import '../network/network_status.dart';
import 'sync_engine.dart';

/// Sinxronizatsiya QACHON ishga tushishini hal qiluvchi komponent
/// (`docs/ARCHITECTURE.md`, "Sync Engine" → *"Ishga tushish
/// shartlari"*).
///
/// **Nega `SyncEngine`dan ALOHIDA:** dvigatel "bitta siklni qanday
/// bajarish" ni biladi, rejalashtiruvchi esa "qachon boshlash" ni.
/// Ikkalasini birlashtirish dvigatelni tarmoq oqimiga va ilova hayot
/// davriga bog'lab qo'yardi — natijada uni testda ishlatish uchun
/// ham shu bog'liqliklarni qurish kerak bo'lardi.
///
/// Hujjatdagi uchala avtomatik sabab shu yerda:
///
/// | Sabab | Metod |
/// |---|---|
/// | Tarmoq tiklandi | [start] ichida, monitor oqimiga obuna orqali (avtomatik) |
/// | Ilova ochildi | [onAppStart] |
/// | Ilova old rejaga qaytdi | [onAppForeground] |
/// | (ixtiyoriy) Foydalanuvchi so'radi | [syncNow] |
///
/// **Ilova hayot davri (`AppLifecycleState`) bu yerda import
/// QILINMAYDI** — u Flutter'ning `widgets` kutubxonasiga bog'liq
/// bo'lardi va offline yadrosining UI'dan mustaqilligini buzardi
/// (`test/core/offline/offline_architecture_boundary_test.dart`
/// buni taqiqlaydi). Signalni UI qatlami (kelgusi bosqichda) shu
/// oddiy metodlar orqali beradi.
class SyncScheduler {
  SyncScheduler({required SyncEngine engine, required NetworkStateMonitor networkMonitor})
    : _engine = engine,
      _networkMonitor = networkMonitor;

  final SyncEngine _engine;
  final NetworkStateMonitor _networkMonitor;

  StreamSubscription<NetworkStatusChange>? _subscription;

  /// Tarmoq tiklanishi sababli boshlangan sikllar soni —
  /// diagnostika/test uchun.
  int get connectivityTriggeredSyncCount => _connectivityTriggeredSyncCount;
  int _connectivityTriggeredSyncCount = 0;

  bool get isListening => _subscription != null;

  /// Tarmoq o'zgarishlarini tinglashni boshlaydi.
  ///
  /// Faqat **oflayn → onlayn** o'tishida sinxronizatsiya ishga
  /// tushadi (`NetworkStatusChange.isRestored`) — "hozir onlayn"
  /// degan har bir xabar uchun emas.
  void start() {
    if (_subscription != null) return;

    _subscription = _networkMonitor.changes.listen((change) {
      if (!change.isRestored) return;
      _connectivityTriggeredSyncCount += 1;
      unawaited(_safeSync(SyncTrigger.connectivityRestored));
    });
  }

  /// Ilova ishga tushganda chaqiriladi.
  Future<SyncReport> onAppStart() => _safeSync(SyncTrigger.appStart);

  /// Ilova old rejaga (foreground) qaytganda chaqiriladi.
  ///
  /// `docs/ARCHITECTURE.md`, "Sync Engine" → *"Fon rejimidagi
  /// cheklovlar"*: platforma fon ishini to'xtatgan bo'lsa ham,
  /// ilova keyingi safar ochilganda navbat ALBATTA qayta
  /// tekshirilishini shu ikkita metod kafolatlaydi.
  Future<SyncReport> onAppForeground() => _safeSync(SyncTrigger.appForeground);

  /// Foydalanuvchi qo'lda so'raganda (ixtiyoriy imkoniyat).
  Future<SyncReport> syncNow() => _safeSync(SyncTrigger.manual);

  /// Sinxronizatsiyani chaqiradi va **hech qachon exception
  /// tashlamaydi**.
  ///
  /// Sabab: bu metod hodisa tinglovchisidan (`listen`) ham
  /// chaqiriladi — u yerda tashlangan xatolik ilova darajasidagi
  /// ushlanmagan xatolikka aylanardi. Sinxronizatsiya muvaffaqiyati
  /// baribir `SyncReport`/`SyncState` orqali kuzatiladi.
  Future<SyncReport> _safeSync(SyncTrigger trigger) async {
    try {
      return await _engine.sync(trigger: trigger);
    } catch (_) {
      // Amallar navbatda qoladi -- keyingi sabab (tarmoq/foreground)
      // yana urinadi.
      return SyncReport(
        trigger: trigger,
        processed: 0,
        succeeded: 0,
        transientFailures: 0,
        needsAttention: 0,
      );
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
