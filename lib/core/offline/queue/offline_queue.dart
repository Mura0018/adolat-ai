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
  /// Bir xil [PendingOperation.id] bilan qayta chaqirilsa, YANGI yozuv
  /// yaratilmaydi — mavjudi yangilanadi (idempotentlik: bir xil amal
  /// ikki marta navbatga tushmaydi).
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

  /// Muvaffaqiyatli yakunlangan amallarni tozalaydi
  /// (`docs/ARCHITECTURE.md`, "Local Storage" → *"Hajm va tozalash
  /// siyosati"*). Nechta yozuv tozalangani qaytariladi.
  Future<int> removeCompleted();

  /// Navbatdagi (hali yetkazilmagan) amallar soni.
  Future<int> pendingCount();
}
