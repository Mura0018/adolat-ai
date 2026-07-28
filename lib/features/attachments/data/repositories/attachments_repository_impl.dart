import 'dart:typed_data';

import '../../../../core/network/result.dart';
import '../../../../services/supabase/supabase_exception_mapper.dart';
import '../../domain/entities/case_attachment.dart';
import '../../domain/entities/case_type.dart';
import '../../domain/repositories/attachments_repository.dart';
import '../datasources/attachments_remote_datasource.dart';
import '../models/case_attachment_model.dart';

class AttachmentsRepositoryImpl implements AttachmentsRepository {
  AttachmentsRepositoryImpl(this._remote);

  final AttachmentsRemoteDataSource _remote;

  @override
  Future<Result<CaseAttachment>> upload({
    required CaseType caseType,
    required String caseId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    try {
      final model = await _remote.upload(
        caseType: caseType,
        caseId: caseId,
        fileName: fileName,
        bytes: bytes,
        contentType: contentType,
      );
      return Result.ok(model.toEntity());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<List<CaseAttachment>>> listForAppeal(String appealId) async {
    try {
      final models = await _remote.listForAppeal(appealId);
      return Result.ok(models.map((m) => m.toEntity()).toList());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<List<CaseAttachment>>> listForDispute(
    String disputeId,
  ) async {
    try {
      final models = await _remote.listForDispute(disputeId);
      return Result.ok(models.map((m) => m.toEntity()).toList());
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<String>> getSignedDownloadUrl(String storagePath) async {
    try {
      final url = await _remote.getSignedDownloadUrl(storagePath);
      return Result.ok(url);
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }

  @override
  Future<Result<void>> delete(CaseAttachment attachment) async {
    try {
      await _remote.delete(
        id: attachment.id,
        storagePath: attachment.storagePath,
      );
      return const Result.ok(null);
    } catch (error) {
      return Result.error(mapSupabaseExceptionToFailure(error));
    }
  }
}
