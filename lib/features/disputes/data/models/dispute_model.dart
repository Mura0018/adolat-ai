// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/dispute.dart';
import '../../domain/entities/dispute_respondent_type.dart';
import '../../domain/entities/dispute_status.dart';

part 'dispute_model.freezed.dart';
part 'dispute_model.g.dart';

/// `public.disputes` qatoriga mos JSON-serializable DTO
/// (docs/DATABASE.md, 6-jadval).
@freezed
class DisputeModel with _$DisputeModel {
  const factory DisputeModel({
    required String id,
    @JsonKey(name: 'initiator_id') required String initiatorId,
    @JsonKey(name: 'respondent_profile_id') String? respondentProfileId,
    @JsonKey(name: 'respondent_display_name') String? respondentDisplayName,
    @JsonKey(name: 'respondent_type') required String respondentType,
    @JsonKey(name: 'category_id') required String categoryId,
    required String title,
    required String description,
    @JsonKey(name: 'respondent_statement') String? respondentStatement,
    required String status,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @JsonKey(name: 'closed_at') String? closedAt,
  }) = _DisputeModel;

  factory DisputeModel.fromJson(Map<String, dynamic> json) =>
      _$DisputeModelFromJson(json);
}

extension DisputeModelX on DisputeModel {
  Dispute toEntity() {
    return Dispute(
      id: id,
      initiatorId: initiatorId,
      respondentProfileId: respondentProfileId,
      respondentDisplayName: respondentDisplayName,
      respondentType: DisputeRespondentType.fromDbValue(respondentType),
      categoryId: categoryId,
      title: title,
      description: description,
      respondentStatement: respondentStatement,
      status: DisputeStatus.fromDbValue(status),
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
      closedAt: closedAt == null ? null : DateTime.parse(closedAt!),
    );
  }
}
