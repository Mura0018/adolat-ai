/// `PromptPipeline.compose()` natijasi — bir nechta mustaqil
/// `PromptContext`larning (`domain/prompt/`) tuzilgan ma'lumoti, kalit
/// (masalan `'system'`, `'case'`) bo'yicha birlashtirilgan.
///
/// **Muhim:** bu klass hech qanday tayyor prompt matnini o'zida
/// saqlamaydi — faqat strukturaviy ma'lumot (`Map<String, dynamic>`).
/// Haqiqiy matn shakllantirish (templating) Module 4, Phase 1 doirasidan
/// tashqarida (kelgusi bosqich).
///
/// Freezed ishlatilmagan sababi: `ai_message.dart`dagi izohga qarang.
class AIContext {
  const AIContext({required this.sections});

  final Map<String, Map<String, dynamic>> sections;

  Map<String, dynamic>? sectionFor(String contextKey) => sections[contextKey];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AIContext) return false;
    if (other.sections.length != sections.length) return false;
    for (final key in sections.keys) {
      if (!other.sections.containsKey(key)) return false;
      if (other.sections[key].toString() != sections[key].toString()) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    sections.entries.map((e) => Object.hash(e.key, e.value.toString())),
  );

  @override
  String toString() => 'AIContext(sections: ${sections.keys})';
}
