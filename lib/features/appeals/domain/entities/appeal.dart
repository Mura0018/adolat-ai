import 'package:freezed_annotation/freezed_annotation.dart';

import 'appeal_status.dart';

part 'appeal.freezed.dart';

/// `public.appeals` qatoriga mos sof domain obyekti
/// (docs/DATABASE.md, 5-jadval).
@freezed
class Appeal with _$Appeal {
  const factory Appeal({
    required String id,
    required String authorId,
    required String categoryId,
    required String recipientBodyId,
    required String title,
    required String bodyText,
    String? aiDraftText,
    required AppealStatus status,
    String? officialResponseText,
    DateTime? submittedAt,
    DateTime? closedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Appeal;
}
