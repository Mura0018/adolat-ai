import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/result.dart';
import '../../data/datasources/ai_analyses_remote_datasource.dart';
import '../../data/repositories/ai_analyses_repository_impl.dart';
import '../../domain/entities/ai_analysis.dart';
import '../../domain/repositories/ai_analyses_repository.dart';

final aiAnalysesRepositoryProvider = Provider<AiAnalysesRepository>((ref) {
  return AiAnalysesRepositoryImpl(AiAnalysesRemoteDataSource());
});

final appealAiAnalysesProvider =
    FutureProvider.family<List<AiAnalysis>, String>((ref, appealId) async {
      final repo = ref.watch(aiAnalysesRepositoryProvider);
      final result = await repo.listForAppeal(appealId);
      return switch (result) {
        ResultOk(:final data) => data,
        ResultError(:final failure) => throw failure,
      };
    });

final disputeAiAnalysesProvider =
    FutureProvider.family<List<AiAnalysis>, String>((ref, disputeId) async {
      final repo = ref.watch(aiAnalysesRepositoryProvider);
      final result = await repo.listForDispute(disputeId);
      return switch (result) {
        ResultOk(:final data) => data,
        ResultError(:final failure) => throw failure,
      };
    });
