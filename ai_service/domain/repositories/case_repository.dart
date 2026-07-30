import '../case/case.dart';
import '../case/case_category.dart';
import '../case/case_priority.dart';
import '../case/case_status.dart';
import '../case/case_timeline.dart';

/// `Case` hayot davri ustidagi abstrakt shartnoma (Module 5, Phase 5B
/// talabi: "Case Repository Contract") -- `ConversationRepository`
/// (`conversation_repository.dart`, Module 4, Phase 2A) bilan bir xil
/// konventsiya va sabab: saqlash usulini (xotira → Postgres) Case
/// domenidan/usecase'laridan mustaqil qilish.
///
/// **"No real database implementation yet":** bu -- FAQAT shartnoma.
/// Foundation implementatsiyasi -- `InMemoryCaseRepository` (`data/
/// session/in_memory_case_repository.dart`), `InMemoryConversationRepository`
/// bilan bir xil cheklov (bitta process instance, ko'p-nusxali
/// joylashtirishda umumiy saqlash kerak bo'ladi).
abstract interface class CaseRepository {
  /// Yangi ish yaratadi, boshlang'ich holati doim `CaseStatus.created`.
  Case create({
    required String userId,
    required CaseCategory category,
    required String problemSummary,
    required String conversationId,
    CasePriority priority = CasePriority.normal,
  });

  /// Ishni identifikatori bo'yicha qaytaradi, topilmasa `null`.
  ///
  /// **Xavfsizlik eslatmasi:** bu metod `userId`ni TEKSHIRMAYDI --
  /// egalik tekshiruvi ATAYLAB yuqori qatlamda (`domain/usecases/
  /// get_case_usecase.dart`), `AIRequestDispatcher`ning `auth.userId`
  /// tekshiruvi (Module 4, Phase 3B) bilan bir xil qatlamlash.
  Case? getById(String caseId);

  /// Berilgan foydalanuvchiga tegishli BARCHA ishlarni qaytaradi --
  /// natija ALLAQACHON shu foydalanuvchi bilan chegaralangan (Module
  /// 5, Phase 5B talabi: "Security Rules -- User can only access own
  /// cases" shu metodning o'zida tabiiy ravishda ta'minlanadi).
  List<Case> listForUser(String userId);

  /// Ish holatini yangilaydi va yangilangan nusxani qaytaradi --
  /// ICHKI ravishda `Case.withStatus()` (o'tish invariantini
  /// tekshiradi) VA mos `CaseTimelineEvent` qo'shilishini
  /// birlashtiradi. Vaqt tamg'asi (`updatedAt`/hodisa vaqti) implementatsiya
  /// tomonidan ICHKI belgilanadi -- `ConversationRepository.close()`
  /// (Module 4, Phase 2A) bilan bir xil konventsiya (chaqiruvchi vaqtni
  /// bermaydi).
  ///
  /// Tashlaydi:
  /// - `CaseNotFoundException` -- ish topilmasa.
  /// - `InvalidCaseStatusTransitionException` -- o'tish noto'g'ri
  ///   bo'lsa (`case_status.dart`, [isValidCaseStatusTransition]).
  Case updateStatus(String caseId, CaseStatus newStatus);

  /// Timeline'ga xom hodisa qo'shadi (holatni o'zgartirmaydi).
  ///
  /// Tashlaydi: `CaseNotFoundException` -- ish topilmasa.
  Case addTimelineEvent(String caseId, CaseTimelineEvent event);

  /// Bitta TUZILMALI ma'lumot bo'lagini yozadi/ustiga yozadi
  /// (`Case.collectedInformation`) -- Module 5, Phase 5C qo'shimchasi
  /// (talab: "Progress tracking").
  ///
  /// [requirementId]ning shu ish TOIFASI uchun haqiqiy ekanligi bu
  /// yerda TEKSHIRILMAYDI -- katalog tekshiruvi usecase qatlamida
  /// (`domain/usecases/record_case_information_usecase.dart`), xuddi
  /// egalik tekshiruvi `getById()`da emas, `GetCaseUseCase`da
  /// bo'lgani kabi: repository "aqlsiz" qoladi.
  ///
  /// Timeline yozuvi bu metodda QO'SHILMAYDI (`updateStatus()`dan
  /// farqli) -- javobni suhbatga va timeline'ga yozish usecase
  /// darajasidagi orkestratsiya (`RecordCaseAnswerUseCase`, Phase 5B),
  /// bu metod esa faqat joriy holatni saqlaydi.
  ///
  /// Tashlaydi: `CaseNotFoundException` -- ish topilmasa.
  Case recordInformation(String caseId, String requirementId, String value);
}
