// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/legal_category.dart';

part 'legal_category_model.freezed.dart';
part 'legal_category_model.g.dart';

/// `public.legal_categories` qatoriga mos JSON-serializable DTO
/// (docs/DATABASE.md, 3-jadval).
@freezed
class LegalCategoryModel with _$LegalCategoryModel {
  const factory LegalCategoryModel({
    required String id,
    @JsonKey(name: 'name_uz') required String nameUz,
    @JsonKey(name: 'name_en') String? nameEn,
    String? description,
  }) = _LegalCategoryModel;

  factory LegalCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$LegalCategoryModelFromJson(json);
}

extension LegalCategoryModelX on LegalCategoryModel {
  LegalCategory toEntity() {
    return LegalCategory(
      id: id,
      nameUz: nameUz,
      nameEn: nameEn,
      description: description,
    );
  }
}
