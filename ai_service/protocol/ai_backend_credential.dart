/// Klient AI Gateway'ga yuboradigan autentifikatsiya hisob
/// ma'lumotining SIMLI (wire) shakli (Module 4, Phase 4B talabi:
/// "Authentication contract").
///
/// **`AIAuthenticator.authenticate(Object? credential)` (`gateway/
/// auth/`, Phase 3B) bilan munosabati:** o'sha interfeys [credential]ni
/// ATAYLAB `Object?` deb qoldirgan edi -- "transport-ga xos xom
/// ma'lumot (masalan HTTP `Authorization` sarlavhasi qiymati)"
/// shaklidan mustaqin bo'lish uchun. `AIBackendCredential` bu
/// mustaqillikni BUZMAYDI -- u transport HALI ANIQLANMAGAN bo'lsa ham,
/// klient qaysi MA'LUMOT turini yuborishi kerakligini (Supabase Auth
/// JWT access token, `docs/SECURITY.md`: "JWT/token faqat Flutter
/// Secure Storage'da saqlanadi va HTTPS ustidan uzatiladi") aniq
/// belgilaydi. Transportga xos joylashtirish (masalan `Authorization:
/// Bearer <token>` sarlavhasi yoki WebSocket handshake payload'i) --
/// bu klassning [token]ini transport ustiga qanday "joylashtirish"
/// masalasi, hali qurilmagan haqiqiy transport implementatsiyasining
/// ishi.
///
/// **Nega xavfsiz `toString()`:** `docs/SECURITY.md`, "Monitoring" --
/// "monitoring/log tizimiga hech qachon parol, token... yuborilmaydi".
/// [token] hech qachon `toString()`da to'liq chiqarilmaydi.
enum AIBackendCredentialType {
  /// Supabase Auth tomonidan berilgan JWT access token -- loyihaning
  /// yagona autentifikatsiya provayderi (`docs/ARCHITECTURE.md`).
  supabaseAccessToken,
}

class AIBackendCredential {
  const AIBackendCredential({required this.type, required this.token, this.expiresAt});

  final AIBackendCredentialType type;

  /// Xom token qiymati -- hech qachon logga yozilmasligi/`toString()`da
  /// to'liq chiqarilmasligi shart.
  final String token;

  /// Ma'lum bo'lsa, tokenning amal qilish muddati -- klient tomonida
  /// muddati tugagan tokenni yuborishdan oldin yangilash (refresh)
  /// qarorini qabul qilish uchun. `null` bo'lishi mumkin (masalan
  /// token turi buni oshkor qilmasa).
  final DateTime? expiresAt;

  /// [now]ga nisbatan token muddati tugaganmi. Xolis (pure) funksiya --
  /// `DateTime.now()`ni o'zi chaqirmaydi (loyihadagi boshqa `protocol/`
  /// klasslari kabi, sinov (test) qilinishi uchun vaqt tashqaridan
  /// beriladi). [expiresAt] `null` bo'lsa, hali ma'lum emas deb hisoblanadi
  /// -- muddati tugagan deb FARAZ QILINMAYDI.
  bool isExpiredAt(DateTime now) => expiresAt != null && !now.isBefore(expiresAt!);

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'token': token,
    if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
  };

  factory AIBackendCredential.fromJson(Map<String, dynamic> json) {
    return AIBackendCredential(
      type: AIBackendCredentialType.values.byName(json['type'] as String),
      token: json['token'] as String,
      expiresAt: json['expiresAt'] == null ? null : DateTime.parse(json['expiresAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIBackendCredential &&
            other.type == type &&
            other.token == token &&
            other.expiresAt == expiresAt);
  }

  @override
  int get hashCode => Object.hash(type, token, expiresAt);

  @override
  String toString() => 'AIBackendCredential(type: $type, token: ***, expiresAt: $expiresAt)';
}
