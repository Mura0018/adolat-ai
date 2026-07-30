/// Ziddiyat qanday hal qilinishi haqidagi QAROR
/// (`docs/ARCHITECTURE.md`, "Conflict Resolution").
///
/// `sealed` — shuning uchun `switch` to'liqligi KOMPILYATSIYA vaqtida
/// tekshiriladi: kelgusida yangi variant qo'shilsa, uni qayta ishlashni
/// unutgan har bir joy darhol xatolik beradi. Bu ataylab: ziddiyatni
/// "e'tibordan chetda qoldirish" ma'lumot yo'qolishiga olib keladi.
///
/// Uchta variantdan boshqasi YO'Q — ayniqsa "mahalliy nusxani jimgina
/// tashlab yuborish" varianti ataylab mavjud emas.
sealed class ConflictResolution {
  const ConflictResolution();

  /// Foydalanuvchi aralashuvi kerakmi.
  bool get requiresUserDecision => this is EscalateToUser;
}

/// Mahalliy o'zgarish serverga yuboriladi.
class ApplyLocalChange extends ConflictResolution {
  const ApplyLocalChange({required this.reason});

  /// Nega shu qaror qabul qilingani — audit izi uchun
  /// (`docs/ARCHITECTURE.md`, "Conflict Resolution" → *"Audit iz"*).
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is ApplyLocalChange && other.reason == reason);

  @override
  int get hashCode => Object.hash(ApplyLocalChange, reason);

  @override
  String toString() => 'ApplyLocalChange($reason)';
}

/// Serverdagi holat saqlanadi, mahalliy amal bekor qilinadi.
///
/// **Bu "ma'lumotni jimgina yo'qotish" EMAS:** amal `needsAttention`
/// holatiga o'tadi va foydalanuvchiga sabab ko'rsatiladi
/// (`QueuedSyncEngine`ga qarang).
class KeepServerState extends ConflictResolution {
  const KeepServerState({required this.reason});

  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is KeepServerState && other.reason == reason);

  @override
  int get hashCode => Object.hash(KeepServerState, reason);

  @override
  String toString() => 'KeepServerState($reason)';
}

/// Avtomatik va XAVFSIZ hal qilib bo'lmaydi — foydalanuvchiga
/// vaziyat tushuntirilib, keyingi qadamni tanlash imkoni beriladi
/// (`docs/ARCHITECTURE.md`: *"tizim taxminiy qaror qabul qilib,
/// ma'lumotni jimgina yo'qotish yoki noto'g'ri holatga majburlash
/// o'rniga..."*; `DEVELOPMENT_RULES.md`, 17–19-band, "No Dead End
/// Rule").
class EscalateToUser extends ConflictResolution {
  const EscalateToUser({required this.reason});

  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is EscalateToUser && other.reason == reason);

  @override
  int get hashCode => Object.hash(EscalateToUser, reason);

  @override
  String toString() => 'EscalateToUser($reason)';
}
