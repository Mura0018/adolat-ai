import 'prompt_context.dart';

/// Kelgusi suhbat xotirasi/tarixi integratsiyasi uchun tuzilma
/// (`docs/AI_ARCHITECTURE.md`, "Future Memory Integration Point").
///
/// **Foundation bosqichida placeholder:** `summarizedHistory` hozircha
/// har doim bo'sh ro'yxat sifatida uzatiladi — haqiqiy suhbat
/// xotirasini yig'ish/qisqartirish (summarization) mexanizmi Module 4,
/// Phase 1 doirasidan tashqarida. Klass shakli allaqachon shu
/// integratsiyani hisobga olib loyihalangan, shunda kelajakda
/// `PromptPipeline`ning boshqa qismlariga tegilmasdan to'ldiriladi.
class MemoryContext implements PromptContext {
  const MemoryContext({this.summarizedHistory = const []});

  final List<String> summarizedHistory;

  @override
  String get contextKey => 'memory';

  @override
  Map<String, dynamic> toPromptData() {
    return {'summarized_history': summarizedHistory};
  }
}
