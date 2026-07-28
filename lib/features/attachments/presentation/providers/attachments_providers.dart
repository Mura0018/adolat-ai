import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/result.dart';
import '../../data/datasources/attachments_remote_datasource.dart';
import '../../data/repositories/attachments_repository_impl.dart';
import '../../domain/entities/case_attachment.dart';
import '../../domain/repositories/attachments_repository.dart';

final attachmentsRepositoryProvider = Provider<AttachmentsRepository>((ref) {
  return AttachmentsRepositoryImpl(AttachmentsRemoteDataSource());
});

/// Berilgan murojaatga biriktirilgan fayllar ro'yxati.
final appealAttachmentsProvider =
    FutureProvider.family<List<CaseAttachment>, String>((
      ref,
      appealId,
    ) async {
      final repo = ref.watch(attachmentsRepositoryProvider);
      final result = await repo.listForAppeal(appealId);
      return switch (result) {
        ResultOk(:final data) => data,
        ResultError(:final failure) => throw failure,
      };
    });

/// Berilgan nizoga biriktirilgan fayllar ro'yxati.
final disputeAttachmentsProvider =
    FutureProvider.family<List<CaseAttachment>, String>((
      ref,
      disputeId,
    ) async {
      final repo = ref.watch(attachmentsRepositoryProvider);
      final result = await repo.listForDispute(disputeId);
      return switch (result) {
        ResultOk(:final data) => data,
        ResultError(:final failure) => throw failure,
      };
    });
