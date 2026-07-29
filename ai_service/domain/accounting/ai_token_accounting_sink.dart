import 'ai_token_accounting.dart';

/// Hisoblangan xarajat yozuvi qayerga BORISHINI belgilaydigan CHEGARA
/// (Module 4, Phase 4C talabi: "Prepare backend adapter boundaries" --
/// token-hisob uchun) -- **faqat interfeys, hech qanday
/// implementatsiya yo'q** (`AISafetyService` konventsiyasi).
///
/// **`ai_token_accounting.dart` (Phase 4B) bilan munosabati:** o'sha
/// fayl `AITokenAccountingEntry.fromRawUsage()` -- XOLIS (pure) hisob-
/// kitob funksiyasini beradi, lekin natijani QAYERGA yozish (audit
/// jurnali, DB jadvali, monitoring xizmati) haqida hech narsa
/// aytmaydi. `AITokenAccountingSink` aynan shu keyingi qadam.
///
/// **Nega hozircha hech qanday chaqiruv nuqtasi (call site) yo'q:**
/// `protocol/ai_token_usage.dart` (Phase 3A)dagi `AITokenUsage`ning
/// barcha maydonlari hozircha doim `null` -- haqiqiy provayder
/// javobidan token sonini o'qish implementatsiyasi hali yo'q. Shuning
/// uchun bu interfeysni `AIGatewayImpl`/`AIResponseDispatcher`ga
/// ULASH (masalan `completed` hodisasi chiqqanda chaqirish) hozircha
/// HECH QACHON haqiqiy ma'lumot bilan ishlamaydigan "o'lik" kod
/// qo'shgan bo'lardi. Haqiqiy provayder integratsiyasi `tokenUsage`ni
/// to'ldirganda, chaqiruv nuqtasi shu interfeys orqali qo'shiladi --
/// `docs/AI_ARCHITECTURE.md`, "Backend Implementation Readiness
/// (Module 4, Phase 4C)" bo'limiga qarang.
abstract interface class AITokenAccountingSink {
  Future<void> record(AITokenAccountingEntry entry);
}
