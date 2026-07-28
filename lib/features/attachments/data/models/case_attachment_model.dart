// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/case_attachment.dart';
import '../../domain/entities/case_type.dart';

part 'case_attachment_model.freezed.dart';
part 'case_attachment_model.g.dart';

/// `public.attachments` qatoriga mos JSON-serializable DTO
/// (docs/DATABASE.md, 11-jadval).
@freezed
class CaseAttachmentModel with _$CaseAttachmentModel {
  const factory CaseAttachmentModel({
    required String id,
    @JsonKey(name: 'case_type') required String caseType,
    @JsonKey(name: 'appeal_id') String? appealId,
    @JsonKey(name: 'dispute_id') String? disputeId,
    @JsonKey(name: 'uploaded_by') required String uploadedBy,
    @JsonKey(name: 'storage_path') required String storagePath,
    @JsonKey(name: 'file_name') required String fileName,
    @JsonKey(name: 'mime_type') required String mimeType,
    @JsonKey(name: 'size_bytes') required int sizeBytes,
    @JsonKey(name: 'created_at') required String createdAt,
  }) = _CaseAttachmentModel;

  factory CaseAttachmentModel.fromJson(Map<String, dynamic> json) =>
      _$CaseAttachmentModelFromJson(json);
}

extension CaseAttachmentModelX on CaseAttachmentModel {
  CaseAttachment toEntity() {
    return CaseAttachment(
      id: id,
      caseType: CaseType.fromDbValue(caseType),
      appealId: appealId,
      disputeId: disputeId,
      uploadedBy: uploadedBy,
      storagePath: storagePath,
      fileName: fileName,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      createdAt: DateTime.parse(createdAt),
    );
  }
}
