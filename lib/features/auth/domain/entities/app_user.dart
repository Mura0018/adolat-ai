import 'package:freezed_annotation/freezed_annotation.dart';

import 'organization_details.dart';
import 'user_role.dart';

part 'app_user.freezed.dart';

/// `public.profiles` qatoriga mos sof domain obyekti
/// (docs/DATABASE.md, 1-jadval), `role = organization` bo'lganda
/// `organization_profiles` (2-jadval) bilan birlashtirilgan holda.
///
/// `phoneNumber`/`avatarUrl` nullable — `docs/DATABASE.md`da ham shunday
/// belgilangan. Sezgir maydon (`phoneNumber`) faqat shu entity orqali,
/// repository chegarasi ostida oqadi (`docs/adr/ADR-006-hybrid-infrastructure-strategy.md`).
@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String id,
    required UserRole role,
    required String fullName,
    String? phoneNumber,
    String? avatarUrl,
    OrganizationDetails? organizationDetails,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AppUser;
}
