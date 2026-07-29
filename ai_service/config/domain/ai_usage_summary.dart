import '../../domain/entities/ai_provider_id.dart';

/// Bitta provayder, bitta davr (period) uchun agregatlangan foydalanish
/// ko'rsatkichi (Module 5, Phase 5A talabi: "usage monitoring").
///
/// **`domain/accounting/ai_token_accounting.dart` (Module 4, Phase 4B)
/// bilan munosabati:** `AITokenAccountingEntry` -- BITTA so'rovga oid
/// xom yozuv. `AIUsageSummary` (shu fayl) -- ko'plab yozuvning
/// AGREGATSIYASI (masalan "kecha OpenAI uchun jami nechta so'rov,
/// nechta token, qancha xarajat") -- admin panelning "Usage Monitoring"
/// ekrani shu shaklni ko'rsatishi mo'ljallangan. Agregatsiyani QANDAY
/// hisoblash (SQL `SUM`/`COUNT` yoki boshqa) bu klassning ishi emas --
/// `AIUsageMonitoringService` (`admin/ai_usage_monitoring_service.dart`)
/// interfeysi orqali ta'minlanadi.
class AIUsageSummary {
  const AIUsageSummary({
    required this.providerId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalRequests,
    required this.totalPromptTokens,
    required this.totalCompletionTokens,
    required this.totalCost,
    required this.currency,
  }) : assert(totalRequests >= 0, 'totalRequests manfiy bo\'lishi mumkin emas'),
       assert(totalPromptTokens >= 0, 'totalPromptTokens manfiy bo\'lishi mumkin emas'),
       assert(totalCompletionTokens >= 0, 'totalCompletionTokens manfiy bo\'lishi mumkin emas'),
       assert(totalCost >= 0, 'totalCost manfiy bo\'lishi mumkin emas');

  final AIProviderId providerId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int totalRequests;
  final int totalPromptTokens;
  final int totalCompletionTokens;
  final double totalCost;
  final String currency;

  int get totalTokens => totalPromptTokens + totalCompletionTokens;

  Map<String, dynamic> toJson() => {
    'providerId': providerId.name,
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
    'totalRequests': totalRequests,
    'totalPromptTokens': totalPromptTokens,
    'totalCompletionTokens': totalCompletionTokens,
    'totalCost': totalCost,
    'currency': currency,
  };

  factory AIUsageSummary.fromJson(Map<String, dynamic> json) {
    return AIUsageSummary(
      providerId: AIProviderId.values.byName(json['providerId'] as String),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      totalRequests: json['totalRequests'] as int,
      totalPromptTokens: json['totalPromptTokens'] as int,
      totalCompletionTokens: json['totalCompletionTokens'] as int,
      totalCost: (json['totalCost'] as num).toDouble(),
      currency: json['currency'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIUsageSummary &&
            other.providerId == providerId &&
            other.periodStart == periodStart &&
            other.periodEnd == periodEnd &&
            other.totalRequests == totalRequests &&
            other.totalPromptTokens == totalPromptTokens &&
            other.totalCompletionTokens == totalCompletionTokens &&
            other.totalCost == totalCost &&
            other.currency == currency);
  }

  @override
  int get hashCode => Object.hash(
    providerId,
    periodStart,
    periodEnd,
    totalRequests,
    totalPromptTokens,
    totalCompletionTokens,
    totalCost,
    currency,
  );

  @override
  String toString() =>
      'AIUsageSummary(providerId: $providerId, totalRequests: $totalRequests, '
      'totalCost: $totalCost $currency)';
}
