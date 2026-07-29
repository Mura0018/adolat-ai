/// Bitta AI provayder uchun so'rov/javob token hajmi chegarasi (Module
/// 5, Phase 5A talabi: "token limits").
///
/// **`protocol/ai_token_usage.dart` (Module 4, Phase 3A) bilan
/// munosabati:** `AITokenUsage` -- HAQIQIY sarflangan token sonini
/// olib yuruvchi (hozircha doim `null`) simli placeholder.
/// `AIProviderTokenLimits` (shu fayl) esa CHEGARA -- oldindan
/// belgilangan, admin tomonidan sozlanadigan maksimal qiymat. Haqiqiy
/// provayder integratsiyasi qo'shilganda, [maxPromptTokens] so'rov
/// yuborishdan OLDIN (kesish/rad etish uchun), [maxCompletionTokens]
/// esa provayderga uzatiladigan so'rov parametri sifatida (masalan
/// OpenAI'ning `max_tokens`) ishlatilishi mo'ljallangan -- bu bog'lanish
/// hali qurilmagan (`docs/AI_ARCHITECTURE.md`, "AI Configuration and
/// Control Foundation (Module 5, Phase 5A)").
class AIProviderTokenLimits {
  const AIProviderTokenLimits({
    required this.maxPromptTokens,
    required this.maxCompletionTokens,
  }) : assert(maxPromptTokens > 0, 'maxPromptTokens musbat bo\'lishi kerak'),
       assert(maxCompletionTokens > 0, 'maxCompletionTokens musbat bo\'lishi kerak');

  final int maxPromptTokens;
  final int maxCompletionTokens;

  int get maxTotalTokens => maxPromptTokens + maxCompletionTokens;

  Map<String, dynamic> toJson() => {
    'maxPromptTokens': maxPromptTokens,
    'maxCompletionTokens': maxCompletionTokens,
  };

  factory AIProviderTokenLimits.fromJson(Map<String, dynamic> json) {
    return AIProviderTokenLimits(
      maxPromptTokens: json['maxPromptTokens'] as int,
      maxCompletionTokens: json['maxCompletionTokens'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIProviderTokenLimits &&
            other.maxPromptTokens == maxPromptTokens &&
            other.maxCompletionTokens == maxCompletionTokens);
  }

  @override
  int get hashCode => Object.hash(maxPromptTokens, maxCompletionTokens);

  @override
  String toString() =>
      'AIProviderTokenLimits(maxPromptTokens: $maxPromptTokens, '
      'maxCompletionTokens: $maxCompletionTokens)';
}
