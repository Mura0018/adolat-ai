/// Rate-limit holatining SIMLI (wire) shakli -- klient qancha so'rov
/// yubora olishi qolganini bilishi uchun (Module 4, Phase 4B talabi:
/// "Rate-limit contract").
///
/// **`AIProtocolErrorCode.rateLimited` (Phase 3A) bilan munosabati:**
/// o'sha kod faqat "cheklovga yetdingiz" degan BINAR faktni bildiradi.
/// `AIRateLimitStatus` shu faktning KENGAYTIRILGAN shakli -- nechta
/// so'rov qolgani, chegara nechta va qachon tiklanishi. Bu ma'lumot
/// ikki holatda foydali: (1) so'rov RAD ETILGANDA -- nega va qachon
/// qayta urinish kerakligini aniq ko'rsatish (`DEVELOPMENT_RULES.md`,
/// 17-band -- "No Dead End Rule"); (2) so'rov MUVAFFAQIYATLI
/// bo'lganda ham -- klient UI'da "bugun yana N ta so'rov qolgan" kabi
/// oldindan ogohlantirish ko'rsatishi uchun (chegara kelib qolishidan
/// OLDIN, kutilmagan rad javobidan saqlaydi).
///
/// **Qayerga biriktirilishi:** hozircha `AIResponseEnvelope`/
/// `AIProtocolStreamEvent`ning HECH BIRIGA ulanmagan -- bu ATAYLAB,
/// mavjud simli konvertlarni o'zgartirish ularning bir nechta joyda
/// (backend + klient mirror) test qilingan shaklini buzish xavfini
/// tug'diradi. Ulash usuli (masalan `AIResponseEnvelope`ga yangi
/// ixtiyoriy maydon sifatida) kelgusi integratsiya bosqichida hal
/// qilinadi -- bu bosqich faqat SHAKLNI belgilaydi (`AITokenUsage`,
/// Phase 3A bilan bir xil konventsiya).
class AIRateLimitStatus {
  const AIRateLimitStatus({
    required this.limit,
    required this.remaining,
    required this.resetAt,
  }) : assert(remaining >= 0, 'remaining manfiy bo\'lishi mumkin emas'),
       assert(limit >= 0, 'limit manfiy bo\'lishi mumkin emas');

  /// Oyna (window) davomida ruxsat etilgan maksimal so'rov soni.
  final int limit;

  /// Joriy oynada qolgan so'rov soni. `0` -- cheklovga yetilgan.
  final int remaining;

  /// Oyna qachon tiklanadi (hisoblagich nolga qaytadi).
  final DateTime resetAt;

  bool get isExceeded => remaining <= 0;

  Map<String, dynamic> toJson() => {
    'limit': limit,
    'remaining': remaining,
    'resetAt': resetAt.toIso8601String(),
  };

  factory AIRateLimitStatus.fromJson(Map<String, dynamic> json) {
    return AIRateLimitStatus(
      limit: json['limit'] as int,
      remaining: json['remaining'] as int,
      resetAt: DateTime.parse(json['resetAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIRateLimitStatus &&
            other.limit == limit &&
            other.remaining == remaining &&
            other.resetAt == resetAt);
  }

  @override
  int get hashCode => Object.hash(limit, remaining, resetAt);

  @override
  String toString() =>
      'AIRateLimitStatus(remaining: $remaining/$limit, resetAt: $resetAt)';
}
