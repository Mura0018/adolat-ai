// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/app_user.dart';
import '../../domain/entities/organization_details.dart';
import '../../domain/entities/user_role.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

/// `public.profiles` qatoriga mos JSON-serializable DTO
/// (docs/DATABASE.md, 1-jadval).
@freezed
class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    required String id,
    required String role,
    @JsonKey(name: 'full_name') required String fullName,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    @JsonKey(name: 'avatar_url') String? avatarUrl,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
}

extension ProfileModelX on ProfileModel {
  /// `organizationDetails` — `role = organization` bo'lganda
  /// `organization_profiles`dan alohida o'qilib shu yerga uzatiladi
  /// (ikkita jadval, bitta domain entity — `AuthRepositoryImpl`da
  /// birlashtiriladi).
  AppUser toEntity({OrganizationDetails? organizationDetails}) {
    return AppUser(
      id: id,
      role: UserRole.fromDbValue(role),
      fullName: fullName,
      phoneNumber: phoneNumber,
      avatarUrl: avatarUrl,
      organizationDetails: organizationDetails,
      createdAt: DateTime.parse(createdAt),
      updatedAt: DateTime.parse(updatedAt),
    );
  }
}
