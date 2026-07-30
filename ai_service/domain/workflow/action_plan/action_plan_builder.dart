import '../recommendation/recommendation.dart';
import 'action_plan.dart';

/// Tavsiyalarni TARTIBLANGAN harakat rejasiga aylantiruvchi chegara
/// (Module 5, Phase 5C talabi: "Action plan foundation -- prepare
/// ordered next-step structure").
///
/// **Nega tavsiya manbaidan (`RecommendationEngine`) ALOHIDA:**
/// tavsiyaning MAZMUNI (nima tavsiya qilinadi) -- almashtiriladigan,
/// kelgusida AI keladigan qism; rejaning TUZILISHI (tartib, raqamlash,
/// invariantlar) -- barqaror, sinaladigan qoida. Ikkalasini bitta
/// klassga qo'shish AI almashtirilganda tuzilma invariantlarini ham
/// qayta yozishga majbur qilardi.
abstract interface class ActionPlanBuilder {
  ActionPlan build({required String caseId, required List<Recommendation> recommendations});
}
