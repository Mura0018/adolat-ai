import '../../../../core/network/result.dart';
import '../../../../services/supabase/supabase_exception_mapper.dart';
import '../../domain/entities/government_body.dart';
import '../../domain/entities/legal_category.dart';
import '../../domain/repositories/legal_reference_repository.dart';
import '../datasources/legal_reference_remote_datasource.dart';
import '../models/government_body_model.dart';
import '../models/legal_category_model.dart';

class LegalReferenceRepositoryImpl implements LegalReferenceRepository {
  LegalReferenceRepositoryImpl(this._remote);

  final LegalReferenceRemoteDataSource _remote;

  @override
  Future<Result<List<LegalCategory>>> getActiveLegalCategories() async {
    try {
      final models = await _remote.getActiveLegalCategories();
      return Result.ok(models.map((m) => m.toEntity()).toList());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<List<GovernmentBody>>> getActiveGovernmentBodies() async {
    try {
      final models = await _remote.getActiveGovernmentBodies();
      return Result.ok(models.map((m) => m.toEntity()).toList());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }
}
