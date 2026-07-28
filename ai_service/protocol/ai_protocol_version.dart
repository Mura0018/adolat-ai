/// Klient ↔ backend simli (wire) protokolining versiyasi (Module 4,
/// Phase 3A talabi: "Protocol Versioning").
///
/// **Butun konvert (envelope) sxemasi bitta birlik sifatida
/// versiyalanadi** — `AIRequestEnvelope`/`AIResponseEnvelope`/
/// `AIProtocolStreamEvent`ning istalgan maydoni mos kelmaydigan
/// (breaking) tarzda o'zgarsa, `current` qiymati oshiriladi. Backend
/// bir vaqtning o'zida bir nechta versiyani qo'llab-quvvatlashi mumkin
/// (masalan migratsiya davrida) — bu klass shuning uchun oddiy butun
/// son (int), semver emas: wire xabar versiyasi paket versiyasi emas,
/// "qaysi sxema" degan savolga javob beradi, xolos.
class AIProtocolVersion {
  const AIProtocolVersion(this.value) : assert(value >= 1, 'value kamida 1 bo\'lishi kerak');

  final int value;

  /// Ushbu kodning yozilgan vaqtidagi eng yangi protokol versiyasi.
  /// Yangi konvertlar standart holatda shu versiyani ishlatadi.
  static const current = AIProtocolVersion(1);

  int toJson() => value;

  factory AIProtocolVersion.fromJson(dynamic json) => AIProtocolVersion(json as int);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AIProtocolVersion && other.value == value);

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'v$value';
}
