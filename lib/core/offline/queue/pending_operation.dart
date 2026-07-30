/// Navbatdagi amalning TURI (`docs/ARCHITECTURE.md`, "Local Storage" —
/// saqlanadigan ma'lumot turlari ro'yxati bilan 1:1 mos).
///
/// **Provayderdan mustaqil:** bu yerda Supabase jadval nomi ham,
/// endpoint ham yo'q — amal QANDAY bajarilishi `SyncOperationHandler`
/// implementatsiyasining ishi (Module 6B va undan keyin).
enum PendingOperationKind {
  /// Yangi yozuv yaratish (murojaat/nizo qoralamasi).
  createRecord,

  /// Mavjud yozuvni tahrirlash.
  updateRecord,

  /// Yozuvni o'chirish.
  deleteRecord,

  /// Yozuvni rasmiy holatga o'tkazish (masalan `draft` -> `submitted`).
  submitRecord,

  /// Biriktirilgan faylni Storage Layer'ga yuklash.
  uploadAttachment,

  /// AI tahlil so'rovi (`docs/ARCHITECTURE.md`, "Sync Engine" —
  /// AI vazifalari navbati bilan integratsiya).
  requestAiAnalysis,
}

/// Navbatdagi amalning HOLATI — foydalanuvchiga ko'rsatiladigan
/// "shaffof holat"ning manbai (`docs/ARCHITECTURE.md`, "Offline-First
/// Architecture": *"lokal saqlangan / yuborilishi kutilmoqda",
/// "sinxronlanmoqda", "serverga yetkazildi"*).
///
/// **`failed` va `needsAttention` ATAYLAB alohida:** birinchisi
/// VAQTINCHALIK xatolik (qayta uriniladi), ikkinchisi DOIMIY xatolik
/// (serverning qat'iy rad etishi) — talab: *"jimgina cheksiz qayta
/// urinilmaydi"*, foydalanuvchiga aniq xabar ko'rsatiladi.
enum PendingOperationStatus {
  /// Lokal saqlangan, yuborilishi kutilmoqda.
  pending,

  /// Hozir sinxronlanmoqda.
  inProgress,

  /// Vaqtinchalik xatolik — navbatda qoladi, backoff bilan qayta
  /// uriniladi.
  failed,

  /// Doimiy xatolik yoki avtomatik hal qilib bo'lmaydigan ziddiyat —
  /// foydalanuvchi aralashuvi kerak ("No Dead End Rule": nima
  /// qilish kerakligi ko'rsatiladi).
  needsAttention,

  /// Serverga yetkazildi.
  completed;

  /// Sinxronizatsiya uchun olinishi mumkinmi.
  bool get isSyncable => this == pending || this == failed;

  /// Yakuniy (boshqa o'zgarmaydigan) holatmi.
  bool get isTerminal => this == completed;
}

/// Serverga yetkazilishi kutilayotgan BITTA amal (`docs/ARCHITECTURE.md`,
/// "Local Storage" — *"navbatdagi yozuvlar"* va *"sinxronizatsiya
/// metama'lumoti"*).
///
/// O'zgarmas (immutable): har bir holat o'zgarishi YANGI nusxa
/// qaytaradi — `ai_service/`dagi `Case`/`AIConversation` bilan bir xil
/// naqsh.
///
/// **Nega Freezed emas:** bu qatlam ataylab kodgen (build_runner)
/// artefaktlaridan xoli — Dart 3'ning o'zi (`sealed`, pattern matching)
/// kerakli narsani beradi va offline yadro hech qanday generatsiya
/// bosqichiga bog'lanmaydi. Bu tanlov `Failure`/`Result` (freezed)ga
/// zid emas: ular DTO/union, bular esa xatti-harakatga ega entity'lar.
class PendingOperation {
  const PendingOperation({
    required this.id,
    required this.kind,
    required this.entityType,
    required this.entityId,
    required this.payload,
    required this.createdAt,
    this.status = PendingOperationStatus.pending,
    this.attemptCount = 0,
    this.lastAttemptAt,
    this.lastError,
    this.dependsOnOperationId,
  }) : assert(attemptCount >= 0);

  /// **Mahalliy tomonda generatsiya qilingan BARQAROR identifikator** —
  /// `docs/ARCHITECTURE.md`, "Sync Engine", idempotentlik talabi:
  /// *"bir xil amal ikki marta yuborilib qolsa ham, backend uni
  /// takroriy emas, bitta amal sifatida tan oladi"*.
  ///
  /// Shu sababli [id] amal qayta urinilganda HECH QACHON
  /// o'zgarmaydi — u idempotentlik kaliti sifatida serverga uzatilishi
  /// mo'ljallangan.
  final String id;

