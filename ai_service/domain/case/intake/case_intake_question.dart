/// `CaseIntakeAssistant` qaytaradigan BITTA aniqlashtiruvchi savol
/// (Module 5, Phase 5B talabi: "User Problem Intake Flow").
class CaseIntakeQuestion {
  const CaseIntakeQuestion({required this.id, required this.text});

  final String id;
  final String text;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CaseIntakeQuestion && other.id == id && other.text == text);
  }

  @override
  int get hashCode => Object.hash(id, text);

  @override
  String toString() => 'CaseIntakeQuestion(id: $id, text: $text)';
}
