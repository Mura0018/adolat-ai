import 'package:freezed_annotation/freezed_annotation.dart';

part 'organization_details.freezed.dart';

/// `public.organization_profiles` qatoriga mos sof domain obyekti
/// (docs/DATABASE.md, 2-jadval). `role = organization` bo'lgan
/// `AppUser`larda mavjud bo'ladi.
@freezed
class OrganizationDetails with _$OrganizationDetails {
  const factory OrganizationDetails({
    required String legalName,
    required String taxId,
    required String legalAddress,
    String? contactEmail,
  }) = _OrganizationDetails;
}
