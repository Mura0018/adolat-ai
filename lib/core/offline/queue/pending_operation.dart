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
  requestAiAnalysis;

  /// Bu turdagi yangi amal, xuddi shu yozuv ustidagi ESKI (hali
  /// boshlanmagan) amalni ORTIQCHA qiladimi (Module 6C).
  ///
  /// **Faqat [updateRecord] uchun `true`.** Sabab: tahrirlash amali
  /// yozuvning TO'LIQ yangi holatini olib yuradi, shuning uchun
  /// oflaynda ketma-ket beshta tahrir qilingan bo'lsa, serverga
  /// beshta so'rov emas, eng so'nggisi yuborilishi kifoya.
  ///
  /// **Nega qolganlari uchun `false` — ataylab ehtiyotkor:**
  /// - [createRecord]/[submitRecord]/[deleteRecord] — bir marta
  ///   bajariladigan, hayot-davri amallari; ularni "almashtirish"
  ///   mantiqan noto'g'ri bo'lardi;
  /// - [uploadAttachment]/[requestAiAnalysis] — QO'SHIMCHA qiluvchi
  ///   amallar: ikkita fayl yoki ikkita tahlil so'rovi bir-birining
  ///   o'rnini bosmaydi. Ularni birlashtirsak, foydalanuvchining
  ///   ishi JIMGINA yo'qolardi — bu butun offline qatlamining asosiy
  ///   va'dasiga zid.
  ///
  /// Shubha bo'lganda javob har doim `false`: ortiqcha so'rov
  /// yuborish — yo'qolgan ma'lumotdan ko'ra ancha arzon xato.
  bool get supersedesPending => this == PendingOperationKind.updateRecord;
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

  /// Bir xil MANTIQIY amalmi — bir xil yozuv ustidagi bir xil turdagi
  /// amal (Module 6C).
  ///
  /// `id` bo'yicha tenglikdan FARQLI: foydalanuvchi oflaynda bitta
  /// qoralamani ikki marta tahrirlasa, ikkita HAR XIL `id`li, lekin
  /// mantiqan bir xil `updateRecord` amali paydo bo'ladi — ikkinchisi
  /// birinchisini ORTIQCHA qiladi (`OfflineQueue.enqueue`ga qarang).
  bool isSameLogicalOperationAs(PendingOperation other) {
    return other.kind == kind &&
        other.entityType == entityType &&
        other.entityId == entityId;
  }

  /// [other] shu amalning o'rnini bosa oladimi — mantiqan bir xil VA
  /// turi almashtirishga ruxsat beradigan bo'lsa.
  bool canBeSupersededBy(PendingOperation other) {
    return other.kind.supersedesPending && isSameLogicalOperationAs(other);
  }

  /// Doimiy saqlashga yozish uchun oddiy xarita (Module 6C).
  ///
  /// **Nega kerak:** Phase 6A `LocalStore` (saqlash) va `OfflineQueue`
  /// (navbat) shartnomalarini alohida belgilagan edi, lekin ularni
  /// ULAYDIGAN bo'g'in yo'q edi — `PendingOperation`ni saqlab
  /// bo'lmasdi, ya'ni navbat hech qachon ilova qayta ochilganda
  /// tiklanmasdi. Bu — offline-first talabining ("Doimiylik") o'zagi.
  ///
  /// Format ataylab oddiy (`Map<String, Object?>`, faqat primitivlar):
  /// hech qanday kodgen yoki paketga bog'liq emas, shuning uchun
  /// istalgan saqlash implementatsiyasi (JSON, sqlite, key-value) uni
  /// qabul qila oladi.
  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'kind': kind.name,
      'entityType': entityType,
      'entityId': entityId,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'attemptCount': attemptCount,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'lastError': lastError,
      'dependsOnOperationId': dependsOnOperationId,
    };
  }

  /// Saqlangan xaritadan tiklaydi.
  ///
  /// Noma'lum `kind`/`status` qiymati uchun **jimgina standart
  /// qiymatga tushib qolmaydi** — `FormatException` tashlanadi.
  /// Sabab: noto'g'ri tiklangan amal serverga NOTO'G'RI so'rov
  /// yuborishi mumkin edi (masalan `deleteRecord` o'rniga
  /// `createRecord`), bu esa ma'lumot yo'qolishiga olib borardi.
  factory PendingOperation.fromJson(Map<String, Object?> json) {
    final kindName = json['kind'] as String?;
    final statusName = json['status'] as String?;

    return PendingOperation(
      id: json['id']! as String,
      kind: PendingOperationKind.values.firstWhere(
        (value) => value.name == kindName,
        orElse: () => throw FormatException('Noma\'lum PendingOperationKind: $kindName'),
      ),
      entityType: json['entityType']! as String,
      entityId: json['entityId']! as String,
      payload: Map<String, Object?>.from((json['payload'] as Map?) ?? const {}),
      createdAt: DateTime.parse(json['createdAt']! as String),
      status: PendingOperationStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => throw FormatException('Noma\'lum PendingOperationStatus: $statusName'),
      ),
      attemptCount: (json['attemptCount'] as int?) ?? 0,
      lastAttemptAt: json['lastAttemptAt'] == null
          ? null
          : DateTime.parse(json['lastAttemptAt']! as String),
      lastError: json['lastError'] as String?,
      dependsOnOperationId: json['dependsOnOperationId'] as String?,
    );
  }

  /// Foydalanuvchi "qayta urinish"ni so'raganda — `needsAttention`
  /// holatidan navbatga qaytaradi (Module 6C, queue lifecycle).
  ///
  /// Urinishlar hisobi NOLGA qaytariladi: bu foydalanuvchining ONGLI
  /// qarori, avvalgi avtomatik urinishlar tarixi uni cheklamasligi
  /// kerak ("No Dead End Rule" — foydalanuvchiga har doim keyingi
  /// qadam bo'lishi shart).
  PendingOperation resetForManualRetry() {
    return PendingOperation(
      id: id,
      kind: kind,
      entityType: entityType,
      entityId: entityId,
      payload: payload,
      createdAt: createdAt,
      status: PendingOperationStatus.pending,
      attemptCount: 0,
      lastAttemptAt: null,
      lastError: null,
      dependsOnOperationId: dependsOnOperationId,
    );
  }

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
