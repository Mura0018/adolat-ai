import 'ai_client_prompt_context.dart';

/// Xavfsizlik qatlamiga signal beruvchi bayroqlar -- masalan xolislik
/// talabi (`DEVELOPMENT_RULES.md`, 15-16-bandlar). Backend `SafetyContext`
/// bilan wire-shaklda mos.
class AiClientSafetyContext implements AiClientPromptContext {
  const AiClientSafetyContext({this.requiresImpartiality = false, this.maxContentLength});

  final bool requiresImpartiality;
  final int? maxContentLength;

  @override
  String get contextKey => 'safety';

  @override
  Map<String, dynamic> toPromptData() => {
    'requires_impartiality': requiresImpartiality,
    if (maxContentLength != null) 'max_content_length': maxContentLength,
  };
}
