// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/organization_details.dart';

part 'organization_profile_model.freezed.dart';
part 'organization_profile_model.g.dart';

/// `public.organization_profiles` qatoriga mos JSON-serializable DTO
/// (docs/DATABASE.md, 2-jadval).
@freezed
class OrganizationProfileModel with _$OrganizationProfileModel {
  const factory OrganizationProfileModel({
    @JsonKey(name: 'profile_id') required String profileId,
    @JsonKey(name: 'legal_name') required String legalName,
    @JsonKey(name: 'tax_id') required String taxId,
    @JsonKey(name: 'legal_address') required String legalAddress,
    @JsonKey(name: 'contact_email') String? contactEmail,
  }) = _OrganizationProfileModel;

  factory OrganizationProfileModel.fromJson(Map<String, dynamic> json) =>
      _$OrganizationProfileModelFromJson(json);
}

extension OrganizationProfileModelX on OrganizationProfileModel {
  OrganizationDetails toEntity() {
    return OrganizationDetails(
      legalName: legalName,
      taxId: taxId,
      legalAddress: legalAddress,
      contactEmail: contactEmail,
    );
  }
}
