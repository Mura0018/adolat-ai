import 'prompt_context.dart';

/// Tizim darajasidagi sozlamalar (masalan til, model rejimi) —
/// **prompt matni emas**, faqat konfiguratsiya ma'lumoti. Haqiqiy
/// tizim ko'rsatmasi (system prompt) matni Module 4, Phase 1 doirasidan
/// tashqarida.
class SystemContext implements PromptContext {
  const SystemContext({required this.locale, this.responseMode = 'default'});

  final String locale;
  final String responseMode;

  @override
  String get contextKey => 'system';

  @override
  Map<String, dynamic> toPromptData() {
    return {'locale': locale, 'response_mode': responseMode};
  }
}
