import '../case/case.dart';
import '../case/case_category.dart';
import '../case/case_priority.dart';
import '../case/case_status.dart';
import '../case/case_timeline.dart';
import '../case/intake/case_intake_assistant.dart';
import '../entities/ai_message.dart';
import '../repositories/case_repository.dart';
import '../repositories/conversation_repository.dart';

/// Foydalanuvchi muammosini birinchi marta tushuntirganda ishga
/// tushadigan orkestratsiya (Module 5, Phase 5B talabi: "User Problem
/// Intake Flow" -- "User explains problem → AI asks clarification
/// questions").
///
/// **Module 4 (suhbat) va Module 5 (ish)ni BOG'LAYDIGAN yagona
/// nuqta:** yangi `AIConversation` (`ConversationRepository.create()`,
/// Module 4, Phase 2A) va yangi `Case` (`CaseRepository.create()`)
/// BIR VAQTDA yaratiladi, `Case.conversationId` ikkalasini bog'laydi
/// (talab: "Every conversation belongs to a case. Case keeps
/// conversation reference."). Foydalanuvchining muammo tavsifi
/// suhbatga `role: user` sifatida yoziladi -- xuddi
/// `SendConversationMessageUseCase` (Module 4, Phase 2C) qilgani kabi,
/// shu bilan "Conversation history remains independent" talabi
/// ta'minlanadi: suhbat tarixi kelgusida `AIRepository`/haqiqiy
/// provayder orqali o'qilganda, u yerda `Case`ning O'ZI haqida hech
/// narsa bo'lmaydi, faqat oddiy xabarlar ketma-ketligi.
class StartCaseIntakeUseCase {
  StartCaseIntakeUseCase({
    required CaseRepository caseRepository,
    required ConversationRepository conversationRepository,
    required CaseIntakeAssistant intakeAssistant,
    String Function()? messageIdGenerator,
    String Function()? timelineEventIdGenerator,
  }) : _caseRepository = caseRepository,
       _conversationRepository = conversationRepository,
       _intakeAssistant = intakeAssistant,
       _generateMessageId = messageIdGenerator ?? _defaultMessageIdGenerator,
       _generateTimelineEventId = timelineEventIdGenerator ?? _defaultTimelineEventIdGenerator;

  final CaseRepository _caseRepository;
  final ConversationRepository _conversationRepository;
  final CaseIntakeAssistant _intakeAssistant;
  final String Function() _generateMessageId;
  final String Function() _generateTimelineEventId;

  static int _messageCounter = 0;
  static int _eventCounter = 0;

  static String _defaultMessageIdGenerator() {
    _messageCounter += 1;
    return 'case_intake_msg_${DateTime.now().microsecondsSinceEpoch}_$_messageCounter';
  }

  static String _defaultTimelineEventIdGenerator() {
    _eventCounter += 1;
    return 'case_intake_evt_${DateTime.now().microsecondsSinceEpoch}_$_eventCounter';
  }

  /// 1. Yangi suhbat + yangi ish yaratadi (`CaseStatus.created`).
  /// 2. Foydalanuvchi tavsifini suhbatga `role: user` sifatida yozadi.
  /// 3. `CaseIntakeAssistant`dan (hozircha faqat `MockCaseIntakeAssistant`,
  ///    talab: "Use mock AI responses only") aniqlashtiruvchi savollar
  ///    oladi, ularning har birini `role: assistant` sifatida suhbatga
  ///    VA timeline'ga (`CaseTimelineEventType.clarificationQuestionAsked`)
  ///    yozadi.
  /// 4. Ishni `CaseStatus.understanding`ga o'tkazadi.
  Future<Case> call({
    required String userId,
    required CaseCategory category,
    required String problemDescription,
    CasePriority priority = CasePriority.normal,
  }) async {
    final conversation = _conversationRepository.create();

    var case_ = _caseRepository.create(
      userId: userId,
      category: category,
      problemSummary: problemDescription,
      conversationId: conversation.id,
      priority: priority,
    );

    _conversationRepository.appendMessage(
      conversation.id,
      AIMessage(
        id: _generateMessageId(),
        role: AIMessageRole.user,
        content: problemDescription,
        createdAt: DateTime.now(),
      ),
    );

    final questions = await _intakeAssistant.generateClarificationQuestions(
      problemDescription: problemDescription,
      category: category,
    );

    for (final question in questions) {
      final askedAt = DateTime.now();
      _conversationRepository.appendMessage(
        conversation.id,
        AIMessage(
          id: _generateMessageId(),
          role: AIMessageRole.assistant,
          content: question.text,
          createdAt: askedAt,
        ),
      );
      case_ = _caseRepository.addTimelineEvent(
        case_.id,
        CaseTimelineEvent(
          id: _generateTimelineEventId(),
          type: CaseTimelineEventType.clarificationQuestionAsked,
          description: question.text,
          occurredAt: askedAt,
        ),
      );
    }

    return _caseRepository.updateStatus(case_.id, CaseStatus.understanding);
  }
}
