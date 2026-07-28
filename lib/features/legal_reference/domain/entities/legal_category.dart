import 'package:freezed_annotation/freezed_annotation.dart';

part 'legal_category.freezed.dart';

/// `public.legal_categories`ga mos sof domain obyekti
/// (docs/DATABASE.md, 3-jadval).
@freezed
class LegalCategory with _$LegalCategory {
  const factory LegalCategory({
    required String id,
    required String nameUz,
    String? nameEn,
    String? description,
  }) = _LegalCategory;
}
