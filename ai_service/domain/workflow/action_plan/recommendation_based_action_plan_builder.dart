import '../recommendation/recommendation.dart';
import 'action_plan.dart';
import 'action_plan_builder.dart';
import 'action_plan_step.dart';

/// `ActionPlanBuilder`ning XOLIS (pure) implementatsiyasi -- tavsiyalarni
/// `Recommendation.order` bo'yicha tartiblab, uzluksiz raqamlangan
/// qadamlarga aylantiradi.
///
/// **Bu klassda MAZMUN yo'q:** qadam matni (`title`) to'g'ridan-to'g'ri
/// `Recommendation.message`dan olinadi, hech qanday yangi jumla shu
/// yerda YASALMAYDI. Shu sababli "huquqiy maslahat bermaslik" talabi
/// bitta joyda -- `RecommendationEngine` implementatsiyasida --
/// ta'minlanadi, ikki joyda tarqalib ketmaydi.
///
/// **Nega qayta raqamlaydi:** tavsiya manbai (kelgusida haqiqiy AI)
/// `order` qiymatlarida bo'shliq qoldirishi yoki takrorlanishi mumkin.
/// Reja esa foydalanuvchiga "1, 2, 3" bo'lib ko'rsatiladi -- shuning
/// uchun tartib SAQLANADI, lekin raqamlar qayta beriladi
/// (`ActionPlan`ning uzluksizlik invarianti shu bilan har doim
/// bajariladi).
class RecommendationBasedActionPlanBuilder implements ActionPlanBuilder {
  const RecommendationBasedActionPlanBuilder();

  @override
  ActionPlan build({required String caseId, required List<Recommendation> recommendations}) {
    if (recommendations.isEmpty) {
      return ActionPlan.empty(caseId);
    }

    // BARQAROR (stable) tartiblash: `Dart`ning `List.sort()`i
    // barqarorlikni kafolatlamaydi, shuning uchun teng `order`
    // qiymatlarida DASTLABKI ketma-ketlik saqlanishi uchun indeks
    // ikkinchi mezon sifatida ishlatiladi.
    final indexed = [
      for (var i = 0; i < recommendations.length; i++) (index: i, value: recommendations[i]),
    ]..sort((a, b) {
      final byOrder = a.value.order.compareTo(b.value.order);
      return byOrder != 0 ? byOrder : a.index.compareTo(b.index);
    });

    return ActionPlan(
      caseId: caseId,
      steps: [
        for (var i = 0; i < indexed.length; i++)
          ActionPlanStep(
            id: 'plan_${indexed[i].value.id}',
            order: i + 1,
            kind: indexed[i].value.kind,
            title: indexed[i].value.message,
            requirementId: indexed[i].value.requirementId,
          ),
      ],
    );
  }
}
