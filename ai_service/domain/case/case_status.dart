/// `Case`ning hayot davri holati (Module 5, Phase 5B talabi: "Case
/// Lifecycle").
///
/// **Qat'iy tartib:** deklaratsiya tartibi ATAYLAB ma'noli --
/// `understanding` `created`dan KEYIN, `archived` esa hammasidan
/// KEYIN keladi. [isValidCaseStatusTransition] shu tartibga tayanadi.
///
/// **"Do not implement legal decisions":** bu enum FAQAT ish (case)
/// AI bilan muloqot jarayonining QAYSI BOSQICHIDA ekanligini
/// bildiradi -- huquqiy xulosa/qaror emas. `analysisReady`/
/// `actionPlanning` nomlanishi ham ataylab neytral: "tahlilga tayyor"
/// (kim tahlil qilishi ochiq -- AI yordamchisi, keyinchalik yurist),
/// "harakat rejalashtirish" (qanday HARAKAT emas).
enum CaseStatus {
  /// Ish yaratildi, foydalanuvchi muammosini hali batafsil
  /// tushuntirmagan.
  created,

  /// AI (yoki mock yordamchi) foydalanuvchi muammosini tushunishga
  /// harakat qilmoqda -- aniqlashtiruvchi savollar berilmoqda.
  understanding,

  /// Foydalanuvchidan qo'shimcha ma'lumot/hujjat yig'ilmoqda.
  informationGathering,

  /// Yetarli ma'lumot to'plangan -- tahlil uchun tayyor (tahlilning
  /// o'zi bu bosqichda YO'Q).
  analysisReady,

  /// Keyingi qadam (murojaat yozish, hujjat tayyorlash va h.k.)
  /// rejalashtirilmoqda.
  actionPlanning,

  /// Ish yakunlandi.
  completed,

  /// Ish arxivlandi -- YAKUNIY (terminal) holat, bu yerdan boshqa
  /// hech qanday holatga o'tib bo'lmaydi.
  archived;

  /// `archived`dan boshqa hamma narsa "faol" -- foydalanuvchi/AI
  /// bilan hali ishlash mumkin.
  bool get isActive => this != CaseStatus.archived;

  bool get isTerminal => this == CaseStatus.archived;
}

/// [from]dan [to]ga o'tish MANTIQAN to'g'rimi -- xolis (pure) qoida,
/// hech qanday holatni o'zi saqlamaydi/o'zgartirmaydi.
///
/// Qoidalar (eng qattiqdan eng erkinigacha):
/// 1. O'zi-o'ziga "o'tish" YO'Q (`from == to` -- bu o'tish emas).
/// 2. `archived` -- YAKUNIY, undan HECH QAYERGA o'tib bo'lmaydi.
/// 3. Istalgan FAOL holatdan `archived`ga o'tish MUMKIN -- foydalanuvchi
///    istalgan vaqtda ishni "yopib qo'yishi" (abandon) kerak
///    bo'lishi mumkin.
/// 4. `completed`dan FAQAT `archived`ga o'tish mumkin -- qayta ochish
///    (reopen) ATAYLAB qo'llab-quvvatlanmaydi (`AIConversation.close()`,
///    Module 4, Phase 2A bilan bir xil "yopilgan holat YAKUNIY"
///    falsafasi) -- qo'shimcha ma'lumot kerak bo'lsa, YANGI ish
///    yaratilishi kutiladi.
/// 5. Qolgan FAOL holatlar (`created`/`understanding`/
///    `informationGathering`/`analysisReady`/`actionPlanning`) orasida
///    IKKALA yo'nalishda ham erkin harakat mumkin -- AI intake
///    jarayoni tabiatan ITERATIV (masalan `analysisReady`da yetarli
///    ma'lumot yo'qligi aniqlansa, `informationGathering`ga qaytish
///    kerak bo'lishi mumkin).
bool isValidCaseStatusTransition({required CaseStatus from, required CaseStatus to}) {
  if (from == to) return false;
  if (from.isTerminal) return false;
  if (to == CaseStatus.archived) return true;
  if (from == CaseStatus.completed) return false;
  return true;
}
