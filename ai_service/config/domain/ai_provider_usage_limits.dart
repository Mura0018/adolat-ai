/// Bitta AI provayder darajasidagi (barcha foydalanuvchilar bo'yicha
/// UMUMIY) so'rov cheklovi (Module 5, Phase 5A talabi: "usage limits").
///
/// **`domain/quota/ai_usage_quota.dart` (Module 4, Phase 4B/4C) bilan
/// ADASHTIRILMASIN -- ikkalasi boshqa-boshqa O'QDA (axis) ishlaydi:**
/// - `AIUsageQuotaPolicy` -- FOYDALANUVCHI darajasida (bitta foydalanuvchi
///   kuniga nechta so'rov yubora oladi) -- mahsulot/biznes chegarasi.
/// - `AIProviderUsageLimits` (shu fayl) -- PROVAYDER darajasida (bitta
///   provayderga UMUMIY, barcha foydalanuvchilardan qancha so'rov
///   yuborilishi mumkin) -- vendor/tashqi API cheklovidan (masalan
///   OpenAI'ning o'zi soatiga N so'rovdan ortig'ini rad etishi) himoya.
///
/// Ikkalasi BIRGALIKDA ishlaydi (`docs/adr/ADR-004-ai-cost-governance.md`,
/// Variant D: foydalanuvchi chegarasi + global byudjet/cheklov) -- bitta
/// so'rov ikkala tekshiruvdan ham o'tishi kerak.
class AIProviderUsageLimits {
  const AIProviderUsageLimits({
    required this.maxRequestsPerDay,
    required this.maxConcurrentRequests,
  }) : assert(maxRequestsPerDay > 0, 'maxRequestsPerDay musbat bo\'lishi kerak'),
       assert(maxConcurrentRequests > 0, 'maxConcurrentRequests musbat bo\'lishi kerak');

  /// Shu provayderga kuniga UMUMIY (barcha foydalanuvchilar bo'yicha)
  /// ruxsat etilgan maksimal so'rov soni.
  final int maxRequestsPerDay;

  /// Bir vaqtning o'zida shu provayderga yuborilishi mumkin bo'lgan
  /// maksimal PARALLEL so'rov soni.
  final int maxConcurrentRequests;

  Map<String, dynamic> toJson() => {
    'maxRequestsPerDay': maxRequestsPerDay,
    'maxConcurrentRequests': maxConcurrentRequests,
  };

  factory AIProviderUsageLimits.fromJson(Map<String, dynamic> json) {
    return AIProviderUsageLimits(
      maxRequestsPerDay: json['maxRequestsPerDay'] as int,
      maxConcurrentRequests: json['maxConcurrentRequests'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIProviderUsageLimits &&
            other.maxRequestsPerDay == maxRequestsPerDay &&
            other.maxConcurrentRequests == maxConcurrentRequests);
  }

  @override
  int get hashCode => Object.hash(maxRequestsPerDay, maxConcurrentRequests);

  @override
  String toString() =>
      'AIProviderUsageLimits(maxRequestsPerDay: $maxRequestsPerDay, '
      'maxConcurrentRequests: $maxConcurrentRequests)';
}
