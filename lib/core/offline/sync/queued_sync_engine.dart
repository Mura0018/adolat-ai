import 'dart:async';

import '../conflict/conflict_resolution.dart';
import '../conflict/conflict_resolution_strategy.dart';
import '../network/network_state_monitor.dart';
import '../queue/offline_queue.dart';
import '../queue/pending_operation.dart';
import 'sync_backoff_policy.dart';
import 'sync_engine.dart';
import 'sync_operation_outcome.dart';
import 'sync_state.dart';

/// `SyncEngine`ning navbatga asoslangan POYDEVOR implementatsiyasi.
///
/// **Hech qanday I/O bajarmaydi** — na HTTP, na Supabase, na fayl
/// tizimi. U faqat `docs/ARCHITECTURE.md`, "Sync Engine" bo'limidagi
/// QOIDALARNI amalga oshiradi:
///
/// | Hujjatdagi talab | Shu klassdagi ifodasi |
/// |---|---|
/// | FIFO tartib | `OfflineQueue.nextBatch()` tartibini o'zgartirmasdan qayta ishlaydi |
/// | Bog'liq amallar ketma-ketligi | `nextBatch()` bog'liqligi qanoatlanmaganini bermaydi |
/// | Idempotentlik | `PendingOperation.id` hech qachon o'zgartirilmaydi |
/// | Vaqtinchalik xatolikda qayta urinish | `SyncTransientFailure` → `markFailed`, navbatda qoladi |
/// | Doimiy xatolikda to'xtash | `SyncPermanentFailure` → `markNeedsAttention` |
/// | Cheksiz urinmaslik | `SyncBackoffPolicy.shouldRetry()` chegarasi |
/// | Ziddiyat | `ConflictResolutionStrategy`ga topshiradi |
/// | Ma'lumot yo'qolmasligi | Muvaffaqiyatsiz amal navbatdan O'CHIRILMAYDI |
///
/// Haqiqiy tarmoq ishi butunlay `SyncOperationHandler` ortida —
/// bu klass uni almashtirsangiz ham o'zgarmaydi.
class QueuedSyncEngine implements SyncEngine {
  QueuedSyncEngine({
    required OfflineQueue queue,
    required List<SyncOperationHandler> handlers,
    ConflictResolutionStrategy conflictStrategy = const DefaultConflictResolutionStrategy(),
    SyncBackoffPolicy backoffPolicy = const SyncBackoffPolicy(),
    NetworkStateMonitor? networkMonitor,
    Future<bool> Function()? isOnline,
    DateTime Function()? clock,
    int batchLimit = 20,
  }) : _queue = queue,
       _handlers = handlers,
       _conflictStrategy = conflictStrategy,
       _backoffPolicy = backoffPolicy,
       _networkMonitor = networkMonitor,
       _isOnline = isOnline,
       _clock = clock ?? DateTime.now,
       _batchLimit = batchLimit;

  final OfflineQueue _queue;
  final List<SyncOperationHandler> _handlers;
  final ConflictResolutionStrategy _conflictStrategy;
  final SyncBackoffPolicy _backoffPolicy;
  final DateTime Function() _clock;
  final int _batchLimit;

  /// Tarmoq holati manbai (Module 6B) — asosiy yo'l.
  ///
  /// Phase 6A'da bu yerda faqat `Future<bool> Function()` ilmog'i bor
  /// edi; 6B uni to'liq `NetworkStateMonitor` shartnomasi bilan
  /// almashtiradi. [_isOnline] hamon qo'llab-quvvatlanadi (testlarda
  /// va monitor kerak bo'lmagan oddiy holatlarda qulay), lekin
  /// monitor berilgan bo'lsa u ustuvor.
  final NetworkStateMonitor? _networkMonitor;

  final Future<bool> Function()? _isOnline;

