/// Sinxronizatsiya jarayonining GLOBAL holati — foydalanuvchiga
/// ko'rsatiladigan "shaffof holat"ning manbai
/// (`docs/ARCHITECTURE.md`, "Offline-First Architecture" va "Network
/// State Handling").
///
/// `sealed` — `switch` to'liqligi kompilyatsiyada tekshiriladi, ya'ni
/// UI (kelgusi bosqichda) biror holatni ko'rsatishni unuta olmaydi.
///
/// **Bu holat XATOLIK emas, ish rejimi:** `docs/ARCHITECTURE.md`,
/// "Network State Handling" — *"bu holat xatolik sifatida emas,
/// ilovaning normal ishlash rejimlaridan biri sifatida taqdim
/// etiladi"*. Shu sababli hech bir variant `Failure` bilan
/// ifodalanmagan.
sealed class SyncState {
  const SyncState();

  /// Hozir faol sinxronizatsiya ketyaptimi.
  bool get isSyncing => this is SyncInProgress;
}

/// Hech narsa qilinmayapti; navbatda [pendingCount] ta amal kutmoqda
/// (0 bo'lishi ham mumkin).
class SyncIdle extends SyncState {
  const SyncIdle({this.pendingCount = 0});

  final int pendingCount;

  bool get hasPendingWork => pendingCount > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SyncIdle && other.pendingCount == pendingCount);

  @override
  int get hashCode => Object.hash(SyncIdle, pendingCount);

  @override
  String toString() => 'SyncIdle(pending: $pendingCount)';
}

/// Sinxronizatsiya ketmoqda — [processed]/[total] progressni
/// ko'rsatish uchun.
class SyncInProgress extends SyncState {
  const SyncInProgress({required this.processed, required this.total})
    : assert(processed >= 0),
      assert(total >= 0);

  final int processed;
  final int total;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncInProgress && other.processed == processed && other.total == total);

  @override
  int get hashCode => Object.hash(SyncInProgress, processed, total);

  @override
  String toString() => 'SyncInProgress($processed/$total)';
}

/// Tarmoq yo'qligi sababli sinxronizatsiya to'xtatilgan.
///
/// **Alohida holat sifatida ATAYLAB mavjud:** foydalanuvchiga
/// "xatolik" emas, "internet qaytganda avtomatik davom etadi" degan
/// ma'noni berish uchun.
class SyncPausedOffline extends SyncState {
  const SyncPausedOffline({this.pendingCount = 0});

  final int pendingCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncPausedOffline && other.pendingCount == pendingCount);

  @override
  int get hashCode => Object.hash(SyncPausedOffline, pendingCount);

  @override
  String toString() => 'SyncPausedOffline(pending: $pendingCount)';
}

/// Sinxronizatsiya sikli yakunlandi (qisman muvaffaqiyat ham shu
/// yerga tushadi — batafsil hisob `SyncReport`da).
class SyncCompleted extends SyncState {
  const SyncCompleted({
    required this.succeeded,
    required this.failed,
    required this.needsAttention,
  });

  final int succeeded;
  final int failed;
  final int needsAttention;

  /// Foydalanuvchi e'tiborini talab qiladigan amal bormi.
  bool get hasUnresolvedWork => needsAttention > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCompleted &&
          other.succeeded == succeeded &&
          other.failed == failed &&
          other.needsAttention == needsAttention);

  @override
  int get hashCode => Object.hash(SyncCompleted, succeeded, failed, needsAttention);

  @override
  String toString() =>
      'SyncCompleted(succeeded: $succeeded, failed: $failed, needsAttention: $needsAttention)';
}
