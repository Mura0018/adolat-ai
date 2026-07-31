import '../../../../core/error/failure.dart';
import '../../../../core/offline/queue/pending_operation.dart';
import '../../../../core/offline/sync/sync_engine.dart';
import '../../../../core/offline/sync/sync_operation_outcome.dart';
import '../../../../services/supabase/supabase_exception_mapper.dart';
import '../datasources/appeals_remote_datasource.dart';

/// Navbatdagi murojaat amallarini HAQIQATAN serverga yuboruvchi
/// komponent — Module 6A'dan beri bo'sh turgan
/// `SyncOperationHandler` chegarasining birinchi haqiqiy
/// implementatsiyasi.
///
/// **Bu — offline yadrosidagi YAGONA tarmoq nuqtasi.** Navbat,
/// dvigatel, backoff, ziddiyat qoidalari — hech biri serverga qanday
/// murojaat qilinishini bilmaydi; hammasi shu klass ortida.
///
/// **Xatolikni tasniflash — eng muhim vazifasi.** `QueuedSyncEngine`
/// "bu xatolik vaqtinchalikmi" degan qarorni O'ZI qabul qila
/// olmaydi (`sync_engine.dart` izohiga qarang) — uni faqat server
/// javobini ko'rgan qatlam biladi. Tasnif `Failure` turlari orqali
/// amalga oshiriladi, ya'ni loyihada allaqachon mavjud va sinalgan
/// `mapSupabaseExceptionToFailure` mantig'i qayta ishlatiladi
/// (`DEVELOPMENT_RULES.md`, 7-band).
class AppealsSyncOperationHandler implements SyncOperationHandler {
  const AppealsSyncOperationHandler(this._remote);

  final AppealsRemoteDataSource _remote;

  /// Shu handler faqat `appeal` turidagi yozuvlar bilan ishlaydi.
  static const String entityType = 'appeal';

  @override
  bool canHandle(PendingOperation operation) => operation.entityType == entityType;

  @override
  Future<SyncOperationOutcome> perform(PendingOperation operation) async {
    try {
      switch (operation.kind) {
        case PendingOperationKind.createRecord:
          await _remote.createDraft(
            id: operation.entityId,
            categoryId: operation.payload['categoryId']! as String,
            recipientBodyId: operation.payload['recipientBodyId']! as String,
            title: operation.payload['title']! as String,
            bodyText: operation.payload['bodyText']! as String,
            aiDraftText: operation.payload['aiDraftText'] as String?,
          );

        case PendingOperationKind.updateRecord:
          await _remote.updateDraft(
            appealId: operation.entityId,
            title: operation.payload['title'] as String?,
            bodyText: operation.payload['bodyText'] as String?,
          );

        case PendingOperationKind.submitRecord:
          await _remote.submit(operation.entityId);

        case PendingOperationKind.deleteRecord:
          await _remote.deleteDraft(operation.entityId);

        case PendingOperationKind.uploadAttachment:
        case PendingOperationKind.requestAiAnalysis:
          // Bu turlar boshqa handlerlarga tegishli. `canHandle`
          // entityType bo'yicha filtrlagani uchun bu yerga tushishi
          // kutilmaydi -- lekin tushsa, amal JIMGINA yo'qolmasligi
          // kerak.
          return SyncPermanentFailure(
            'Murojaat handleri bu amal turini bajara olmaydi: ${operation.kind.name}',
          );
      }

      // ADR-009: server qaytargan id klient bergani bilan AYNAN bir
      // xil, shuning uchun `remoteId` moslashtirish uchun EMAS --
      // faqat tasdiq sifatida uzatiladi.
      return SyncSuccess(remoteId: operation.entityId);
    } catch (error) {
      return _classify(error);
    }
  }

  /// Xom xatolikni "qayta urinsa bo'ladimi" degan qarorga aylantiradi.
  ///
  /// - **Vaqtinchalik:** tarmoq uzilishi (`NetworkFailure`) va
  ///   serverning vaqtinchalik nosozligi — amal navbatda qoladi va
  ///   backoff bilan qayta uriniladi.
  /// - **Doimiy:** ruxsat rad etilishi (RLS), validatsiya xatosi va
  ///   boshqalar — qayta urinish ma'nosiz, foydalanuvchiga
  ///   ko'rsatiladi.
  ///
  /// **`PermissionDeniedFailure` nega DOIMIY:** RLS rad etgan bo'lsa
  /// (masalan murojaat allaqachon `submitted` holatiga o'tgan va
  /// tahrirlab bo'lmaydi), qayta urinish hech qachon natija
  /// bermaydi — bu foydalanuvchi ko'rishi kerak bo'lgan holat.
  SyncOperationOutcome _classify(Object error) {
    final failure = mapSupabaseExceptionToFailure(error);

    return switch (failure) {
      NetworkFailure() => SyncTransientFailure(failure.userFacingHint),
      ServerFailure(:final code) when _isRetryableServerCode(code) =>
        SyncTransientFailure(failure.userFacingHint),
      _ => SyncPermanentFailure(failure.userFacingHint),
    };
  }

  /// Serverning VAQTINCHALIK nosozligini bildiruvchi kodlar.
  ///
  /// Ro'yxat ataylab TOR: shubha bo'lganda amal `needsAttention`ga
  /// o'tadi va foydalanuvchiga ko'rsatiladi — jimgina cheksiz qayta
  /// urinishdan ko'ra bu xavfsizroq (`docs/ARCHITECTURE.md`, "Sync
  /// Engine").
  static bool _isRetryableServerCode(String? code) {
    return code == '502' || code == '503' || code == '504' || code == '429';
  }
}

/// Xom xatolik matnini foydalanuvchiga ko'rsatish uchun emas,
/// diagnostika uchun qisqartiradi.
extension on Failure {
  String get userFacingHint {
    return switch (this) {
      NetworkFailure() => 'Tarmoq bilan bog\'lanib bo\'lmadi',
      PermissionDeniedFailure() => 'Bu amalga ruxsat yo\'q yoki yozuv holati o\'zgargan',
      ValidationFailure(:final message) => message,
      ServerFailure(:final code) => 'Server xatoligi${code == null ? '' : ' ($code)'}',
      StorageFailure() => 'Fayl bilan bog\'liq xatolik',
      UnknownFailure() => 'Kutilmagan xatolik',
    };
  }
}