  /// Ikkalasi ham berilmasa — "har doim onlayn" deb qaraladi
  /// (masalan sof mantiqiy testlarda).
  Future<bool> _checkOnline() async {
    final monitor = _networkMonitor;
    if (monitor != null) {
      return (await monitor.refresh()).isOnline;
    }
    final isOnline = _isOnline;
    if (isOnline != null) return isOnline();
    return true;
  }

  final StreamController<SyncState> _stateController = StreamController<SyncState>.broadcast();

  SyncState _currentState = const SyncIdle();

  /// Bir vaqtda ikkita sikl ishlamasligi kafolati — aks holda bir xil
  /// amal ikki marta yuborilishi mumkin edi.
  bool _isRunning = false;

  @override
  Stream<SyncState> get state => _stateController.stream;

  @override
  SyncState get currentState => _currentState;

  void _emit(SyncState next) {
    _currentState = next;
    if (!_stateController.isClosed) {
      _stateController.add(next);
    }
  }

  @override
  Future<SyncReport> sync({required SyncTrigger trigger}) async {
    if (_isRunning) {
      // Yangi sikl BOSHLANMAYDI (shartnoma talabi). Module 6C: bu
      // holat endi ANIQ belgilanadi, shuning uchun chaqiruvchi
      // (`SyncCoordinator`) signal yo'qolganini bilib, siklni qayta
      // rejalashtira oladi.
      return SyncReport.skippedAlreadyRunning(trigger);
    }

    _isRunning = true;
    try {
      if (!await _checkOnline()) {
        _emit(SyncPausedOffline(pendingCount: await _queue.pendingCount()));
        return SyncReport.skippedOffline(trigger);
      }

      // Oldingi sikl uzilib qolgan bo'lsa (ilova o'chib qolgan,
      // jarayon to'xtatilgan) -- `inProgress`da osilib qolgan amallar
      // tiklanadi. Bir vaqtda faqat bitta sikl ishlagani uchun, sikl
      // BOSHIDA `inProgress`da turgan har qanday amal aynan shunday
      // uzilishning izidir.
      await _recoverStalledOperations();

      final batch = await _eligibleBatch();
      if (batch.isEmpty) {
        _emit(SyncIdle(pendingCount: await _queue.pendingCount()));
        return SyncReport(
          trigger: trigger,
          processed: 0,
          succeeded: 0,
          transientFailures: 0,
          needsAttention: 0,
        );
      }

      var succeeded = 0;
      var transientFailures = 0;
      var needsAttention = 0;
      var processed = 0;

      for (final operation in batch) {
        // Sikl O'RTASIDA tarmoq uzilishi (`docs/ARCHITECTURE.md`,
        // "Network State Handling" -> *"onlayndan oflaynga o'tganda,
        // joriy bajarilayotgan so'rovlar xavfsiz tarzda navbatga
        // qaytariladi"*). Amal `inProgress` deb belgilanishidan OLDIN
        // tekshiriladi, shuning uchun qolgan amallar `pending` holida
        // navbatda saqlanadi -- hech narsa yo'qolmaydi.
        if (!await _checkOnline()) {
          _emit(SyncPausedOffline(pendingCount: await _queue.pendingCount()));
          return SyncReport(
            trigger: trigger,
            processed: processed,
            succeeded: succeeded,
            transientFailures: transientFailures,
            needsAttention: needsAttention,
            interruptedByOffline: true,
          );
        }

        _emit(SyncInProgress(processed: processed, total: batch.length));

        final resolved = await _processOne(operation);
        processed += 1;

        switch (resolved.status) {
          case PendingOperationStatus.completed:
            succeeded += 1;
          case PendingOperationStatus.needsAttention:
            needsAttention += 1;
          case PendingOperationStatus.failed:
            transientFailures += 1;
          case PendingOperationStatus.pending:
          case PendingOperationStatus.inProgress:
            // Bu yerga tushmasligi kerak -- `_processOne` har doim
            // yakuniy holat qaytaradi.
            transientFailures += 1;
        }
      }

      _emit(
        SyncCompleted(
          succeeded: succeeded,
          failed: transientFailures,
          needsAttention: needsAttention,
        ),
      );

      return SyncReport(
        trigger: trigger,
        processed: processed,
        succeeded: succeeded,
        transientFailures: transientFailures,
        needsAttention: needsAttention,
      );
    } finally {
      _isRunning = false;
    }
  }

