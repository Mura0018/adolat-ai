/// Serverdagi yozuvning MAHALLIY qatlam uchun ahamiyatli holati.
///
/// **Nega `AppealStatus`/`DisputeStatus` ishlatilmaydi:** `lib/core/`
/// feature enum'larini bilmasligi shart (`docs/ARCHITECTURE.md`,
/// "Ichki Kod Arxitekturasi" — bog'liqlik yo'nalishi). Har bir feature
/// o'z holatini shu uchta umumiy qiymatdan biriga XARITALAYDI
/// (masalan `draft`/`open` → [editable], `submitted`/`ai_analyzing` →
/// [locked]) — shu bilan ziddiyat qoidasi bitta joyda, feature'lardan
/// mustaqil yoziladi.
enum RecordEditability {
  /// Yozuv hali tahrirlash mumkin bo'lgan holatda (`draft`, `open`).
  editable,

  /// Yozuv rasmiylashgan/qulflangan — tarkibni o'zgartirib bo'lmaydi.
  locked,

  /// Server holati noma'lum (masalan javob olinmadi) — ATAYLAB
  /// alohida qiymat: "bilmaslik" hech qachon "ruxsat berilgan" deb
  /// talqin qilinmasligi kerak.
  unknown,
}

/// Ziddiyat NIMA ustida ekanligi (`docs/ARCHITECTURE.md`, "Conflict
/// Resolution").
enum ConflictKind {
  /// Yozuv HOLATI (`status`) ustidagi ziddiyat — server yakuniy hakam.
  status,

  /// Foydalanuvchi kiritgan TARKIB (matn/tavsif) ustidagi ziddiyat.
  content,

  /// Mahalliy tomonda o'chirish so'ralgan, lekin server tomonda yozuv
  /// o'zgargan.
  deletion,
}

/// Sinxronizatsiya vaqtida aniqlangan ziddiyat.
///
/// **Ziddiyatni bu model o'zi ANIQLAMAYDI** — uni serverga murojaat
/// qilgan qatlam (`SyncOperationHandler` implementatsiyasi, Module 6B+)
/// aniqlaydi va shu shaklda qaytaradi. Bu qatlam faqat ziddiyatni
/// TAVSIFLAYDI va qanday hal qilinishini `ConflictResolutionStrategy`
/// hal qiladi.
class SyncConflict {
  const SyncConflict({
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.kind,
    required this.serverEditability,
    this.localStatusLabel,
    this.serverStatusLabel,
  });

  final String operationId;
  final String entityType;
  final String entityId;
  final ConflictKind kind;

  /// Server tomonidagi yozuv hozir tahrirlash mumkinmi.
  final RecordEditability serverEditability;

  /// Diagnostika uchun xom holat nomlari (masalan `draft`,
  /// `submitted`) — foydalanuvchiga to'g'ridan-to'g'ri ko'rsatilmaydi.
  final String? localStatusLabel;
  final String? serverStatusLabel;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SyncConflict &&
            other.operationId == operationId &&
            other.entityType == entityType &&
            other.entityId == entityId &&
            other.kind == kind &&
            other.serverEditability == serverEditability &&
            other.localStatusLabel == localStatusLabel &&
            other.serverStatusLabel == serverStatusLabel);
  }

  @override
  int get hashCode => Object.hash(
    operationId,
    entityType,
    entityId,
    kind,
    serverEditability,
    localStatusLabel,
    serverStatusLabel,
  );

  @override
  String toString() =>
      'SyncConflict(operationId: $operationId, entityType: $entityType, '
      'kind: ${kind.name}, serverEditability: ${serverEditability.name})';
}