  final PendingOperationKind kind;

  /// Qaysi TURDAGI yozuvga tegishli (masalan `appeal`, `dispute`) —
  /// ataylab `String`, chunki `lib/core/` feature enum'larini
  /// (`AppealStatus` va h.k.) bilmasligi kerak.
  final String entityType;

  /// Yozuvning MAHALLIY identifikatori.
  final String entityId;

  /// Amal uchun kerakli ma'lumot — oddiy, seriyalanadigan xarita.
  ///
  /// **Xavfsizlik:** bu yerga autentifikatsiya tokeni yoki API kaliti
  /// HECH QACHON yozilmaydi (`docs/ARCHITECTURE.md`, "Local Storage" —
  /// tokenlar faqat `Flutter Secure Storage`da). [toString] payload
  /// mazmunini chiqarmaydi (pastga qarang).
  final Map<String, Object?> payload;

  final DateTime createdAt;
  final PendingOperationStatus status;

  /// Nechta marta urinilgan — backoff hisobi shunga tayanadi
  /// (`SyncBackoffPolicy`).
  final int attemptCount;

  final DateTime? lastAttemptAt;

  /// Oxirgi xatolikning TEXNIK tavsifi — foydalanuvchiga
  /// to'g'ridan-to'g'ri ko'rsatilmaydi (`core/error/failure_presentation.dart`
  /// bilan bir xil intizom).
  final String? lastError;

  /// Bog'liqlik: bu amal boshqa amal muvaffaqiyatli tugamaguncha
  /// yuborilmaydi (`docs/ARCHITECTURE.md`, "Sync Engine": *"avval
  /// murojaat yozuvi, keyin unga biriktirilgan fayl... fayl hali
  /// mavjud bo'lmagan yozuvga bog'lanib qolmasligi uchun"*).
  final String? dependsOnOperationId;

  bool get isSyncable => status.isSyncable;

  bool get hasDependency => dependsOnOperationId != null;

  PendingOperation markInProgress({required DateTime at}) {
    return _copyWith(
      status: PendingOperationStatus.inProgress,
      attemptCount: attemptCount + 1,
      lastAttemptAt: at,
    );
  }

  PendingOperation markCompleted() {
    return _copyWith(status: PendingOperationStatus.completed, clearError: true);
  }

  /// Vaqtinchalik xatolik — amal navbatda QOLADI.
  PendingOperation markFailed(String error) {
    return _copyWith(status: PendingOperationStatus.failed, lastError: error);
  }

  /// Doimiy xatolik yoki hal qilib bo'lmaydigan ziddiyat — qayta
  /// urinilmaydi, foydalanuvchiga ko'rsatiladi.
  PendingOperation markNeedsAttention(String reason) {
    return _copyWith(status: PendingOperationStatus.needsAttention, lastError: reason);
  }

  PendingOperation _copyWith({
    PendingOperationStatus? status,
    int? attemptCount,
    DateTime? lastAttemptAt,
    String? lastError,
    bool clearError = false,
  }) {
    return PendingOperation(
      id: id,
      kind: kind,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      createdAt: createdAt,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: clearError ? null : (lastError ?? this.lastError),
      dependsOnOperationId: dependsOnOperationId,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PendingOperation &&
            other.id == id &&
            other.kind == kind &&
            other.entityType == entityType &&
            other.entityId == entityId &&
            other.createdAt == createdAt &&
            other.status == status &&
            other.attemptCount == attemptCount &&
            other.lastAttemptAt == lastAttemptAt &&
            other.lastError == lastError &&
            other.dependsOnOperationId == dependsOnOperationId);
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    entityType,
    entityId,
    createdAt,
    status,
    attemptCount,
    lastAttemptAt,
    lastError,
    dependsOnOperationId,
  );

  /// **Xavfsizlik:** [payload] (foydalanuvchi kiritgan matn — murojaat
  /// tarkibi, sezgir bo'lishi mumkin) va [lastError] (xom texnik matn)
  /// ATAYLAB chiqarilmaydi — `Case.toString()` (Module 5) va
  /// `AIBackendCredential.toString()` (Module 4) bilan bir xil intizom.
  @override
  String toString() =>
      'PendingOperation(id: $id, kind: ${kind.name}, entityType: $entityType, '
      'status: ${status.name}, attempts: $attemptCount)';
}
