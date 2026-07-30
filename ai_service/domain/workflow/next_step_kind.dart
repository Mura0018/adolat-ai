/// Foydalanuvchi/tizim uchun KEYINGI QADAMning TURI (Module 5, Phase 5C).
///
/// **Bitta enum, ikkita iste'molchi:** `Recommendation`
/// (`recommendation/recommendation.dart` -- tavsiya MANBAI, kelgusida
/// haqiqiy AI bilan almashtiriladigan) va `ActionPlanStep`
/// (`action_plan/action_plan_step.dart` -- tavsiyalardan tuzilgan
/// TARTIBLI reja). Ataylab ikkita alohida (bir xil qiymatli) enum
/// YARATILMADI -- `DEVELOPMENT_RULES.md`, 7-band (DRY): reja qadami
/// va tavsiya qadami MOHIYATAN bir xil narsani (nima qilish kerak)
/// bildiradi, farqi faqat qayerda turishida.
///
/// **"No legal conclusions":** hamma qiymatlar JARAYON qadamlari --
/// "ma'lumot to'plang", "ko'rib chiqing", "mutaxassisga murojaat
/// qiling". HECH BIR qiymat huquqiy xulosa/natija bildirmaydi
/// (masalan "sud yutasiz", "shikoyat asosli" kabi qiymat ATAYLAB
/// yo'q va kelgusida ham bu yerga qo'shilmasligi kerak).
enum NextStepKind {
  /// Yetishmayotgan ma'lumot bo'lagini to'ldirish kerak
  /// (`InformationRequirement` bilan bog'lanadi).
  collectInformation,

  /// To'plangan ma'lumotni foydalanuvchi bilan birga ko'rib chiqish/
  /// tasdiqlash.
  reviewCollectedInformation,

  /// Hujjat tayyorlash bosqichiga o'tishga TAYYOR -- **hujjatning
  /// O'ZI bu bosqichda GENERATSIYA QILINMAYDI** (talab: "No document
  /// generation"). Nomdagi `Later` ataylab: bu qadam faqat kelgusi
  /// bosqichga ishora qiladi.
  prepareDocumentLater,

  /// Malakali mutaxassis (yurist)ga murojaat qilish -- AI xulosasi
  /// EMAS, balki jarayonni odamga TOPSHIRISH (hand-off). `docs/
  /// DEVELOPMENT_RULES.md`, 16-band ("AI hech qachon bir tomon
  /// foydasiga qaror chiqarmaydi") shu qadamning mavjudlik sababi.
  consultHumanSpecialist,
}
