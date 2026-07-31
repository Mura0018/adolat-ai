import '../../core/offline/queue/pending_operation.dart';
import '../../core/offline/sync/sync_engine.dart';
import '../../core/offline/sync/sync_operation_outcome.dart';
import 'reachability_aware_network_monitor.dart';

/// `SyncOperationHandler`ni O'RAB, uning natijalarini tarmoq
/// monitoriga "haqiqat manbai" sifatida uzatuvchi dekorator
/// (`docs/adr/ADR-008-network-signal-source.md`).
///
/// **Nega dekorator, interfeysga metod qo'shish emas:** ADR-008ning
/// natijasi yadro shartnomalarini o'zgartirishni TALAB QILMAYDI.
/// `NetworkStateMonitor`ga `report*` metodlarini qo'shish uni amalga
/// oshiruvchi barcha klasslarni (jumladan `InMemoryNetworkStateMonitor`
/// va testlardagilarni) buzardi. Dekorator esa mavjud
/// `SyncOperationHandler` shartnomasini AYNAN saqlaydi —
/// `QueuedSyncEngine` bu klass borligini ham bilmaydi.
///
/// **Natijalarni talqin qilish (eng muhim qism):**
///
/// | Natija | Tarmoq haqida nima deydi |
/// |---|---|
/// | `SyncSuccess` | Yetib bo'ladi — server javob berdi |
/// | `SyncPermanentFailure` | **Yetib bo'ladi** — server javob berdi (rad etdi) |
/// | `SyncConflictDetected` | **Yetib bo'ladi** — server holatini bildirdi |
/// | `SyncTransientFailure` | Yetib bo'lmasligi MUMKIN |
///
/// Ikkinchi va uchinchi qatorlar nozik, lekin muhim: validatsiya
/// xatosi yoki ziddiyat — bu tarmoq muammosi EMAS, aksincha
/// backend'ga muvaffaqiyatli yetib borganimizning isboti. Ularni
/// "tarmoq yo'q" deb talqin qilish ilovani noto'g'ri `offline`
/// holatiga tushirardi va sinxronizatsiyani keraksiz to'xtatardi.
class ReachabilityReportingSyncHandler implements SyncOperationHandler {
  const ReachabilityReportingSyncHandler({
    required SyncOperationHandler inner,
    required ReachabilityAwareNetworkMonitor monitor,
  }) : _inner = inner,
       _monitor = monitor;

  final SyncOperationHandler _inner;
  final ReachabilityAwareNetworkMonitor _monitor;

  @override
  bool canHandle(PendingOperation operation) => _inner.canHandle(operation);

  @override
  Future<SyncOperationOutcome> perform(PendingOperation operation) async {
    final outcome = await _inner.perform(operation);

    switch (outcome) {
      case SyncSuccess():
      case SyncPermanentFailure():
      case SyncConflictDetected():
        _monitor.reportReachable();
      case SyncTransientFailure():
        _monitor.reportTransientFailure();
    }

    return outcome;
  }
}
