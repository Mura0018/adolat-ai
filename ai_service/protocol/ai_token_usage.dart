/// Token sarfi haqidagi ma'lumot -- joy ajratilgan (placeholder)
/// (Module 4, Phase 3A talabi: "token usage placeholder").
///
/// Barcha maydonlar ixtiyoriy va hozircha har doim `null` bo'ladi --
/// haqiqiy provayder javobidan token sonini o'qish/hisoblash
/// implementatsiyasi bu bosqich doirasidan tashqarida (`docs/
/// adr/ADR-004-ai-cost-governance.md`, xarajat nazorati -- kelgusi
/// bosqichda shu maydonlarga bog'lanadi).
class AITokenUsage {
  const AITokenUsage({this.promptTokens, this.completionTokens, this.totalTokens});

  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;

  /// Hali o'lchanmagan/ma'lum bo'lmagan holat uchun qulaylik konstantasi.
  static const unknown = AITokenUsage();

  Map<String, dynamic> toJson() => {
    if (promptTokens != null) 'promptTokens': promptTokens,
    if (completionTokens != null) 'completionTokens': completionTokens,
    if (totalTokens != null) 'totalTokens': totalTokens,
  };

  factory AITokenUsage.fromJson(Map<String, dynamic> json) {
    return AITokenUsage(
      promptTokens: json['promptTokens'] as int?,
      completionTokens: json['completionTokens'] as int?,
      totalTokens: json['totalTokens'] as int?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AITokenUsage &&
            other.promptTokens == promptTokens &&
            other.completionTokens == completionTokens &&
            other.totalTokens == totalTokens);
  }

  @override
  int get hashCode => Object.hash(promptTokens, completionTokens, totalTokens);

  @override
  String toString() =>
      'AITokenUsage(prompt: $promptTokens, completion: $completionTokens, total: $totalTokens)';
}
