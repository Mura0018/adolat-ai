/// Bitta AI provayder uchun xarajat nazorati parametrlari (Module 5,
/// Phase 5A talabi: "cost control parameters") --
/// `docs/adr/ADR-004-ai-cost-governance.md`, Variant C ("global xarajat
/// byudjeti asosidagi circuit breaker")ning admin tomonidan
/// sozlanadigan shakli.
///
/// **`domain/accounting/ai_token_accounting.dart` (Module 4, Phase 4B)
/// bilan munosabati:** `AITokenCostRate`/`AITokenAccountingEntry` --
/// xarajatni HISOBLASH (bitta so'rov qancha turadi). `AIProviderCostControlParams`
/// (shu fayl) esa hisoblangan xarajatga nisbatan QARORNI belgilaydi
/// (qachon ogohlantirish, qachon to'xtatish). Ikkalasi birgalikda
/// ADR-004'ning to'liq zanjirini yopadi -- hisoblash + nazorat.
class AIProviderCostControlParams {
  const AIProviderCostControlParams({
    required this.dailyBudget,
    required this.monthlyBudget,
    required this.currency,
    required this.alertThresholdRatio,
  }) : assert(dailyBudget > 0, 'dailyBudget musbat bo\'lishi kerak'),
       assert(monthlyBudget > 0, 'monthlyBudget musbat bo\'lishi kerak'),
       assert(
         alertThresholdRatio > 0 && alertThresholdRatio <= 1,
         'alertThresholdRatio (0, 1] oralig\'ida bo\'lishi kerak',
       );

  /// Kunlik xarajat chegarasi -- yetilganda `docs/adr/ADR-004`,
  /// "Tavsiya etilgan qaror"ga muvofiq yangi so'rovlar RAD ETILMAYDI,
  /// navbatga qo'yiladi (haqiqiy navbat mexanizmi hali qurilmagan).
  final double dailyBudget;

  final double monthlyBudget;

  /// ISO 4217 valyuta kodi (masalan `'USD'`) --
  /// `AITokenCostRate.currency` (Phase 4B) bilan bir xil konventsiya.
  final String currency;

  /// Byudjetning qaysi ulushida (masalan `0.8` = 80%) admin'ga
  /// ogohlantirish yuborilishi kerak -- `docs/SECURITY.md`,
  /// "Monitoring" bo'limidagi umumiy tamoyilga muvofiq.
  final double alertThresholdRatio;

  Map<String, dynamic> toJson() => {
    'dailyBudget': dailyBudget,
    'monthlyBudget': monthlyBudget,
    'currency': currency,
    'alertThresholdRatio': alertThresholdRatio,
  };

  factory AIProviderCostControlParams.fromJson(Map<String, dynamic> json) {
    return AIProviderCostControlParams(
      dailyBudget: (json['dailyBudget'] as num).toDouble(),
      monthlyBudget: (json['monthlyBudget'] as num).toDouble(),
      currency: json['currency'] as String,
      alertThresholdRatio: (json['alertThresholdRatio'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIProviderCostControlParams &&
            other.dailyBudget == dailyBudget &&
            other.monthlyBudget == monthlyBudget &&
            other.currency == currency &&
            other.alertThresholdRatio == alertThresholdRatio);
  }

  @override
  int get hashCode => Object.hash(dailyBudget, monthlyBudget, currency, alertThresholdRatio);

  @override
  String toString() =>
      'AIProviderCostControlParams(dailyBudget: $dailyBudget $currency, '
      'monthlyBudget: $monthlyBudget $currency)';
}
