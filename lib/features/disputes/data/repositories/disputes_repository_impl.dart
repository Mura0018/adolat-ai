import '../../../../core/network/result.dart';
import '../../../../services/supabase/supabase_exception_mapper.dart';
import '../../domain/entities/dispute.dart';
import '../../domain/repositories/disputes_repository.dart';
import '../datasources/disputes_remote_datasource.dart';
import '../models/dispute_model.dart';

class DisputesRepositoryImpl implements DisputesRepository {
  DisputesRepositoryImpl(this._remote);

  final DisputesRemoteDataSource _remote;

  @override
  Future<Result<Dispute>> createWithUnregisteredRespondent({
    required String categoryId,
    required String title,
    required String description,
    required String respondentDisplayName,
  }) async {
    try {
      final model = await _remote.createWithUnregisteredRespondent(
        categoryId: categoryId,
        title: title,
        description: description,
        respondentDisplayName: respondentDisplayName,
      );
      return Result.ok(model.toEntity());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Dispute>> updateAsInitiator({
    required String disputeId,
    String? title,
    String? description,
  }) async {
    try {
      final model = await _remote.updateAsInitiator(
        disputeId: disputeId,
        title: title,
        description: description,
      );
      return Result.ok(model.toEntity());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Dispute>> submitRespondentStatement({
    required String disputeId,
    required String statement,
  }) async {
    try {
      final model = await _remote.submitRespondentStatement(
        disputeId: disputeId,
        statement: statement,
      );
      return Result.ok(model.toEntity());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> deleteAsInitiator(String disputeId) async {
    try {
      await _remote.deleteAsInitiator(disputeId);
      return const Result.ok(null);
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Dispute>> getById(String disputeId) async {
    try {
      final model = await _remote.getById(disputeId);
      return Result.ok(model.toEntity());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<List<Dispute>>> listMine() async {
    try {
      final models = await _remote.listMine();
      return Result.ok(models.map((m) => m.toEntity()).toList());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }
}
