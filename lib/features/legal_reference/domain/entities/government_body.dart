import 'package:freezed_annotation/freezed_annotation.dart';

part 'government_body.freezed.dart';

/// `public.government_bodies`ga mos sof domain obyekti
/// (docs/DATABASE.md, 4-jadval).
@freezed
class GovernmentBody with _$GovernmentBody {
  const factory GovernmentBody({
    required String id,
    required String name,
    String? region,
  }) = _GovernmentBody;
}
