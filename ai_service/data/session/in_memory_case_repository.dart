import '../../domain/case/case.dart';
import '../../domain/case/case_category.dart';
import '../../domain/case/case_exceptions.dart';
import '../../domain/case/case_priority.dart';
import '../../domain/case/case_status.dart';
import '../../domain/case/case_timeline.dart';
import '../../domain/repositories/case_repository.dart';

/// `CaseRepository`ning xotiradagi (in-memory) implementatsiyasi --
/// `InMemoryConversationRepository` (Module 4, Phase 2A) bilan bir xil
/// naqsh va bir xil cheklov (bitta process instance doirasida).
class InMemoryCaseRepository implements CaseRepository {
  InMemoryCaseRepository({String Function()? idGenerator})
    : _generateId = idGenerator ?? _defaultIdGenerator;

  final String Function() _generateId;
  final Map<String, Case> _cases = {};

  static int _counter = 0;

  static String _defaultIdGenerator() {
    _counter += 1;
    return 'case_${DateTime.now().microsecondsSinceEpoch}_$_counter';
  }

  @override
  Case create({
    required String userId,
    required CaseCategory category,
    required String problemSummary,
    required String conversationId,
    CasePriority priority = CasePriority.normal,
  }) {
    final id = _generateId();
    final createdAt = DateTime.now();
    final createdEvent = CaseTimelineEvent(
      id: _generateId(),
      type: CaseTimelineEventType.caseCreated,
      description: 'Ish yaratildi',
      occurredAt: createdAt,
    );
    final case_ = Case(
      id: id,
      userId: userId,
      category: category,
      priority: priority,
      status: CaseStatus.created,
      conversationId: conversationId,
      problemSummary: problemSummary,
      timeline: CaseTimeline(events: [createdEvent]),
      createdAt: createdAt,
      updatedAt: createdAt,
    );
    _cases[id] = case_;
    return case_;
  }

  @override
  Case? getById(String caseId) => _cases[caseId];

  @override
  List<Case> listForUser(String userId) {
    return _cases.values.where((c) => c.userId == userId).toList();
  }

  @override
  Case updateStatus(String caseId, CaseStatus newStatus) {
    final existing = _cases[caseId];
    if (existing == null) {
      throw CaseNotFoundException(caseId);
    }
    final at = DateTime.now();
    // `Case.withStatus()`ning o'zi `InvalidCaseStatusTransitionException`
    // tashlashi mumkin -- bu yerda ushlanmaydi, chaqiruvchiga tarqaladi
    // (entity darajasidagi invariant, repository buni takrorlamaydi).
    final transitioned = existing.withStatus(newStatus, at: at);
    final withEvent = transitioned.appendTimelineEvent(
      CaseTimelineEvent(
        id: _generateId(),
        type: CaseTimelineEventType.statusChanged,
        description: '${existing.status.name} -> ${newStatus.name}',
        occurredAt: at,
      ),
    );
    _cases[caseId] = withEvent;
    return withEvent;
  }

  @override
  Case addTimelineEvent(String caseId, CaseTimelineEvent event) {
    final existing = _cases[caseId];
    if (existing == null) {
      throw CaseNotFoundException(caseId);
    }
    final updated = existing.appendTimelineEvent(event);
    _cases[caseId] = updated;
    return updated;
  }

  @override
  Case recordInformation(String caseId, String requirementId, String value) {
    final existing = _cases[caseId];
    if (existing == null) {
      throw CaseNotFoundException(caseId);
    }
    final updated = existing.withInformation(requirementId, value, at: DateTime.now());
    _cases[caseId] = updated;
    return updated;
  }
}
