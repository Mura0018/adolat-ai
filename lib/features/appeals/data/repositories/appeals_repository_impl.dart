import '../../../../core/network/result.dart';
import '../../../../services/supabase/supabase_exception_mapper.dart';
import '../../domain/entities/appeal.dart';
import '../../domain/repositories/appeals_repository.dart';
import '../datasources/appeals_remote_datasource.dart';
import '../models/appeal_model.dart';

class AppealsRepositoryImpl implements AppealsRepository {
  AppealsRepositoryImpl(this._remote);

  final AppealsRemoteDataSource _remote;

  @override
  Future<Result<Appeal>> createDraft({
    required String categoryId,
    required String recipientBodyId,
    required String title,
    required String bodyText,
    String? aiDraftText,
  }) async {
    try {
      final model = await _remote.createDraft(
        categoryId: categoryId,
        recipientBodyId: recipientBodyId,
        title: title,
        bodyText: bodyText,
        aiDraftText: aiDraftText,
      );
      return Result.ok(model.toEntity());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Appeal>> updateDraft({
    required String appealId,
    String? title,
    String? bodyText,
  }) async {
    try {
      final model = await _remote.updateDraft(
        appealId: appealId,
        title: title,
        bodyText: bodyText,
      );
      return Result.ok(model.toEntity());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Appeal>> submit(String appealId) async {
    try {
      final model = await _remote.submit(appealId);
      return Result.ok(model.toEntity());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> deleteDraft(String appealId) async {
    try {
      await _remote.deleteDraft(appealId);
      return const Result.ok(null);
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<Appeal>> getById(String appealId) async {
    try {
      final model = await _remote.getById(appealId);
      return Result.ok(model.toEntity());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<List<Appeal>>> listMine() async {
    try {
      final models = await _remote.listMine();
      return Result.ok(models.map((m) => m.toEntity()).toList());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }
}
