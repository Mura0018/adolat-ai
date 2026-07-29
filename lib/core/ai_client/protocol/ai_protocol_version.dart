/// Klient tomonidagi (`lib/`) simli (wire) protokol versiyasi ko'rsatkichi.
///
/// **Bu `ai_service/protocol/ai_protocol_version.dart`ning AYNAN o'zi
/// EMAS -- ataylab mustaqil ko'chirma (mirror):** `lib/` `ai_service/`ni
/// hech qachon import qilmasligi shart (Module 4, Phase 1-3B --
/// `ai_service/README.md`, "Nega alohida"; `test/ai_service/
/// architecture_boundary_test.dart` shu chegarani ikkala tomondan ham
/// avtomatik tekshiradi). Ikkala tomon ham bir xil JSON SHAKLIGA rioya
/// qiladi (`{'value': int}` emas, oddiy `int`), lekin mustaqil Dart
/// klasslari sifatida -- xuddi `ai_service/domain/prompt/ai_user_role.dart`
/// loyihaning `UserRole`ni takrorlashi kabi bir xil sabab bilan.
///
/// Batafsil: `docs/AI_ARCHITECTURE.md`, "Backend Gateway (Module 4,
/// Phase 4A)" -- "Mock Integration Flow".
class AiProtocolVersion {
  const AiProtocolVersion(this.value) : assert(value >= 1, 'value kamida 1 bo\'lishi kerak');

  final int value;

  /// Klient qurilgan vaqtdagi eng yangi ma'lum protokol versiyasi --
  /// backend `AIProtocolVersion.current` bilan mos kelishi kutiladi.
  static const current = AiProtocolVersion(1);

  int toJson() => value;

  factory AiProtocolVersion.fromJson(dynamic json) => AiProtocolVersion(json as int);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AiProtocolVersion && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'v$value';
}
