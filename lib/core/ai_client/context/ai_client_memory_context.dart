import 'ai_client_prompt_context.dart';

/// Kelgusi suhbat xotirasi/tarixi integratsiyasi uchun tuzilma --
/// backend `MemoryContext` bilan wire-shaklda mos.
///
/// **Foundation bosqichida placeholder:** `summarizedHistory` hozircha
/// har doim bo'sh ro'yxat sifatida uzatiladi.
class AiClientMemoryContext implements AiClientPromptContext {
  const AiClientMemoryContext({this.summarizedHistory = const []});

  final List<String> summarizedHistory;

  @override
  String get contextKey => 'memory';

  @override
  Map<String, dynamic> toPromptData() => {'summarized_history': summarizedHistory};
}
