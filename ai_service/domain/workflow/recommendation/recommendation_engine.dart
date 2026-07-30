import 'recommendation.dart';
import 'recommendation_context.dart';

/// Keyingi qadam tavsiyalarini beruvchi CHEGARA (Module 5, Phase 5C
/// talabi: "Recommendation engine abstraction -- provider-independent,
/// no real AI").
///
/// **Bu -- Phase 5C'ning ASOSIY almashtirish nuqtasi.** Butun ish
/// oqimi (aniqlashtirish → to'liqlik → harakat rejasi) shu
/// interfeysdan boshqa hech qayerda "nima qilish kerak" degan
/// qarorni saqlamaydi:
///
/// ```
/// InformationCompleteness -> RecommendationEngine -> List<Recommendation>
///                                                          |
///                                            ActionPlanBuilder (xolis tartiblash)
///                                                          v
///                                                     ActionPlan
/// ```
///
/// Hozirgi yagona implementatsiya -- `MockRecommendationEngine`
/// (`data/workflow/mock_recommendation_engine.dart`): deterministik,
/// to'liqlik natijasidan KELIB CHIQADIGAN qadamlar. Kelgusida haqiqiy
/// AI shu interfeysning ortiga qo'yiladi -- `ActionPlanBuilder`,
/// usecase'lar va `Case` domeni O'ZGARMAYDI.
///
/// **Provayderdan mustaqil:** interfeys `AIProviderId`/`AIRequest`/
/// `AIRepository` (Module 4)ni import QILMAYDI -- shuning uchun
/// implementatsiya haqiqiy AI'ga ham, oddiy qoidalar to'plamiga ham,
/// backend xizmatiga ham asoslanishi mumkin.
///
/// **`Future` nega:** hozirgi mock sinxron ishlaydi, lekin kelgusi
/// implementatsiya tarmoq chaqiruvi qilishi mumkin --
/// `CaseIntakeAssistant` (Module 5, Phase 5B) bilan bir xil sabab va
/// bir xil imzo uslubi.
abstract interface class RecommendationEngine {
  /// Qaytariladigan ro'yxat `Recommendation.order` bo'yicha
  /// TARTIBLANGAN bo'lishi KUTILADI, lekin `ActionPlanBuilder`
  /// baribir qayta tartiblaydi -- implementatsiyaga ishonch
  /// bilan tayanmaslik uchun.
  Future<List<Recommendation>> recommend(RecommendationContext context);
}
