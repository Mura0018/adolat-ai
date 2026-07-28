/// `CaseContext.caseType` uchun tur-xavfsiz qiymat — `public.case_type`
/// (`docs/DATABASE.md`, "Umumiy konventsiyalar") bilan kontseptual mos,
/// lekin `ai_service/` `lib/`dan mustaqil bo'lgani uchun mustaqil enum
/// (`ai_user_role.dart`dagi izohga qarang).
enum AICaseType { appeal, dispute }