  Future<PendingOperation> _processOne(PendingOperation operation) async {
    final handler = _handlerFor(operation);
    if (handler == null) {
      // Amalni bajara oladigan handler yo'q -- bu dasturlash/konfiguratsiya
      // xatosi, lekin amal JIMGINA yo'qolmasligi kerak: foydalanuvchi
      // e'tiboriga chiqariladi.
      return _save(
        operation.markNeedsAttention(
          'Bu amal turini bajara oladigan komponent ulanmagan '
          '(${operation.entityType}/${operation.kind.name}).',
        ),
      );
    }

    final started = await _save(operation.markInProgress(at: _clock()));

    SyncOperationOutcome outcome;
    try {
      outcome = await handler.perform(started);
    } catch (error) {
      // Handler shartnomasi exception tashlamaslikni talab qiladi,
      // lekin kutilmagan xatolik ma'lumot yo'qolishiga olib
      // kelmasligi kerak -- ehtiyotkorlik bilan VAQTINCHALIK deb
      // qaraladi (amal navbatda qoladi).
      outcome = SyncTransientFailure('Kutilmagan xatolik: $error');
    }

    final resolved = switch (outcome) {
      SyncSuccess() => await _save(started.markCompleted()),
      SyncPermanentFailure(:final message) => await _save(started.markNeedsAttention(message)),
      SyncTransientFailure(:final message) => await _save(
        _afterTransientFailure(started, message),
      ),
      SyncConflictDetected(:final conflict) => await _save(
        _applyConflictResolution(started, _conflictStrategy.resolve(conflict)),
      ),
    };

    if (resolved.status == PendingOperationStatus.needsAttention) {
      await _blockDependentsOf(resolved);
    }

    return resolved;
  }

  /// Bloklangan amalga BOG'LIQ amallarni ham foydalanuvchi e'tiboriga
  /// chiqaradi (Module 6C).
  ///
  /// **Bu — 6A/6B integratsiyasida aniqlangan eng jiddiy bo'shliq:**
  /// bog'liqlik faqat ota-amal `completed` bo'lganda qanoatlantirilardi.
  /// Agar ota-amal `needsAttention`ga tushsa (doimiy xatolik yoki
  /// ziddiyat), unga bog'langan amal MANGU `pending` holida navbatda
  /// qolar, hech qachon olinmas va hech qayerda ko'rinmasdi —
  /// foydalanuvchi uchun "jimgina yo'qolgan" bo'lardi
  /// (`DEVELOPMENT_RULES.md`, 17–19-band, "No Dead End Rule"ning
  /// bevosita buzilishi).
  ///
  /// Endi bog'liq amal ham `needsAttention`ga o'tadi va SABABI
  /// ko'rsatiladi. Foydalanuvchi ota-amalni tuzatib
  /// `OfflineQueue.retryNow()` bilan ikkalasini ham qayta ishga
  /// tushira oladi.
  ///
  /// Zanjir bo'ylab rekursiv ishlaydi (A → B → C).
  Future<void> _blockDependentsOf(PendingOperation blocked) async {
    final dependents = await _queue.dependentsOf(blocked.id);

    for (final dependent in dependents) {
      if (dependent.status == PendingOperationStatus.needsAttention) continue;
      if (dependent.status == PendingOperationStatus.completed) continue;

      final updated = dependent.markNeedsAttention(
        'Bog\'liq amal bajarilmadi (${blocked.entityType}/${blocked.kind.name}) — '
        'avval o\'sha amal hal qilinishi kerak.',
      );
      await _queue.update(updated);
      await _blockDependentsOf(updated);
    }
  }

