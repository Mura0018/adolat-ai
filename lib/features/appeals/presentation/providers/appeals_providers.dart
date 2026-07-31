import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/result.dart';
import '../../../../core/offline/sync/sync_engine.dart';
import '../../../../services/offline/offline_providers.dart';
import '../../../../services/supabase/supabase_providers.dart';
import '../../data/datasources/appeals_remote_datasource.dart';
import '../../data/repositories/appeals_repository_impl.dart';
import '../../data/repositories/offline_first_appeals_repository.dart';
import '../../data/sync/appeals_sync_operation_handler.dart';
import '../../domain/entities/appeal.dart';
import '../../domain/repositories/appeals_repository.dart';
import '../../domain/usecases/create_appeal_draft_usecase.dart';
import '../../domain/usecases/delete_appeal_draft_usecase.dart';
import '../../domain/usecases/get_appeal_usecase.dart';
import '../../domain/usecases/list_my_appeals_usecase.dart';
import '../../domain/usecases/submit_appeal_usecase.dart';
import '../../domain/usecases/update_appeal_draft_usecase.dart';

final appealsRemoteDataSourceProvider = Provider<AppealsRemoteDataSource>((ref) {
  return AppealsRemoteDataSource();
});

/// Faqat serverga murojaat qiluvchi implementatsiya.
///
/// `OfflineFirstAppealsRepository` uni O'RAYDI (o'qish yo'li uchun) —
/// shuning uchun u yo'q qilinmadi, balki alohida provayderga
/// ajratildi (Module 7D).
final remoteAppealsRepositoryProvider = Provider<AppealsRepository>((ref) {
  return AppealsRepositoryImpl(ref.watch(appealsRemoteDataSourceProvider));
});

/// Navbatdagi murojaat amallarini serverga yuboruvchi handler
/// (Module 7C). `main()` da `featureSyncHandlersProvider`ga
/// qo'shiladi.
final appealsSyncOperationHandlerProvider = Provider<SyncOperationHandler>((ref) {
  return AppealsSyncOperationHandler(ref.watch(appealsRemoteDataSourceProvider));
});

/// **Offline-first murojaat repozitoriysi** (Module 7D).
///
/// Interfeys o'zgarmadi — usecase'lar va ekranlar farqni sezmaydi
/// (`docs/adr/ADR-009-offline-identifier-strategy.md`). Yozish yo'li
/// endi mahalliy bazaga va navbatga boradi; serverga yuborishni
/// `SyncEngine` bajaradi.
final appealsRepositoryProvider = Provider<AppealsRepository>((ref) {
  return OfflineFirstAppealsRepository(
    remote: ref.watch(remoteAppealsRepositoryProvider),
    cache: ref.watch(appealsCacheStoreProvider),
    queue: ref.watch(offlineQueueProvider),
    currentUserId: ref.watch(currentUserIdProvider),
  );
});

final createAppealDraftUseCaseProvider = Provider<CreateAppealDraftUseCase>((
  ref,
) {
  return CreateAppealDraftUseCase(ref.watch(appealsRepositoryProvider));
});

final updateAppealDraftUseCaseProvider = Provider<UpdateAppealDraftUseCase>((
  ref,
) {
  return UpdateAppealDraftUseCase(ref.watch(appealsRepositoryProvider));
});

final submitAppealUseCaseProvider = Provider<SubmitAppealUseCase>((ref) {
  return SubmitAppealUseCase(ref.watch(appealsRepositoryProvider));
});

final deleteAppealDraftUseCaseProvider = Provider<DeleteAppealDraftUseCase>((
  ref,
) {
  return DeleteAppealDraftUseCase(ref.watch(appealsRepositoryProvider));
});

final getAppealUseCaseProvider = Provider<GetAppealUseCase>((ref) {
  return GetAppealUseCase(ref.watch(appealsRepositoryProvider));
});

final listMyAppealsUseCaseProvider = Provider<ListMyAppealsUseCase>((ref) {
  return ListMyAppealsUseCase(ref.watch(appealsRepositoryProvider));
});

/// Joriy foydalanuvchining barcha murojaatlari ro'yxati (`Bosh sahifa` /
/// `Murojaatlarim` ekrani uchun).
final myAppealsProvider = FutureProvider<List<Appeal>>((ref) async {
  final result = await ref.watch(listMyAppealsUseCaseProvider).call();
  return switch (result) {
    ResultOk(:final data) => data,
    ResultError(:final failure) => throw failure,
  };
});

/// Bitta murojaat tafsiloti (`appealId` bo'yicha).
final appealDetailProvider = FutureProvider.family<Appeal, String>((
  ref,
  appealId,
) async {
  final result = await ref.watch(getAppealUseCaseProvider).call(appealId);
  return switch (result) {
    ResultOk(:final data) => data,
    ResultError(:final failure) => throw failure,
  };
});

/// Murojaat qoralamasini yaratish/tahrirlash/yuborish/o'chirish amallari
/// uchun holat boshqaruvchisi. Ekran shu orqali amalni boshlaydi va
/// natija/xatolikni `AsyncValue` sifatida kuzatadi.
class AppealFormController extends StateNotifier<AsyncValue<Appeal?>> {
  AppealFormController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> createDraft({
    required String categoryId,
    required String recipientBodyId,
    required String title,
    required String bodyText,
    String? aiDraftText,
  }) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(createAppealDraftUseCaseProvider)
        .call(
          categoryId: categoryId,
          recipientBodyId: recipientBodyId,
          title: title,
          bodyText: bodyText,
          aiDraftText: aiDraftText,
        );
    state = switch (result) {
      ResultOk(:final data) => AsyncValue.data(data),
      ResultError(:final failure) => AsyncValue.error(
        failure,
        StackTrace.current,
      ),
    };
  }

  Future<void> updateDraft({
    required String appealId,
    String? title,
    String? bodyText,
  }) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(updateAppealDraftUseCaseProvider)
        .call(appealId: appealId, title: title, bodyText: bodyText);
    state = switch (result) {
      ResultOk(:final data) => AsyncValue.data(data),
      ResultError(:final failure) => AsyncValue.error(
        failure,
        StackTrace.current,
      ),
    };
    if (result.isOk) {
      _ref.invalidate(myAppealsProvider);
      _ref.invalidate(appealDetailProvider(appealId));
    }
  }

  Future<void> submit(String appealId) async {
    state = const AsyncValue.loading();
    final result = await _ref.read(submitAppealUseCaseProvider).call(
      appealId,
    );
    state = switch (result) {
      ResultOk(:final data) => AsyncValue.data(data),
      ResultError(:final failure) => AsyncValue.error(
        failure,
        StackTrace.current,
      ),
    };
    if (result.isOk) {
      _ref.invalidate(myAppealsProvider);
      _ref.invalidate(appealDetailProvider(appealId));
    }
  }
}

final appealFormControllerProvider =
    StateNotifierProvider<AppealFormController, AsyncValue<Appeal?>>((ref) {
      return AppealFormController(ref);
    });
