import 'ai_client_prompt_context.dart';

/// Tizim darajasidagi sozlamalar (til, javob rejimi) -- **prompt matni
/// emas**, faqat konfiguratsiya ma'lumoti. Backend `SystemContext`ning
/// wire-shakl hamkasbi (`ai_client_prompt_context.dart`ga qarang).
class AiClientSystemContext implements AiClientPromptContext {
  const AiClientSystemContext({required this.locale, this.responseMode = 'default'});

  final String locale;
  final String responseMode;

  @override
  String get contextKey => 'system';

  @override
  Map<String, dynamic> toPromptData() => {'locale': locale, 'response_mode': responseMode};
}