  /// Vaqtinchalik xatolik: urinishlar chegarasiga yetgan bo'lsa,
  /// amal `needsAttention`ga o'tadi -- *"jimgina cheksiz qayta
  /// urinilmaydi"*.
  PendingOperation _afterTransientFailure(PendingOperation operation, String message) {
    if (!_backoffPolicy.shouldRetry(operation.attemptCount)) {
      return operation.markNeedsAttention(_backoffPolicy.exhaustedReason(operation.attemptCount));
    }
    return operation.markFailed(message);
  }

  /// Ziddiyat qarorini amal holatiga aylantiradi.
  ///
  /// **`ApplyLocalChange` amalni `pending` holatiga QAYTARADI:** qaror
  /// "mahalliy o'zgarish yuborilsin" degani, lekin uni yuborish
  /// keyingi sikl ishi -- shu bilan qaror qabul qilish va bajarish
  /// ajratilgan qoladi.
  PendingOperation _applyConflictResolution(
    PendingOperation operation,
    ConflictResolution resolution,
  ) {
    return switch (resolution) {
      ApplyLocalChange() => operation.markFailed(
        'Ziddiyat mahalliy foydasiga hal qilindi -- keyingi siklda qayta yuboriladi.',
      ),
      KeepServerState(:final reason) => operation.markNeedsAttention(reason),
      EscalateToUser(:final reason) => operation.markNeedsAttention(reason),
    };
  }

  /// Uzilib qolgan (`inProgress`da osilib qolgan) amallarni qayta
  /// urinishga yaroqli holatga qaytaradi.
  ///
  /// Bularsiz amal MANGU `inProgress`da qolib ketardi: bu holat
  /// `isSyncable` emas, ya'ni amal boshqa hech qachon olinmasdi va
  /// foydalanuvchi uchun "jimgina yo'qolgan"ga aylanardi — 6A
  /// navbatining eng nozik bo'shlig'i.
  ///
  /// Idempotentlik kaliti (`PendingOperation.id`) o'zgarmagani uchun
  /// qayta yuborish serverda takroriy yozuv hosil qilmaydi
  /// (`docs/ARCHITECTURE.md`, "Network State Handling" → *"So'rov
  /// davomida uzilish"*).
  Future<void> _recoverStalledOperations() async {
    final stalled = await _queue.getByStatus(PendingOperationStatus.inProgress);

    for (final operation in stalled) {
      await _queue.update(
        operation.markFailed(
          'Oldingi sinxronizatsiya yakunlanmay uzilib qolgan — qayta uriniladi.',
        ),
      );
    }
  }

  /// Navbatdan FAQAT shu daqiqada urinishga TAYYOR amallarni oladi.
  ///
  /// Backoff kutish oralig'i shu yerda haqiqatan hurmat qilinadi
  /// (Module 6B) — 6A'da oraliq hisoblanardi, lekin kutilmasdi.
  /// Navbatning FIFO tartibi saqlanadi: tayyor bo'lmagan amal
  /// o'tkazib yuboriladi, lekin o'z o'rnini yo'qotmaydi.
  Future<List<PendingOperation>> _eligibleBatch() async {
    final batch = await _queue.nextBatch(limit: _batchLimit);
    final now = _clock();

    return batch
        .where(
          (operation) => _backoffPolicy.isReadyForRetry(
            attemptCount: operation.attemptCount,
            lastAttemptAt: operation.lastAttemptAt,
            now: now,
          ),
        )
        .toList(growable: false);
  }

  SyncOperationHandler? _handlerFor(PendingOperation operation) {
    for (final handler in _handlers) {
      if (handler.canHandle(operation)) return handler;
    }
    return null;
  }

  Future<PendingOperation> _save(PendingOperation operation) async {
    await _queue.update(operation);
    return operation;
  }

  /// Oqimni yopadi (ilova to'xtaganda).
  Future<void> dispose() => _stateController.close();
}
