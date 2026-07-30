import '../queue/pending_operation.dart';
import 'sync_operation_outcome.dart';
import 'sync_state.dart';

/// Sinxronizatsiya NIMA SABABDAN ishga tushgani
/// (`docs/ARCHITECTURE.md`, "Sync Engine" → *"Ishga tushish
/// shartlari"*).
///
/// Sabab saqlanadi, chunki u diagnostikada muhim (masalan "faqat
/// qo'lda ishga tushirilganda ishlayapti" degan muammoni ko'rsatadi)
/// va kelgusida siyosat shunga bog'liq bo'lishi mumkin.
enum SyncTrigger {
  /// Tarmoq yo'q holatdan bor holatga o'tdi — asosiy avtomatik sabab.
  connectivityRestored,

  /// Ilova old rejaga (foreground) qaytdi.
  appForeground,

  /// Ilova ishga tushdi.
  appStart,

  /// Foydalanuvchi qo'lda so'radi (ixtiyoriy imkoniyat — talab
  /// bo'yicha majburiy emas).
  manual,
}

/// Bitta sinxronizatsiya siklining natijasi.
class SyncReport {
  const SyncReport({
    required this.trigger,
    required this.processed,
    required this.succeeded,
    required this.transientFailures,
    required this.needsAttention,
    this.skippedOffline = false,
  });

  /// Tarmoq yo'qligi sababli umuman ishlamagan sikl.
  const SyncReport.skippedOffline(this.trigger)
    : processed = 0,
      succeeded = 0,
      transientFailures = 0,
      needsAttention = 0,
      skippedOffline = true;

  final SyncTrigger trigger;
  final int processed;
  final int succeeded;

  /// Qayta urinish kutayotgan amallar soni.
  final int transientFailures;

  /// Foydalanuvchi aralashuvini kutayotgan amallar soni.
  final int needsAttention;

  final bool skippedOffline;

  bool get hasFailures => transientFailures > 0 || needsAttention > 0;

  @override
  String toString() =>
      'SyncReport(trigger: ${trigger.name}, processed: $processed, succeeded: $succeeded, '
      'transient: $transientFailures, needsAttention: $needsAttention, '
      'skippedOffline: $skippedOffline)';
}

/// BITTA navbatdagi amalni haqiqatan bajaruvchi chegara.
///
/// **Bu — Module 6A'ning eng muhim almashtirish nuqtasi.** Butun
/// offline yadrosi (navbat, tartib, qayta urinish, ziddiyat) shu
/// interfeysdan boshqa hech qayerda "serverga qanday murojaat
/// qilinadi" bilimini SAQLAMAYDI.
///
/// Shu sababli 6A'da HECH QANDAY HTTP/Supabase/WebSocket kodi yo'q va
/// bo'lishi ham shart emas — haqiqiy implementatsiya keyingi bosqichda
/// shu interfeysni amalga oshiradi. Bu chegara
/// `test/core/offline/offline_architecture_boundary_test.dart` bilan
/// avtomatik qulflangan.
///
/// `AIProviderAdapter` (Module 4) va `RecommendationEngine` (Module 5C)
/// bilan bir xil falsafa.
abstract interface class SyncOperationHandler {
  /// Shu handler berilgan amalni bajara oladimi (odatda
  /// `operation.entityType`/`kind` bo'yicha).
  bool canHandle(PendingOperation operation);

  /// Amalni bajarishga urinadi.
  ///
  /// **Exception TASHLAMASLIGI kutiladi** — har qanday xatolik
  /// `SyncTransientFailure`/`SyncPermanentFailure` sifatida
  /// QAYTARILADI, chunki "bu xatolik vaqtinchalikmi" degan qarorni
  /// faqat shu qatlam bila oladi. (`QueuedSyncEngine` baribir
  /// himoyalangan: kutilmagan exception vaqtinchalik xatolik deb
  /// qaraladi — ma'lumot yo'qolmasligi uchun.)
  Future<SyncOperationOutcome> perform(PendingOperation operation);
}

/// Sinxronizatsiya dvigatelining abstrakt shartnomasi
/// (`docs/ARCHITECTURE.md`, "Sync Engine").
abstract interface class SyncEngine {
  /// Joriy holat oqimi — UI shu oqimni tinglab "shaffof holat"ni
  /// ko'rsatadi (UI kelgusi bosqichda; 6A UI'ga TEGMAYDI).
  Stream<SyncState> get state;

  SyncState get currentState;

  /// Navbatni bir marta to'liq qayta ishlashga urinadi.
  ///
  /// Bir vaqtda ikkinchi chaqiruv qilinsa, u yangi sikl BOSHLAMAYDI
  /// (implementatsiya buni ta'minlashi shart) — aks holda bir xil amal
  /// ikki marta yuborilishi mumkin.
  Future<SyncReport> sync({required SyncTrigger trigger});
}
