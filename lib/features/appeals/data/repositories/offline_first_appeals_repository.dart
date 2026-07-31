import '../../../../core/error/failure.dart';
import '../../../../core/network/result.dart';
import '../../../../core/offline/queue/offline_queue.dart';
import '../../../../core/offline/queue/pending_operation.dart';
import '../../../../core/offline/storage/local_store.dart';
import '../../../../core/utils/uuid_v7.dart';
import '../../domain/entities/appeal.dart';
import '../../domain/repositories/appeals_repository.dart';
import '../models/appeal_model.dart';

/// `AppealsRepository`ning **offline-first** implementatsiyasi —
/// Module 7C.
///
/// **Shartnoma O'ZGARMAGAN.** Bu klass mavjud `AppealsRepository`
/// interfeysini aynan amalga oshiradi: usecase'lar, domain qatlami va
/// UI hech qanday o'zgarishni sezmaydi. Buni mumkin qilgan narsa —
/// `docs/adr/ADR-009-offline-identifier-strategy.md`: identifikator
/// KLIENT tomonda (UUID v7) yaratilgani uchun `createDraft()` tarmoq
/// bo'lmasa ham to'liq shakllangan `Appeal` qaytara oladi.
///
/// **Yozish yo'li — har doim bir xil (write-through):** amal
/// mahalliy nusxaga yoziladi VA navbatga qo'yiladi; serverga
/// yuborishni `SyncEngine` o'z vaqtida bajaradi. Tarmoq holatiga
/// qarab shoxlanish (`if online ... else ...`) ATAYLAB yo'q — u
/// ikkita turli xatti-harakat yaratardi va "onlayn holatda boshqacha
/// ishlaydi" turidagi qiyin xatolarga olib kelardi.
///
/// **O'qish yo'li — server birinchi, mahalliy nusxa zaxira:** eng
/// so'nggi ma'lumot ustuvor, lekin tarmoq yo'q bo'lsa foydalanuvchi
/// avval ko'rgan ma'lumotni ko'rishda davom etadi
/// (`docs/ARCHITECTURE.md`, "Offline-First Architecture" → *"Faqat
/// ko'rish uchun ham offline qamrov"*).
class OfflineFirstAppealsRepository implements AppealsRepository {
  OfflineFirstAppealsRepository({
    required AppealsRepository remote,
    required LocalStore<Map<String, Object?>> cache,
    required OfflineQueue queue,
    required String? Function() currentUserId,
    String Function()? generateId,
    DateTime Function()? clock,
  }) : _remote = remote,
       _cache = cache,
       _queue = queue,
       _currentUserId = currentUserId,
       _generateId = generateId ?? UuidV7.generate,
       _clock = clock ?? DateTime.now;

  final AppealsRepository _remote;
  final LocalStore<Map<String, Object?>> _cache;
  final OfflineQueue _queue;
  final String? Function() _currentUserId;
  final String Function() _generateId;
  final DateTime Function() _clock;

  static const String _entityType = 'appeal';

  // ---------------------------------------------------------------
  // Yozish amallari
  // ---------------------------------------------------------------

  @override
  Future<Result<Appeal>> createDraft({
    required String categoryId,
    required String recipientBodyId,
    required String title,
    required String bodyText,
    String? aiDraftText,
  }) async {
    final authorId = _currentUserId();
    if (authorId == null) {
      return const Result.error(
        Failure.permissionDenied(message: 'Foydalanuvchi tizimga kirmagan'),
      );
    }

    // ADR-009: identifikator SHU YERDA yaratiladi va birinchi
    // kunidanoq yakuniy bo'ladi -- server uni o'zgartirmaydi.
    final id = _generateId();
    final now = _clock();

    final model = AppealModel(
      id: id,
      authorId: authorId,
      categoryId: categoryId,
      recipientBodyId: recipientBodyId,
      title: title,
      bodyText: bodyText,
      aiDraftText: aiDraftText,
      status: 'draft',
      createdAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );

    await _cache.put(id, model.toJson());
    await _enqueue(
      kind: PendingOperationKind.createRecord,
      entityId: id,
      payload: {
        'categoryId': categoryId,
        'recipientBodyId': recipientBodyId,
        'title': title,
        'bodyText': bodyText,
        'aiDraftText': aiDraftText,
      },
      at: now,
    );

    return Result.ok(model.toEntity());
  }

  @override
  Future<Result<Appeal>> updateDraft({
    required String appealId,
    String? title,
    String? bodyText,
  }) async {
    final existing = await _cachedModel(appealId);
    if (existing == null) {
      return const Result.error(
        Failure.unknown(message: 'Murojaat mahalliy nusxada topilmadi'),
      );
    }

    final now = _clock();
    final updated = existing.copyWith(
      title: title ?? existing.title,
      bodyText: bodyText ?? existing.bodyText,
      updatedAt: now.toIso8601String(),
    );

    await _cache.put(appealId, updated.toJson());
    // Ketma-ket tahrirlar navbatda bittaga birlashadi (Module 6C,
    // `updateRecord` uchun supersede qoidasi) -- shuning uchun har
    // bir tahrir uchun YANGI amal identifikatori beriladi.
    await _enqueue(
      kind: PendingOperationKind.updateRecord,
      entityId: appealId,
      payload: {'title': title, 'bodyText': bodyText},
      at: now,
    );

    return Result.ok(updated.toEntity());
  }

