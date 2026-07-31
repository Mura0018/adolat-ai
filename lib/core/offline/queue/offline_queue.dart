import 'pending_operation.dart';

/// Serverga yetkazilishi kutayotgan amallar navbati
/// (`docs/ARCHITECTURE.md`, "Local Storage" va "Sync Engine").
///
/// Shartnoma darajasida kafolatlanadigan uchta narsa:
/// 1. **FIFO** — [nextBatch] amallarni YARATILGAN tartibida qaytaradi
///    (*"navbatdagi amallar yaratilgan tartibda (FIFO) qayta
///    ishlanadi"*);
/// 2. **Bog'liqlik tartibi** — bog'liq amal (`dependsOnOperationId`)
///    o'zi bog'langan amal tugamaguncha qaytarilmaydi (*"fayl hali
///    mavjud bo'lmagan yozuvga bog'lanib qolmasligi uchun"*);
/// 3. **Amal jimgina yo'qolmaydi** — muvaffaqiyatsizlikda navbatdan
///    OLIB TASHLANMAYDI, faqat holati o'zgaradi (*"amal navbatdan olib
///    tashlanmaydi... toki muvaffaqiyatli yakunlanmaguncha yoki
///    foydalanuvchi tomonidan bekor qilinmaguncha"*).
abstract interface class OfflineQueue {
  /// Yangi amalni navbatga qo'yadi.
  ///
  /// **Idempotentlik va takrorlanish qoidalari (Module 6C):**
  ///
  /// 1. Bir xil [PendingOperation.id] bilan qayta chaqirilsa, YANGI
  ///    yozuv yaratilmaydi.
  /// 2. **Mavjud amal ALLAQACHON boshlangan bo'lsa (`inProgress`)
  ///    yoki yakunlangan bo'lsa (`completed`), u USTIGA
  ///    YOZILMAYDI** — chaqiruv jimgina e'tiborsiz qoldiriladi.
  ///    Aks holda ish vaqtidagi holat (urinishlar soni, `inProgress`
  ///    belgisi) nolga qaytib, ayni damda yuborilayotgan amal
  ///    IKKINCHI marta yuborilishi mumkin edi — bu aynan
  ///    idempotentlik buzilishi (Phase 6A/6B integratsiyasida
  ///    aniqlangan bo'shliq).
  /// 3. **Mantiqan bir xil amal** (bir xil `entityType`+`entityId`+
  ///    `kind`, lekin boshqa `id`) navbatda `pending` holatida
  ///    turgan bo'lsa, u YANGISI bilan ALMASHTIRILADI
  ///    (`PendingOperation.isSameLogicalOperationAs`). Foydalanuvchi
  ///    bitta qoralamani oflaynda besh marta tahrirlasa, serverga
  ///    beshta emas, ENG SO'NGGI holat yuboriladi. Faqat hali
  ///    boshlanmagan (`pending`) amal almashtiriladi — boshlangani
  ///    hech qachon tegilmaydi.
  Future<void> enqueue(PendingOperation operation);

  /// Sinxronizatsiya uchun TAYYOR amallar — FIFO tartibida, bog'liqligi
  /// qanoatlantirilganlari.
  ///
  /// "Tayyor" degani: holati `pending` yoki `failed`
  /// (`PendingOperationStatus.isSyncable`) VA bog'langan amali (agar
  /// bo'lsa) allaqachon `completed`.
  Future<List<PendingOperation>> nextBatch({int limit});

  /// Amalning yangilangan nusxasini saqlaydi (holat/urinishlar soni
  /// o'zgargandan keyin).
  Future<void> update(PendingOperation operation);

  Future<PendingOperation?> getById(String operationId);

  /// Barcha amallar (holatidan qat'i nazar) — foydalanuvchiga
  /// "navbatda nechta amal bor" ko'rsatish uchun
  /// (`docs/ARCHITECTURE.md`, "Network State Handling").
  Future<List<PendingOperation>> getAll();

  Future<List<PendingOperation>> getByStatus(PendingOperationStatus status);

  /// Foydalanuvchi ataylab bekor qilgan amalni olib tashlaydi — bu
  /// YAGONA yo'l bilan amal navbatdan yo'qoladi (avtomatik emas).
  Future<void> remove(String operationId);

  /// Foydalanuvchi `needsAttention` holatidagi amalni QAYTA URINISHGA
  /// yuboradi (Module 6C, queue lifecycle).
  ///
  /// **Nega kerak:** 6A/6B'da amal `needsAttention`ga tushgach,
  /// undan CHIQISH yo'li yo'q edi — foydalanuvchiga "e'tibor talab
  /// qiladi" deb ko'rsatilardi-yu, u hech narsa qila olmasdi. Bu
  /// `DEVELOPMENT_RULES.md`, 17–19-bandlar ("No Dead End Rule")ning
  /// bevosita buzilishi edi.
  ///
  /// Urinishlar hisobi nolga qaytariladi
  /// (`PendingOperation.resetForManualRetry`).
  ///
  /// Amal topilmasa yoki `needsAttention`da bo'lmasa — hech narsa
  /// qilmaydi (idempotent).
  Future<void> retryNow(String operationId);

  /// Berilgan amalga BOG'LIQ bo'lgan amallar (`dependsOnOperationId`).
  ///
  /// Bog'liqlik zanjirini kuzatish uchun kerak: agar ota-amal
  /// bajarilmasa, unga bog'langanlar mangu kutib qolmasligi shart
  /// (`QueuedSyncEngine` shu ro'yxatni bloklash uchun ishlatadi).
  Future<List<PendingOperation>> dependentsOf(String operationId);

  /// Muvaffaqiyatli yakunlangan amallarni tozalaydi
  /// (`docs/ARCHITECTURE.md`, "Local Storage" → *"Hajm va tozalash
  /// siyosati"*). Nechta yozuv tozalangani qaytariladi.
  Future<int> removeCompleted();

  /// Navbatdagi (hali yetkazilmagan) amallar soni.
  Future<int> pendingCount();
}
