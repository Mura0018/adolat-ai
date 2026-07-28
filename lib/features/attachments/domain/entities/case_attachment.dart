import 'package:freezed_annotation/freezed_annotation.dart';

import 'case_type.dart';

part 'case_attachment.freezed.dart';

/// `public.attachments` qatoriga mos sof domain obyekti
/// (docs/DATABASE.md, 11-jadval).
@freezed
class CaseAttachment with _$CaseAttachment {
  const factory CaseAttachment({
    required String id,
    required CaseType caseType,
    String? appealId,
    String? disputeId,
    required String uploadedBy,
    required String storagePath,
    required String fileName,
    required String mimeType,
    required int sizeBytes,
    required DateTime createdAt,
  }) = _CaseAttachment;
}
