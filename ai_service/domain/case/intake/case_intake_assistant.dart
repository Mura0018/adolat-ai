import '../case_category.dart';
import 'case_intake_question.dart';

/// Foydalanuvchi tavsifiga qarab ANIQLASHTIRUVCHI savollar generatsiya
/// qiluvchi CHEGARA (Module 5, Phase 5B talabi: "User Problem Intake
/// Flow" -- "AI asks clarification questions").
///
/// **`AIRepository`/`AIProviderAdapter` (Module 4) bilan ADASHTIRILMASIN,
/// ATAYLAB mustaqil:** talab: "Connect existing AI conversation
/// foundation with cases... No AI provider dependency" va "Use mock AI
/// responses only". Bu interfeys HECH QACHON `AIProviderId`/
/// `AIProviderAdapter`ni import qilmaydi -- haqiqiy AI mulohaza
/// yuritish (reasoning) shu chegaraning ORQASIDA (implementatsiyada)
/// bo'lishi mumkin bo'lgan kelgusi bosqich, lekin bu ATAYLAB Module
/// 4'ning provayder zanjiridan MUSTAQIL yo'l -- ish (case) intake
/// oqimi provayder tanlash/fallback (`docs/adr/ADR-005`) haqida hech
/// narsa bilishi shart emas.
///
/// Foundation implementatsiyasi -- `MockCaseIntakeAssistant`
/// (`mock_case_intake_assistant.dart`), OLDINDAN TAYYORLANGAN,
/// deterministik savollar bilan (talab: "DO NOT connect real AI
/// providers").
abstract interface class CaseIntakeAssistant {
  Future<List<CaseIntakeQuestion>> generateClarificationQuestions({
    required String problemDescription,
    required CaseCategory category,
  });
}
