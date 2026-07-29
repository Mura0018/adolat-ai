import 'case_category.dart';
import 'case_exceptions.dart';
import 'case_priority.dart';
import 'case_status.dart';
import 'case_timeline.dart';

/// Foydalanuvchining AI yordamida muammo yechish sessiyasi (Module 5,
/// Phase 5B talabi: "Case Domain Model") -- `AIConversation` (Module 4,
/// Phase 1)dan YUQORI darajadagi tushuncha: bitta `Case` ostida bitta
/// suhbat (`conversationId`) yotadi, lekin `Case` qo'shimcha ravishda
/// TOifa/muhimlik/hayot-davri holatini olib yuradi -- `AIConversation`
/// bularning HECH BIRINI bilmaydi (`domain/entities/ai_conversation.dart`,
/// "bu klass shaxsan qaysi appeal/disputega tegishli ekanligini
/// bilmaydi" bilan bir xil ajratish falsafasi, endi Case uchun ham).
///
/// **`appeals`/`disputes` (`docs/DATABASE.md`) bilan ADASHTIRILMASIN:**
/// bular RASMIY, davlat organiga yuboriladigan/ikki tomon o'rtasidagi
/// yozuvlar. `Case` esa undan OLDINGI, AI-yordamli TAYYORGARLIK
/// bosqichi -- bitta `Case` kelajakda bir nechta rasmiy `appeal`/
/// `dispute`ga olib kelishi mumkin, yoki umuman hech qanday rasmiy
/// yozuvga aylanmasligi mumkin (masalan faqat maslahat bo'lsa,
/// `CaseCategory.legalAssistance`). Ikkalasi orasidagi bog'lanish
/// (agar kerak bo'lsa) kelgusi bosqich -- `docs/AI_ARCHITECTURE.md`,
/// "AI Case and Conversation Foundation (Module 5, Phase 5B)".
///
/// **Nega Freezed emas:** `ai_message.dart`dagi izohga qarang --
/// `ai_service/` `build_runner` kodgen manbai doirasidan tashqarida.
class Case {
  const Case({
    required this.id,
    required this.userId,
    required this.category,
    required this.priority,
    required this.status,
    required this.conversationId,
    required this.problemSummary,
    required this.timeline,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  /// Ish egasi -- xavfsizlik qoidasi ("User can only access own
  /// cases")ning YAGONA haqiqat manbai. Bu tekshiruvni `Case`ning
  /// o'zi EMAS, uni CHAQIRUVCHI (`domain/usecases/get_case_usecase.dart`)
  /// amalga oshiradi -- `AIRequestDispatcher`ning `request.userId !=
  /// auth.userId` tekshiruvi (Module 4, Phase 3B) bilan bir xil
  /// qatlamlash falsafasi: repository/entity "aqlsiz", ruxsat mantig'i
  /// yuqori qatlamda.
  final String userId;

  final CaseCategory category;
  final CasePriority priority;
  final CaseStatus status;

  /// `AIConversation.id` (Module 4) ga ishora -- Module 5, Phase 5B
  /// talabi: "Case keeps conversation reference". Suhbatning O'ZI
  /// (xabarlar tarixi) bu yerda QAYTARILMAYDI -- "Conversation history
  /// remains independent": uni olish uchun `ConversationRepository.
  /// getById(conversationId)` alohida chaqiriladi.
  final String conversationId;

  /// Foydalanuvchi muammosining qisqa, boshlang'ich tavsifi --
  /// **SEZGIR bo'lishi mumkin** (talab: "No sensitive information in
  /// domain logs"). `toString()` buni hech qachon to'liq chiqarmaydi
  /// (pastga qarang).
  final String problemSummary;

  final CaseTimeline timeline;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTerminal => status.isTerminal;

  /// Yangi holatga **yangi** nusxa bilan o'tadi -- `AIConversation.close()`
  /// (Module 4, Phase 2A) bilan bir xil o'zgarmaslik (immutability)
  /// naqshi. O'tish invarianti ([isValidCaseStatusTransition]) shu
  /// yerda, ENTITY darajasida majburlangan -- repository
  /// implementatsiyasidan mustaqil (`InMemoryConversationRepository`
  /// emas, `AIConversation`ning o'zi `ConversationClosedException`
  /// tashlashi bilan bir xil sabab).
  ///
  /// **Timeline yozuvi bu yerda QO'SHILMAYDI** -- `AIConversation.
  /// appendMessage(AIMessage message)` (Module 4) bilan bir xil sabab:
  /// hodisa ID'sini generatsiya qilish chaqiruvchining (repository/
  /// usecase, o'zining hisoblagichi bilan) ishi, entity o'zi ID
  /// "o'ylab topmaydi". Chaqiruvchi (`domain/repositories/
  /// case_repository.dart`ning implementatsiyasi) `withStatus()` bilan
  /// [appendTimelineEvent]ni birgalikda chaqiradi.
  ///
  /// Tashlaydi: `InvalidCaseStatusTransitionException` -- o'tish
  /// mantiqan noto'g'ri bo'lsa.
  Case withStatus(CaseStatus newStatus, {required DateTime at}) {
    if (!isValidCaseStatusTransition(from: status, to: newStatus)) {
      throw InvalidCaseStatusTransitionException(from: status, to: newStatus);
    }
    return _copyWith(status: newStatus, updatedAt: at);
  }

  /// Timeline'ga tayyor hodisa qo'shadi -- `AIConversation.appendMessage()`
  /// bilan bir xil, chaqiruvchi allaqachon shakllangan [event]ni beradi.
  Case appendTimelineEvent(CaseTimelineEvent event) {
    return _copyWith(timeline: timeline.appendEvent(event), updatedAt: event.occurredAt);
  }

  Case _copyWith({CaseStatus? status, CaseTimeline? timeline, required DateTime updatedAt}) {
    return Case(
      id: id,
      userId: userId,
      category: category,
      priority: priority,
      status: status ?? this.status,
      conversationId: conversationId,
      problemSummary: problemSummary,
      timeline: timeline ?? this.timeline,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Case &&
            other.id == id &&
            other.userId == userId &&
            other.category == category &&
            other.priority == priority &&
            other.status == status &&
            other.conversationId == conversationId &&
            other.problemSummary == problemSummary &&
            other.timeline == timeline &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt);
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    category,
    priority,
    status,
    conversationId,
    problemSummary,
    timeline,
    createdAt,
    updatedAt,
  );

  /// **Xavfsizlik:** `problemSummary` (sezgir bo'lishi mumkin bo'lgan
  /// foydalanuvchi matni) ATAYLAB chiqarilmagan -- talab: "No sensitive
  /// information in domain logs". `AIBackendCredential.toString()`
  /// (Module 4, Phase 4B) tokenni maskalagani bilan bir xil ehtiyotkorlik.
  @override
  String toString() =>
      'Case(id: $id, category: $category, status: $status, priority: $priority)';
}
