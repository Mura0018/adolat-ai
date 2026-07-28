import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/result.dart';
import '../../data/datasources/disputes_remote_datasource.dart';
import '../../data/repositories/disputes_repository_impl.dart';
import '../../domain/entities/dispute.dart';
import '../../domain/repositories/disputes_repository.dart';
import '../../domain/usecases/create_dispute_usecase.dart';
import '../../domain/usecases/delete_dispute_usecase.dart';
import '../../domain/usecases/get_dispute_usecase.dart';
import '../../domain/usecases/list_my_disputes_usecase.dart';
import '../../domain/usecases/submit_respondent_statement_usecase.dart';
import '../../domain/usecases/update_dispute_as_initiator_usecase.dart';

final disputesRepositoryProvider = Provider<DisputesRepository>((ref) {
  return DisputesRepositoryImpl(DisputesRemoteDataSource());
});

final createDisputeUseCaseProvider = Provider<CreateDisputeUseCase>((ref) {
  return CreateDisputeUseCase(ref.watch(disputesRepositoryProvider));
});

final updateDisputeAsInitiatorUseCaseProvider =
    Provider<UpdateDisputeAsInitiatorUseCase>((ref) {
      return UpdateDisputeAsInitiatorUseCase(
        ref.watch(disputesRepositoryProvider),
      );
    });

final submitRespondentStatementUseCaseProvider =
    Provider<SubmitRespondentStatementUseCase>((ref) {
      return SubmitRespondentStatementUseCase(
        ref.watch(disputesRepositoryProvider),
      );
    });

final deleteDisputeUseCaseProvider = Provider<DeleteDisputeUseCase>((ref) {
  return DeleteDisputeUseCase(ref.watch(disputesRepositoryProvider));
});

final getDisputeUseCaseProvider = Provider<GetDisputeUseCase>((ref) {
  return GetDisputeUseCase(ref.watch(disputesRepositoryProvider));
});

final listMyDisputesUseCaseProvider = Provider<ListMyDisputesUseCase>((ref) {
  return ListMyDisputesUseCase(ref.watch(disputesRepositoryProvider));
});

final myDisputesProvider = FutureProvider<List<Dispute>>((ref) async {
  final result = await ref.watch(listMyDisputesUseCaseProvider).call();
  return switch (result) {
    ResultOk(:final data) => data,
    ResultError(:final failure) => throw failure,
  };
});

final disputeDetailProvider = FutureProvider.family<Dispute, String>((
  ref,
  disputeId,
) async {
  final result = await ref.watch(getDisputeUseCaseProvider).call(disputeId);
  return switch (result) {
    ResultOk(:final data) => data,
    ResultError(:final failure) => throw failure,
  };
});

/// Nizo yaratish/tahrirlash/javob berish amallari uchun holat
/// boshqaruvchisi.
class DisputeFormController extends StateNotifier<AsyncValue<Dispute?>> {
  DisputeFormController(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> create({
    required String categoryId,
    required String title,
    required String description,
    required String respondentDisplayName,
  }) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(createDisputeUseCaseProvider)
        .call(
          categoryId: categoryId,
          title: title,
          description: description,
          respondentDisplayName: respondentDisplayName,
        );
    _applyResult(result);
  }

  Future<void> updateAsInitiator({
    required String disputeId,
    String? title,
    String? description,
  }) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(updateDisputeAsInitiatorUseCaseProvider)
        .call(disputeId: disputeId, title: title, description: description);
    _applyResult(result, disputeId: disputeId);
  }

  Future<void> submitRespondentStatement({
    required String disputeId,
    required String statement,
  }) async {
    state = const AsyncValue.loading();
    final result = await _ref
        .read(submitRespondentStatementUseCaseProvider)
        .call(disputeId: disputeId, statement: statement);
    _applyResult(result, disputeId: disputeId);
  }

  void _applyResult(Result<Dispute> result, {String? disputeId}) {
    state = switch (result) {
      ResultOk(:final data) => AsyncValue.data(data),
      ResultError(:final failure) => AsyncValue.error(
        failure,
        StackTrace.current,
      ),
    };
    if (result.isOk) {
      _ref.invalidate(myDisputesProvider);
      if (disputeId != null) {
        _ref.invalidate(disputeDetailProvider(disputeId));
      }
    }
  }
}

final disputeFormControllerProvider =
    StateNotifierProvider<DisputeFormController, AsyncValue<Dispute?>>((ref) {
      return DisputeFormController(ref);
    });
