import 'prompt_context.dart';

/// Xavfsizlik qatlamiga (`ai_service/safety/ai_safety_service.dart`)
/// signal beruvchi bayroqlar — masalan xolislik talabi.
///
/// `requiresImpartiality`: `DEVELOPMENT_RULES.md`, 15–16-bandlar ("AI
/// faqat qonun va faktlarga asoslanadi", "AI hech qachon bir tomon
/// foydasiga qaror chiqarmaydi") — nizo (dispute) tahlili uchun har
/// doim `true` bo'lishi kutiladi.
class SafetyContext implements PromptContext {
  const SafetyContext({
    this.requiresImpartiality = false,
    this.maxContentLength,
  });

  final bool requiresImpartiality;
  final int? maxContentLength;

  @override
  String get contextKey => 'safety';

  @override
  Map<String, dynamic> toPromptData() {
    return {
      'requires_impartiality': requiresImpartiality,
      if (maxContentLength != null) 'max_content_length': maxContentLength,
    };
  }
}
