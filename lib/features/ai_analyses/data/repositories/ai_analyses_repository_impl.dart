import '../../../../core/network/result.dart';
import '../../../../services/supabase/supabase_exception_mapper.dart';
import '../../domain/entities/ai_analysis.dart';
import '../../domain/repositories/ai_analyses_repository.dart';
import '../datasources/ai_analyses_remote_datasource.dart';
import '../models/ai_analysis_model.dart';

class AiAnalysesRepositoryImpl implements AiAnalysesRepository {
  AiAnalysesRepositoryImpl(this._remote);

  final AiAnalysesRemoteDataSource _remote;

  @override
  Future<Result<List<AiAnalysis>>> listForAppeal(String appealId) async {
    try {
      final models = await _remote.listForAppeal(appealId);
      return Result.ok(models.map((m) => m.toEntity()).toList());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<List<AiAnalysis>>> listForDispute(String disputeId) async {
    try {
      final models = await _remote.listForDispute(disputeId);
      return Result.ok(models.map((m) => m.toEntity()).toList());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }
}
