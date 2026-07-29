import '../case/case.dart';
import '../case/case_exceptions.dart';
import '../case/case_timeline.dart';
import '../entities/ai_message.dart';
import '../repositories/case_repository.dart';
import '../repositories/conversation_repository.dart';

/// Foydalanuvchi AI'ning aniqlashtiruvchi savoliga javob berganda
/// (yoki umuman qo'shimcha ma'lumot bergan bo'lsa) ishga tushadigan
/// orkestratsiya (Module 5, Phase 5B talabi: "User Problem Intake
/// Flow" -- "Information collected").
///
/// **Nega ish holatini avtomatik O'ZGARTIRMAYDI:** "Case becomes
/// ready for next action" qachon sodir bo'lishini AVTOMATIK hal
/// qilish -- qachon "yetarli" ma'lumot to'plangani haqidagi QAROR --
/// bu ATAYLAB shu usecase'ning vazifasi EMAS (talab: "Do not
/// implement legal decisions"; `docs/adr/ADR-004`/`ADR-005`dagi bir
/// xil intizom: mahsulot/biznes qarori kod ichida taxmin
/// qilinmaydi). Holatni oldinga siljitish alohida, aniq chaqiriladigan
/// `AdvanceCaseStatusUseCase` orqali amalga oshiriladi.
class RecordCaseAnswerUseCase {
  RecordCaseAnswerUseCase({
    required CaseRepository caseRepository,
    required ConversationRepository conversationRepository,
    String Function()? messageIdGenerator,
    String Function()? timelineEventIdGenerator,
  }) : _caseRepository = caseRepository,
       _conversationRepository = conversationRepository,
       _generateMessageId = messageIdGenerator ?? _defaultMessageIdGenerator,
       _generateTimelineEventId = timelineEventIdGenerator ?? _defaultTimelineEventIdGenerator;

  final CaseRepository _caseRepository;
  final ConversationRepository _conversationRepository;
  final String Function() _generateMessageId;
  final String Function() _generateTimelineEventId;

  static int _messageCounter = 0;
  static int _eventCounter = 0;

  static String _defaultMessageIdGenerator() {
    _messageCounter += 1;
    return 'case_answer_msg_${DateTime.now().microsecondsSinceEpoch}_$_messageCounter';
  }

  static String _defaultTimelineEventIdGenerator() {
    _eventCounter += 1;
    return 'case_answer_evt_${DateTime.now().microsecondsSinceEpoch}_$_eventCounter';
  }

  /// Tashlaydi: `CaseNotFoundException` -- ish topilmasa (`../case/
  /// case_exceptions.dart`).
  Case call({required String caseId, required String answer}) {
    final existing = _caseRepository.getById(caseId);
    if (existing == null) {
      // Suhbatga yozishdan OLDIN tekshiriladi -- aks holda suhbatga
      // xabar yozilib, keyin ish topilmagani aniqlansa, ikkalasi
      // orasida nomuvofiqlik paydo bo'ladi.
      throw CaseNotFoundException(caseId);
    }

    final answeredAt = DateTime.now();
    _conversationRepository.appendMessage(
      existing.conversationId,
      AIMessage(
        id: _generateMessageId(),
        role: AIMessageRole.user,
        content: answer,
        createdAt: answeredAt,
      ),
    );

    return _caseRepository.addTimelineEvent(
      caseId,
      CaseTimelineEvent(
        id: _generateTimelineEventId(),
        type: CaseTimelineEventType.userAnswered,
        description: answer,
        occurredAt: answeredAt,
      ),
    );
  }
}
