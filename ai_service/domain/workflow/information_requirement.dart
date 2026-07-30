/// Ma'lumot bo'lagining MAJBURIYLIK darajasi -- `mandatory` bo'lganlar
/// to'ldirilmaguncha ish "to'liq ma'lumotga ega" deb HISOBLANMAYDI
/// (`completeness/information_completeness.dart`, `isSufficient`).
///
/// **Nega `required` emas:** `required` -- Dart'ning o'rnatilgan
/// identifikatori (built-in identifier), enum qiymati sifatida
/// chalkashlik keltiradi.
enum InformationImportance { mandatory, optional }

/// Ish (case) bo'yicha to'planishi kerak bo'lgan BITTA ma'lumot
/// bo'lagi -- "slot" (Module 5, Phase 5C talabi: "AI determines
/// missing information").
///
/// **Savol va yetishmayotgan ma'lumot -- BIR narsaning ikki tomoni:**
/// [question] aynan shu bo'lakni to'ldirish uchun beriladigan
/// aniqlashtiruvchi savol. Shuning uchun "qaysi ma'lumot yetishmayapti"
/// va "qaysi savolni berish kerak" YAGONA manbadan
/// (`InformationRequirementCatalog`) keladi -- ikkita alohida ro'yxat
/// saqlanmaydi (`DEVELOPMENT_RULES.md`, 7-band, DRY).
///
/// **"No legal judgement":** [id]/[question] faqat FAKT so'raydi
/// ("voqea qachon bo'lgan?", "qaysi organga?") -- hech bir talab
/// huquqiy baho/xulosa (masalan "sizning huquqingiz buzilganmi?")
/// so'ramaydi va kelgusida ham so'ramasligi kerak.
class InformationRequirement {
  const InformationRequirement({
    required this.id,
    required this.question,
    this.importance = InformationImportance.mandatory,
  });

  /// Barqaror, mashinaga mo'ljallangan identifikator (masalan
  /// `complaint_target`) -- `CollectedInformation`ning kaliti VA
  /// `CaseIntakeQuestion.id` (Module 5, Phase 5B) shu qiymatni
  /// ishlatadi, shu bilan foydalanuvchining javobi to'g'ridan-to'g'ri
  /// kerakli bo'lakka bog'lanadi.
  final String id;

  /// Foydalanuvchiga ko'rsatiladigan aniqlashtiruvchi savol matni.
  final String question;

  final InformationImportance importance;

  bool get isMandatory => importance == InformationImportance.mandatory;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is InformationRequirement &&
            other.id == id &&
            other.question == question &&
            other.importance == importance);
  }

  @override
  int get hashCode => Object.hash(id, question, importance);

  @override
  String toString() => 'InformationRequirement(id: $id, importance: ${importance.name})';
}
