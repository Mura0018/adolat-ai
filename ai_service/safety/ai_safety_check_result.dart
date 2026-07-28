/// `AISafetyService`ning tekshiruv natijasi.
///
/// Freezed ishlatilmagan sababi: `ai_service/domain/entities/
/// ai_message.dart`dagi izohga qarang (`ai_service/` `build_runner`
/// kodgen manbai doirasidan tashqarida).
class AISafetyCheckResult {
  const AISafetyCheckResult({required this.isSafe, this.reason});

  final bool isSafe;
  final String? reason;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AISafetyCheckResult &&
            other.isSafe == isSafe &&
            other.reason == reason);
  }

  @override
  int get hashCode => Object.hash(isSafe, reason);

  @override
  String toString() => 'AISafetyCheckResult(isSafe: $isSafe, reason: $reason)';
}
