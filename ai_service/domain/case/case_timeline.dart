/// `CaseTimelineEvent`ning turi -- `docs/DATABASE.md`, 7-jadval
/// (`case_status_history` -- "Murojaat/nizo holati o'zgarishlarining
/// audit izi")ning `ai_service/` domenidagi KONSEPTUAL hamkasbi (hali
/// shu jadvalning o'ziga yozilmaydi -- talab: "No real database
/// implementation yet").
enum CaseTimelineEventType {
  /// Ish yaratildi -- har doim timeline'dagi BIRINCHI hodisa.
  caseCreated,

  /// `Case.status` o'zgardi.
  statusChanged,

  /// AI (yoki mock yordamchi) aniqlashtiruvchi savol berdi.
  clarificationQuestionAsked,

  /// Foydalanuvchi savolga javob berdi/qo'shimcha ma'lumot taqdim etdi.
  userAnswered,

  /// Erkin shakldagi eslatma (masalan kelgusi admin/tizim yozuvi uchun
  /// joy ajratilgan).
  note,
}

/// Bitta timeline yozuvi -- o'zgarmas (immutable).
class CaseTimelineEvent {
  const CaseTimelineEvent({
    required this.id,
    required this.type,
    required this.description,
    required this.occurredAt,
  });

  final String id;
  final CaseTimelineEventType type;

  /// Inson o'qiy oladigan qisqa tavsif -- **sezgir ma'lumotni xavfsiz
  /// tarzda saqlash chaqiruvchining mas'uliyati** (masalan foydalanuvchi
  /// muammosining to'liq matni bu yerga yozilishi mumkin -- `Case`
  /// darajasidagi log/monitoring xavfsizligi uchun `Case.toString()`
  /// buni hech qachon to'liq chiqarmaydi, quyidagi `case.dart`ga
  /// qarang).
  final String description;

  final DateTime occurredAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CaseTimelineEvent &&
            other.id == id &&
            other.type == type &&
            other.description == description &&
            other.occurredAt == occurredAt);
  }

  @override
  int get hashCode => Object.hash(id, type, description, occurredAt);

  @override
  String toString() => 'CaseTimelineEvent(id: $id, type: $type, occurredAt: $occurredAt)';
}

/// `Case`ning voqealar tarixi -- o'zgarmas (immutable) ro'yxat
/// o'ramchi (wrapper), `AIConversation.messages` (Module 4, Phase 1)
/// bilan bir xil ruhda, lekin alohida TUR sifatida (Module 5, Phase
/// 5B talabi: "Case Domain Model" ro'yxatida `CaseTimeline` aniq
/// nomlab ko'rsatilgan).
class CaseTimeline {
  const CaseTimeline({this.events = const []});

  final List<CaseTimelineEvent> events;

  /// Eng so'nggi hodisa, hali hech narsa bo'lmasa `null`.
  CaseTimelineEvent? get latest => events.isEmpty ? null : events.last;

  /// Yangi hodisa bilan **yangi** nusxa qaytaradi -- `Case`ning o'zi
  /// kabi o'zgarmas.
  CaseTimeline appendEvent(CaseTimelineEvent event) {
    return CaseTimeline(events: [...events, event]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CaseTimeline) return false;
    if (other.events.length != events.length) return false;
    for (var i = 0; i < events.length; i++) {
      if (other.events[i] != events[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(events);

  @override
  String toString() => 'CaseTimeline(${events.length} events)';
}
