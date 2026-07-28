import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/result.dart';
import '../../data/datasources/legal_reference_remote_datasource.dart';
import '../../data/repositories/legal_reference_repository_impl.dart';
import '../../domain/entities/government_body.dart';
import '../../domain/entities/legal_category.dart';
import '../../domain/repositories/legal_reference_repository.dart';

final legalReferenceRepositoryProvider = Provider<LegalReferenceRepository>((
  ref,
) {
  return LegalReferenceRepositoryImpl(LegalReferenceRemoteDataSource());
});

/// Murojaat/nizo yaratish shaklidagi kategoriya tanlash ro'yxati.
final activeLegalCategoriesProvider = FutureProvider<List<LegalCategory>>((
  ref,
) async {
  final repo = ref.watch(legalReferenceRepositoryProvider);
  final result = await repo.getActiveLegalCategories();
  return switch (result) {
    ResultOk<List<LegalCategory>>(:final data) => data,
    ResultError<List<LegalCategory>>(:final failure) => throw failure,
  };
});

/// Murojaat yaratish shaklidagi davlat organi tanlash ro'yxati.
final activeGovernmentBodiesProvider = FutureProvider<List<GovernmentBody>>((
  ref,
) async {
  final repo = ref.watch(legalReferenceRepositoryProvider);
  final result = await repo.getActiveGovernmentBodies();
  return switch (result) {
    ResultOk<List<GovernmentBody>>(:final data) => data,
    ResultError<List<GovernmentBody>>(:final failure) => throw failure,
  };
});
