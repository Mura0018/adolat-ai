/// Klient tomonidagi context pipeline'ning bitta mustaqil bo'lagi --
/// backend `PromptContext` (`ai_service/domain/prompt/prompt_context.dart`)
/// bilan bir xil shartnoma shakli.
///
/// **Muhim:** `toPromptData()` tayyor prompt MATNI qaytarmaydi -- faqat
/// xom, strukturaviy ma'lumot. Bu ma'lumot `AiRequestEnvelope.context`ga
/// joylanadi va backend tomonida (`AIRequestDispatcher`) `AIContext.
/// sections`ga to'g'ridan-to'g'ri aylantiriladi -- shuning uchun har bir
/// [contextKey] backend tomonidagi mos context'ning kaliti bilan AYNAN
/// bir xil bo'lishi shart ('system'/'user'/'safety'/'case'/'memory').
abstract interface class AiClientPromptContext {
  String get contextKey;

  Map<String, dynamic> toPromptData();
}
