import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/government_body.dart';

part 'government_body_model.freezed.dart';
part 'government_body_model.g.dart';

/// `public.government_bodies` qatoriga mos JSON-serializable DTO
/// (docs/DATABASE.md, 4-jadval).
@freezed
class GovernmentBodyModel with _$GovernmentBodyModel {
  const factory GovernmentBodyModel({
    required String id,
    required String name,
    String? region,
  }) = _GovernmentBodyModel;

  factory GovernmentBodyModel.fromJson(Map<String, dynamic> json) =>
      _$GovernmentBodyModelFromJson(json);
}

extension GovernmentBodyModelX on GovernmentBodyModel {
  GovernmentBody toEntity() {
    return GovernmentBody(id: id, name: name, region: region);
  }
}
