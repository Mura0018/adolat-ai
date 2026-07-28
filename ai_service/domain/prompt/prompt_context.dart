/// Prompt pipeline'ning bitta mustaqil bo'lagi (Module 4 talabi: "Each
/// must be independent and composable"). Har bir implementatsiya
/// (`SystemContext`, `UserContext`, `CaseContext`, `MemoryContext`,
/// `SafetyContext`) boshqalaridan bexabar — faqat o'z ma'lumotini
/// tuzilgan shaklda (`toPromptData()`) taqdim etadi.
///
/// **Muhim:** `toPromptData()` tayyor prompt MATNI qaytarmaydi — faqat
/// xom, strukturaviy ma'lumot. Bu ma'lumotni haqiqiy prompt matniga
/// aylantirish (templating/formatting) Module 4, Phase 1 doirasidan
/// tashqarida qoldirilgan ("Do NOT write prompts").
abstract interface class PromptContext {
  /// `AIContext.sections`dagi kalit — masalan `'system'`, `'case'`.
  String get contextKey;

  Map<String, dynamic> toPromptData();
}
