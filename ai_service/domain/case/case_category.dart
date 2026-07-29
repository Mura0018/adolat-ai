/// Foydalanuvchi AI bilan qaysi TURDAGI natija uchun ishlayotganini
/// bildiradi (Module 5, Phase 5B talabi: "Case Domain Model" --
/// "The model must support future: complaints, applications, legal
/// assistance, document generation").
///
/// **`AICaseType` (`domain/prompt/ai_case_type.dart`, Module 4, Phase
/// 2B) bilan ADASHTIRILMASIN:** `AICaseType` -- `appeal`/`dispute`,
/// ALLAQACHON MAVJUD, DB-asosli (`docs/DATABASE.md`) rasmiy ish
/// turlari, prompt context yig'ishda ishlatiladi. `CaseCategory` (shu
/// fayl) -- undan BOSHQA, YUQORI darajadagi tushuncha: foydalanuvchi
/// AI bilan suhbatni BOSHLAGANDA nima olishni xohlayotgani (hali
/// rasmiy `appeal`/`dispute`ga aylanmagan, umuman aylanmasligi ham
/// mumkin -- masalan faqat maslahat so'rasa). Kelgusida bitta `Case`
/// natijada bir nechta rasmiy `appeal`/`dispute` yozuviga olib
/// kelishi mumkin -- bu ikkalasi ATAYLAB mustaqil qatlamlar.
enum CaseCategory {
  /// Davlat organi/tashkilotga shikoyat.
  complaint,

  /// Rasmiy ariza/murojaat.
  application,

  /// Ariza/shikoyatga aylanmaydigan, faqat huquqiy maslahat.
  legalAssistance,

  /// Foydalanuvchi uchun hujjat (ariza matni va h.k.) tayyorlash --
  /// **hujjatning O'ZI bu bosqichda generatsiya QILINMAYDI** (talab:
  /// "DO NOT generate final legal documents") -- faqat kelgusida shu
  /// yo'nalishda ishlanadigan ish sifatida belgilanadi.
  documentGeneration,
}
