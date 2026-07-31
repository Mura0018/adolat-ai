import 'dart:async';

import '../network/network_state_monitor.dart';
import '../queue/offline_queue.dart';
import '../queue/pending_operation.dart';
import 'sync_engine.dart';
import 'sync_scheduler.dart';

/// Offline-First qatlamining YAGONA tashqi kirish nuqtasi
/// (Module 6C).
///
/// Ilova (kelgusi bosqichda UI/DI qatlami) navbat, dvigatel va
/// rejalashtiruvchi bilan ALOHIDA-ALOHIDA ishlamasligi kerak —
/// aks holda ularning to'g'ri tartibda ulanishi har bir chaqiruv
/// joyida qayta takrorlanardi.
///
/// **Hal qiladigan asosiy muammo — YO'QOLGAN SIGNAL (race):**
/// `SyncEngine` bir vaqtda faqat bitta sikl ishlashini kafolatlaydi;
/// sikl davomida kelgan yangi sabab (masalan tarmoq tiklandi)
/// e'tiborsiz qolar edi va navbatdagi yangi amallar keyingi tasodifiy
/// sababgacha kutib turardi. Bu — 6A/6B integratsiyasida aniqlangan
/// haqiqiy poyga holati.
///
/// Koordinator uni **birlashtirish (coalescing)** bilan yopadi: sikl
/// ishlayotganda kelgan sabab BELGILAB qo'yiladi va joriy sikl
/// tugagach, avtomatik ravishda YANA bitta sikl ishga tushadi.
/// Nechta signal kelganidan qat'i nazar, ortiqcha sikl emas — aynan
/// BITTA qo'shimcha sikl bajariladi.
class SyncCoordinator {
  SyncCoordinator({
    required SyncEngine engine,
    required OfflineQueue queue,
    required NetworkStateMonitor networkMonitor,
  }) : _engine = engine,
       _queue = queue,
       _scheduler = SyncScheduler(engine: engine, networkMonitor: networkMonitor);

  SyncCoordinator.withScheduler({
    required SyncEngine engine,
    required OfflineQueue queue,
    required SyncScheduler scheduler,
  }) : _engine = engine,
       _queue = queue,
       _scheduler = scheduler;

  final SyncEngine _engine;
  final OfflineQueue _queue;
  final SyncScheduler _scheduler;

  bool _isCycleRunning = false;

  /// Joriy sikl davomida kelgan, hali bajarilmagan sabab.
  SyncTrigger? _coalescedTrigger;

  /// Birlashtirish natijasida bajarilgan qo'shimcha sikllar soni —
  /// diagnostika/test uchun.
  int get coalescedRunCount => _coalescedRunCount;
  int _coalescedRunCount = 0;

  /// Tarmoq tiklanishini avtomatik kuzatishni boshlaydi.
  void start() => _scheduler.start();

  Stream<dynamic> get syncState => _engine.state;

  /// Foydalanuvchi yangi amalni navbatga qo'yadi va (agar imkon
  /// bo'lsa) darhol sinxronizatsiya urinishi boshlanadi.
  ///
  /// Tarmoq bo'lmasa — amal shunchaki navbatda qoladi, XATOLIK
  /// QAYTARILMAYDI: offline holat normal ish rejimi
  /// (`docs/ARCHITECTURE.md`, "Network State Handling").
  Future<void> submit(PendingOperation operation) async {
    await _queue.enqueue(operation);
    unawaited(run(SyncTrigger.manual));
  }

  Future<SyncReport> onAppStart() => run(SyncTrigger.appStart);

  Future<SyncReport> onAppForeground() => run(SyncTrigger.appForeground);

  Future<SyncReport> syncNow() => run(SyncTrigger.manual);

  /// Foydalanuvchi bloklangan amalni qayta ishga tushiradi
  /// (`needsAttention` → navbat) va darhol urinib ko'riladi.
  ///
  /// "No Dead End Rule"ning amaliy ifodasi: foydalanuvchiga faqat
  /// muammo ko'rsatilmaydi, undan CHIQISH yo'li ham beriladi.
  Future<SyncReport> retryOperation(String operationId) async {
    await _queue.retryNow(operationId);
    return run(SyncTrigger.manual);
  }

  /// Foydalanuvchi amalni butunlay bekor qiladi.
  Future<void> cancelOperation(String operationId) => _queue.remove(operationId);

  /// Yakunlangan amallarni tozalaydi (`docs/ARCHITECTURE.md`,
  /// "Local Storage" → hajm va tozalash siyosati).
  Future<int> cleanUpCompleted() => _queue.removeCompleted();

  /// Foydalanuvchi e'tiborini kutayotgan amallar — UI shu ro'yxatni
  /// ko'rsatadi (kelgusi bosqich).
  Future<List<PendingOperation>> operationsNeedingAttention() =>
      _queue.getByStatus(PendingOperationStatus.needsAttention);

  Future<int> pendingCount() => _queue.pendingCount();

  /// Siklni ishga tushiradi; band bo'lsa — sababni BELGILAB qo'yadi
  /// va joriy sikl tugagach avtomatik takrorlaydi.
  Future<SyncReport> run(SyncTrigger trigger) async {
    if (_isCycleRunning) {
      // Signal YO'QOLMAYDI -- birlashtiriladi.
      _coalescedTrigger = trigger;
      return SyncReport.skippedAlreadyRunning(trigger);
    }

    _isCycleRunning = true;
    try {
      var report = await _engine.sync(trigger: trigger);

      // Sikl davomida kelgan sabab(lar) uchun AYNAN bitta qo'shimcha
      // sikl -- nechta signal kelganidan qat'i nazar.
      while (_coalescedTrigger != null) {
        final pending = _coalescedTrigger!;
        _coalescedTrigger = null;
        _coalescedRunCount += 1;
        report = await _engine.sync(trigger: pending);
      }

      return report;
    } finally {
      _isCycleRunning = false;
    }
  }

  Future<void> dispose() => _scheduler.dispose();
}
