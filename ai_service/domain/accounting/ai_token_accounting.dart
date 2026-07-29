import '../entities/ai_provider_id.dart';

/// Token sarfini XARAJATGA aylantirish modeli (Module 4, Phase 4B
/// talabi: "Token accounting model") -- `docs/adr/ADR-004-ai-cost-governance.md`
/// ("AI -- mahsulotning eng qimmat doimiy operatsion xarajat moddasi")
/// ning arxitektura darajasidagi ifodasi.
///
/// **`protocol/ai_token_usage.dart` (Phase 3A) bilan munosabati:**
/// `AITokenUsage` -- SIMLI (wire) placeholder, faqat xom son
/// (`promptTokens`/`completionTokens`/`totalTokens`), hech qanday
/// pul birligiga ega emas va domain qatlamidan ATAYLAB mustaqil (`protocol/`
/// konventsiyasi). Bu fayldagi turlar esa backend ICHKI, domain
/// darajasidagi hisob-kitob -- xom token sonini haqiqiy xarajatga
/// (pul birligida) aylantiradi. Ikkalasi orasidagi bog'lovchi
/// [AITokenAccountingEntry.fromRawUsage] -- lekin bu funksiya `AITokenUsage`
/// turini o'zi IMPORT QILMAYDI (`domain/` -> `protocol/` bog'liqligi
/// loyihada hech qayerda yo'q), xom `int?` qiymatlarni parametr sifatida
/// oladi -- tarjima chaqiruvchining (kelgusi gateway/billing qatlami)
/// ishi.
///
/// Provayder narxi vaqt o'tishi bilan o'zgaradi va provayderga qarab
/// farq qiladi -- shuning uchun [AITokenCostRate] konfiguratsiya
/// sifatida in'ektsiya qilinadi, bu faylda hech qanday HAQIQIY narx
/// (masalan "OpenAI $0.03/1K token") qattiq yozilmagan.
class AITokenCostRate {
  const AITokenCostRate({
    required this.providerId,
    required this.currency,
    required this.costPerThousandPromptTokens,
    required this.costPerThousandCompletionTokens,
  }) : assert(
         costPerThousandPromptTokens >= 0 && costPerThousandCompletionTokens >= 0,
         'narx manfiy bo\'lishi mumkin emas',
       );

  final AIProviderId providerId;

  /// ISO 4217 valyuta kodi (masalan `'USD'`) -- hech qanday standart
  /// qiymat yo'q, chaqiruvchi aniq ko'rsatishi shart.
  final String currency;

  final double costPerThousandPromptTokens;
  final double costPerThousandCompletionTokens;
}

/// Bitta AI so'rovi uchun hisoblangan xarajat yozuvi -- kelgusida
/// audit/billing maqsadida saqlanishi mo'ljallangan (`docs/adr/ADR-004`,
/// "Migratsiya ta'siri": "global byudjet holatini saqlovchi bitta
/// konfiguratsiya/holat yozuvi").
class AITokenAccountingEntry {
  const AITokenAccountingEntry({
    required this.conversationId,
    required this.requestId,
    required this.providerId,
    required this.promptTokens,
    required this.completionTokens,
    required this.estimatedCost,
    required this.currency,
    required this.recordedAt,
  }) : assert(promptTokens >= 0 && completionTokens >= 0, 'token soni manfiy bo\'lishi mumkin emas'),
       assert(estimatedCost >= 0, 'xarajat manfiy bo\'lishi mumkin emas');

  final String conversationId;
  final String requestId;
  final AIProviderId providerId;
  final int promptTokens;
  final int completionTokens;
  final double estimatedCost;
  final String currency;
  final DateTime recordedAt;

  int get totalTokens => promptTokens + completionTokens;

  /// Xolis (pure) hisob-kitob funksiyasi -- [rate] va xom token
  /// sonlaridan yozuv yaratadi. [providerId] [rate.providerId] bilan
  /// mos kelishi shart (aks holda notog'ri narx qo'llanadi) --
  /// invariant `assert` bilan majburlangan (loyihaning boshqa
  /// joylaridagi, masalan `CaseContext`ning `caseType` invarianti
  /// bilan bir xil konventsiya).
  factory AITokenAccountingEntry.fromRawUsage({
    required String conversationId,
    required String requestId,
    required AIProviderId providerId,
    required int promptTokens,
    required int completionTokens,
    required AITokenCostRate rate,
    required DateTime recordedAt,
  }) {
    assert(
      rate.providerId == providerId,
      'AITokenCostRate.providerId so\'rov providerId\'siga mos kelishi shart',
    );
    final cost =
        (promptTokens / 1000) * rate.costPerThousandPromptTokens +
        (completionTokens / 1000) * rate.costPerThousandCompletionTokens;
    return AITokenAccountingEntry(
      conversationId: conversationId,
      requestId: requestId,
      providerId: providerId,
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      estimatedCost: cost,
      currency: rate.currency,
      recordedAt: recordedAt,
    );
  }

  @override
  String toString() =>
      'AITokenAccountingEntry(requestId: $requestId, totalTokens: $totalTokens, '
      'estimatedCost: $estimatedCost $currency)';
}
