import 'dart:typed_data';

import '../../../../core/network/result.dart';
import '../entities/case_attachment.dart';
import '../entities/case_type.dart';

/// Murojaat/nizoga biriktirilgan dalil fayllari uchun abstrakt shartnoma
/// (docs/DATABASE.md, 11-jadval "RLS talablari").
abstract interface class AttachmentsRepository {
  /// Faylni `case-attachments` bucket'iga yuklaydi va
  /// `public.attachments`ga mos yozuvni yaratadi. `caseId` — allaqachon
  /// yaratilgan (draft) appeal/dispute identifikatori bo'lishi shart,
  /// chunki Storage RLS mavjud case'ga egalikni tekshiradi (supabase/
  /// migrations/20260726000003_storage_foundation.sql).
  Future<Result<CaseAttachment>> upload({
    required CaseType caseType,
    required String caseId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  });

  Future<Result<List<CaseAttachment>>> listForAppeal(String appealId);

  Future<Result<List<CaseAttachment>>> listForDispute(String disputeId);

  Future<Result<String>> getSignedDownloadUrl(String storagePath);

  Future<Result<void>> delete(CaseAttachment attachment);
}
