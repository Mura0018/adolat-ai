// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/appeal.dart';
import '../../domain/entities/appeal_status.dart';

part 'appeal_model.freezed.dart';
part 'appeal_model.g.dart';

/// `public.appeals` qatoriga mos JSON-serializable DTO
/// (docs/DATABASE.md, 5-jadval).
@freezed
class AppealModel with _$AppealModel {
  const factory AppealModel({
    required String id,
    @JsonKey(name: 'author_id') required String authorId,
    @JsonKey(name: 'category_id') required String categoryId,
    @JsonKey(name: 'recipient_body_id') required String recipientBodyId,
    required String title,
    @JsonKey(name: 'body_text') required String bodyText,
    @JsonKey(name: 'ai_draft_text') String? aiDraftText,
    required String status,
    @JsonKey(name: 'official_response_text') String? officialResponseText,
    @JsonKey(name: 'submitted_at') String? submittedAt,
    @JsonKey(name: 'closed_at') String? closedAt,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _AppealModel;

  factory AppealModel.fromJson(Map<String, dynamic> json) =>
      _$AppealModelFromJson(json);
}

extension AppealModelX on AppealModel {
  Appeal toEntity() {
    return Appeal(
      id: id,
      authorId: authorId,
      categoryId: categoryId,
      recipientBodyId: recipientBodyId,
      title: title,
      bodyText: bodyText,
      aiDraftText: aiDraftText,
      status: AppealStatus.fromDbValue(status),
      officialResponseText: officialResponseText,
      submittedAt: submittedAt == null ? null : DateTime.parse(submittedAt!),
      closedAt: closedAt == null ? null : DateTime.parse(closedAt!),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
