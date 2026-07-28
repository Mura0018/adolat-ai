import 'package:freezed_annotation/freezed_annotation.dart';

import 'dispute_respondent_type.dart';
import 'dispute_status.dart';

part 'dispute.freezed.dart';

/// `public.disputes` qatoriga mos sof domain obyekti
/// (docs/DATABASE.md, 6-jadval).
@freezed
class Dispute with _$Dispute {
  const factory Dispute({
    required String id,
    required String initiatorId,
    String? respondentProfileId,
    String? respondentDisplayName,
    required DisputeRespondentType respondentType,
    required String categoryId,
    required String title,
    required String description,
    String? respondentStatement,
    required DisputeStatus status,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? closedAt,
  }) = _Dispute;
}
