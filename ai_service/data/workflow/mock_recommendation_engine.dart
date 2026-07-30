import '../../domain/case/case_category.dart';
import '../../domain/case/case_status.dart';
import '../../domain/workflow/next_step_kind.dart';
import '../../domain/workflow/recommendation/recommendation.dart';
import '../../domain/workflow/recommendation/recommendation_context.dart';
import '../../domain/workflow/recommendation/recommendation_engine.dart';

/// `RecommendationEngine`ning FOUNDATION (mock) implementatsiyasi
/// (Module 5, Phase 5C talablari: "Recommendation engine abstraction --
/// provider-independent, no real AI"; "Mock responses only").
///
/// **Butunlay deterministik va ochiq qoidalarga asoslangan:**
/// 1. Har bir yetishmayotgan MAJBURIY bo'lak → bitta
///    `collectInformation` tavsiyasi (katalog tartibida);
/// 2. keyin yetishmayotgan IXTIYORIY bo'laklar (xuddi shunday);
/// 3. majburiylar to'liq bo'lsa → to'plangan ma'lumotni ko'rib
///    chiqish tavsiyasi;
/// 4. va yakuniy qadam: `documentGeneration` toifasi uchun --
///    hujjat bosqichiga TAYYORLIK (hujjatning O'ZI yaratilmaydi),
///    qolgan toifalar uchun -- malakali mutaxassisga murojaat.
///
/// **Nega 4-qadam har doim odam/keyingi bosqichga ishora qiladi:**
/// `docs/DEVELOPMENT_RULES.md`, 15–16-band -- AI hech qachon bir
/// tomon foydasiga qaror chiqarmaydi. Shuning uchun bu dvigatel
/// oqimni HECH QACHON "huquqiy xulosa" bilan yakunlamaydi; u faqat
/// jarayonni keyingi mas'ul bo'g'inga uzatadi.
///
/// **Arxivlangan/yakunlangan ish** uchun umuman tavsiya berilmaydi --
/// bo'sh ro'yxat (`ActionPlan.empty`ga aylanadi): tugagan ishga
/// "keyingi qadam" taklif qilish foydalanuvchini chalg'itadi.
class MockRecommendationEngine implements RecommendationEngine {
  const MockRecommendationEngine();

  @override
  Future<List<Recommendation>> recommend(RecommendationContext context) async {
    if (context.status == CaseStatus.completed || context.status == CaseStatus.archived) {
      return const [];
    }

    final recommendations = <Recommendation>[];
    var order = 1;

    for (final requirement in [
      ...context.completeness.missingMandatory,
      ...context.completeness.missingOptional,
    ]) {
      recommendations.add(
        Recommendation(
          id: 'collect_${requirement.id}',
          kind: NextStepKind.collectInformation,
          message: requirement.question,
          order: order++,
          requirementId: requirement.id,
        ),
      );
    }

    if (!context.completeness.isSufficient) {
      // Majburiy bo'laklar hali to'liq emas -- ko'rib chiqish/keyingi
      // bosqich tavsiyasi ATAYLAB berilmaydi (aks holda foydalanuvchi
      // ma'lumot yetishmayotganini bilmay, oldinga o'tishga
      // urinishi mumkin).
      return List.unmodifiable(recommendations);
    }

    recommendations.add(
      Recommendation(
        id: 'review_collected_information',
        kind: NextStepKind.reviewCollectedInformation,
        message: 'To\'plangan ma\'lumotlarni ko\'rib chiqing va to\'g\'riligini tasdiqlang.',
        order: order++,
      ),
    );

    recommendations.add(
      context.category == CaseCategory.documentGeneration
          ? Recommendation(
              id: 'prepare_document_later',
              kind: NextStepKind.prepareDocumentLater,
              message:
                  'Hujjat tayyorlash bosqichiga o\'tish uchun ma\'lumot yetarli '
                  '(hujjatning o\'zi bu bosqichda tayyorlanmaydi).',
              order: order++,
            )
          : Recommendation(
              id: 'consult_human_specialist',
              kind: NextStepKind.consultHumanSpecialist,
              message: 'Keyingi qadamni malakali mutaxassis bilan birgalikda belgilang.',
              order: order++,
            ),
    );

    return List.unmodifiable(recommendations);
  }
}