  @override
  Future<Result<Appeal>> submit(String appealId) async {
    final existing = await _cachedModel(appealId);
    if (existing == null) {
      return const Result.error(
        Failure.unknown(message: 'Murojaat mahalliy nusxada topilmadi'),
      );
    }

    final now = _clock();
    final updated = existing.copyWith(
      status: 'submitted',
      submittedAt: now.toIso8601String(),
      updatedAt: now.toIso8601String(),
    );

    await _cache.put(appealId, updated.toJson());
    await _enqueue(
      kind: PendingOperationKind.submitRecord,
      entityId: appealId,
      payload: const {},
      at: now,
    );

    return Result.ok(updated.toEntity());
  }

  @override
  Future<Result<void>> deleteDraft(String appealId) async {
    await _cache.delete(appealId);
    await _enqueue(
      kind: PendingOperationKind.deleteRecord,
      entityId: appealId,
      payload: const {},
      at: _clock(),
    );

    return const Result.ok(null);
  }

  // ---------------------------------------------------------------
  // O'qish amallari
  // ---------------------------------------------------------------

  @override
  Future<Result<Appeal>> getById(String appealId) async {
    final remoteResult = await _remote.getById(appealId);

    switch (remoteResult) {
      case ResultOk(:final data):
        await _cache.put(appealId, _toModel(data).toJson());
        return remoteResult;
      case ResultError():
        // Tarmoq yo'q yoki yozuv hali yuborilmagan -- mahalliy
        // nusxadan ko'rsatamiz.
        final cached = await _cachedModel(appealId);
        if (cached != null) return Result.ok(cached.toEntity());
        return remoteResult;
    }
  }

  @override
  Future<Result<List<Appeal>>> listMine() async {
    final remoteResult = await _remote.listMine();

    switch (remoteResult) {
      case ResultOk(:final data):
        for (final appeal in data) {
          await _cache.put(appeal.id, _toModel(appeal).toJson());
        }
        // Serverdagi ro'yxatga hali YUBORILMAGAN mahalliy yozuvlarni
        // qo'shamiz -- aks holda foydalanuvchi oflaynda yaratgan
        // murojaati ro'yxatdan "yo'qolgandek" ko'rinardi.
        final pendingOnly = await _unsyncedOnly(data.map((a) => a.id).toSet());
        return Result.ok([...data, ...pendingOnly]);
      case ResultError():
        final cached = await _cache.getAll();
        if (cached.isEmpty) return remoteResult;
        return Result.ok([
          for (final row in cached) AppealModel.fromJson(row).toEntity(),
        ]);
    }
  }

  // ---------------------------------------------------------------
  // Yordamchilar
  // ---------------------------------------------------------------

  Future<AppealModel?> _cachedModel(String appealId) async {
    final row = await _cache.get(appealId);
    return row == null ? null : AppealModel.fromJson(row);
  }

  /// Serverda hali mavjud bo'lmagan (navbatda turgan) mahalliy
  /// yozuvlar.
  Future<List<Appeal>> _unsyncedOnly(Set<String> remoteIds) async {
    final operations = await _queue.getAll();
    final pendingIds = operations
        .where((o) => o.entityType == _entityType && !o.status.isTerminal)
        .map((o) => o.entityId)
        .where((id) => !remoteIds.contains(id))
        .toSet();

    final result = <Appeal>[];
    for (final id in pendingIds) {
      final model = await _cachedModel(id);
      if (model != null) result.add(model.toEntity());
    }
    return result;
  }

  /// Entity → DTO xaritalash.
  ///
  /// **Nega bu yerda, `AppealModel`ning o'zida emas:** Module 7C
  /// mavjud fayllarni o'zgartirmaslik intizomiga amal qiladi. Bu
  /// yo'nalish (entity → DTO) faqat mahalliy keshga yozish uchun
  /// kerak — ya'ni offline qatlamining ehtiyoji, model qatlamining
  /// umumiy vazifasi emas. Agar u boshqa joyda ham kerak bo'lsa,
  /// `AppealModel`ga ko'chirilishi mumkin.
  static AppealModel _toModel(Appeal appeal) {
    return AppealModel(
      id: appeal.id,
      authorId: appeal.authorId,
      categoryId: appeal.categoryId,
      recipientBodyId: appeal.recipientBodyId,
      title: appeal.title,
      bodyText: appeal.bodyText,
      aiDraftText: appeal.aiDraftText,
      status: appeal.status.dbValue,
      officialResponseText: appeal.officialResponseText,
      submittedAt: appeal.submittedAt?.toIso8601String(),
      closedAt: appeal.closedAt?.toIso8601String(),
      createdAt: appeal.createdAt.toIso8601String(),
      updatedAt: appeal.updatedAt.toIso8601String(),
    );
  }

  Future<void> _enqueue({
    required PendingOperationKind kind,
    required String entityId,
    required Map<String, Object?> payload,
    required DateTime at,
  }) {
    return _queue.enqueue(
      PendingOperation(
        // Amal identifikatori yozuv identifikatoridan ALOHIDA:
        // bitta yozuv ustida bir nechta amal bo'lishi mumkin.
        id: _generateId(),
        kind: kind,
        entityType: _entityType,
        entityId: entityId,
        payload: payload,
        createdAt: at,
      ),
    );
  }
}
