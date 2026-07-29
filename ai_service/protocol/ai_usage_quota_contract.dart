/// Foydalanuvchi kvotasi holatining SIMLI (wire) shakli (Module 4,
/// Phase 4B talabi: "Usage quota model") -- `gateway/endpoint/
/// ai_backend_endpoint.dart`dagi `AIBackendEndpointId.getUsageQuota`
/// amali shu turni qaytaradi deb mo'ljallangan.
///
/// **`AIRateLimitStatus` (shu bosqich) bilan bir xil shaklga ega, lekin
/// ATAYLAB ALOHIDA klass:** ikkalasi tasodifan bir xil uchta maydonga
/// ega (`limit`/`remaining`/`resetAt`) bo'lsa-da, ular MUSTAQIL
/// tushunchalar (`domain/quota/ai_usage_quota.dart`dagi "Rate limit
/// bilan FARQI" izohiga qarang) -- vaqt o'tishi bilan ularning shakli
/// mustaqil evolyutsiya qilishi kerak (masalan kvotaga kelgusida
/// `planName`/`upgradeUrl` kabi biznes-maydon qo'shilishi mumkin,
/// rate-limit holatiga esa hech qachon kerak bo'lmaydi).
class AIUsageQuotaStatus {
  const AIUsageQuotaStatus({
    required this.limit,
    required this.used,
    required this.resetAt,
  }) : assert(limit >= 0, 'limit manfiy bo\'lishi mumkin emas'),
       assert(used >= 0, 'used manfiy bo\'lishi mumkin emas');

  /// Oyna (masalan kunlik) davomida ruxsat etilgan maksimal so'rov soni.
  final int limit;

  /// Joriy oynada sarflangan so'rov soni.
  final int used;

  /// Kvota qachon tiklanadi.
  final DateTime resetAt;

  int get remaining => (limit - used) < 0 ? 0 : (limit - used);

  bool get isExceeded => used >= limit;

  Map<String, dynamic> toJson() => {
    'limit': limit,
    'used': used,
    'resetAt': resetAt.toIso8601String(),
  };

  factory AIUsageQuotaStatus.fromJson(Map<String, dynamic> json) {
    return AIUsageQuotaStatus(
      limit: json['limit'] as int,
      used: json['used'] as int,
      resetAt: DateTime.parse(json['resetAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIUsageQuotaStatus &&
            other.limit == limit &&
            other.used == used &&
            other.resetAt == resetAt);
  }

  @override
  int get hashCode => Object.hash(limit, used, resetAt);

  @override
  String toString() => 'AIUsageQuotaStatus(used: $used/$limit, resetAt: $resetAt)';
}
