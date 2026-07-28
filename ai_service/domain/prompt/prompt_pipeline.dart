import '../entities/ai_context.dart';
import 'prompt_context.dart';

/// Bir nechta mustaqil `PromptContext`larni bitta `AIContext`ga
/// birlashtiradi (Module 4 talabi: "Only build prompt pipeline").
///
/// O'zgarmas (immutable), qurilmoqchi (builder) naqshi: `withContext()`
/// har safar YANGI nusxa qaytaradi. Kontekstlar qo'shilish tartibida
/// saqlanadi, lekin `compose()` ularni faqat kalit bo'yicha
/// (`contextKey`) birlashtiradi — tartibning o'zi hozircha (real
/// prompt-matn shakllantirish yo'q) faqat ma'lumot uchun.
class PromptPipeline {
  const PromptPipeline([this.contexts = const []]);

  final List<PromptContext> contexts;

  PromptPipeline withContext(PromptContext context) {
    return PromptPipeline([...contexts, context]);
  }

  /// Bir xil `contextKey`ga ega ikkita context qo'shilsa, oxirgisi
  /// g'olib chiqadi (`Map` semantikasi) — bu ataylab, chaqiruvchiga
  /// bosqichma-bosqich context'ni almashtirish/yangilash imkonini
  /// beradi.
  AIContext compose() {
    final sections = <String, Map<String, dynamic>>{};
    for (final context in contexts) {
      sections[context.contextKey] = context.toPromptData();
    }
    return AIContext(sections: sections);
  }
}
