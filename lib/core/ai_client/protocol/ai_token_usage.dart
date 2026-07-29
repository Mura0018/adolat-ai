/// Token sarfi haqidagi ma'lumot -- joy ajratilgan (placeholder).
/// `ai_service/protocol/ai_token_usage.dart`ning klient tomonidagi
/// mustaqil ko'chirmasi.
///
/// Barcha maydonlar ixtiyoriy va hozircha har doim `null` bo'ladi --
/// haqiqiy provayder javobidan token sonini o'qish backend tomonida
/// amalga oshiriladi (`docs/adr/ADR-004-ai-cost-governance.md`).
class AiTokenUsage {
  const AiTokenUsage({this.promptTokens, this.completionTokens, this.totalTokens});

  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;

  static const unknown = AiTokenUsage();

  Map<String, dynamic> toJson() => {
    if (promptTokens != null) 'promptTokens': promptTokens,
    if (completionTokens != null) 'completionTokens': completionTokens,
    if (totalTokens != null) 'totalTokens': totalTokens,
  };

  factory AiTokenUsage.fromJson(Map<String, dynamic> json) {
    return AiTokenUsage(
      promptTokens: json['promptTokens'] as int?,
      completionTokens: json['completionTokens'] as int?,
      totalTokens: json['totalTokens'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AiTokenUsage &&
            other.promptTokens == promptTokens &&
            other.completionTokens == completionTokens &&
            other.totalTokens == totalTokens);
  }

  @override
  int get hashCode => Object.hash(promptTokens, completionTokens, totalTokens);

  @override
  String toString() =>
      'AiTokenUsage(prompt: $promptTokens, completion: $completionTokens, total: $totalTokens)';
}
