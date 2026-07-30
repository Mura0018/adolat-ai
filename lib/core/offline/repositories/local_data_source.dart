/// Mahalliy (on-device) datasource uchun UMUMIY shartnoma
/// (`docs/ARCHITECTURE.md`, "Local Storage": *"Local Storage
/// `data/datasources/` ichida alohida lokal datasource sifatida
/// namoyon bo'ladi, u Supabase bilan ishlaydigan remote datasource
/// bilan bir xil `domain/repositories/` shartnomasini amalga
/// oshiradi"*).
///
/// **Qatlamlash:** bu interfeys `domain`ga TEGMAYDI — mavjud
/// `AppealsRepository`/`DisputesRepository` (feature `domain/`ida)
/// o'zgarishsiz qoladi. Repository IMPLEMENTATSIYASI (data qatlami)
/// kelgusida remote va lokal datasource'larni birgalikda ishlatadi;
/// `domain`/`presentation` bu haqda hech narsa bilmaydi.
///
/// **Module 6A'da hech bir feature bu interfeysga ULANMAGAN** — bu
/// ataylab: 6A faqat shartnoma bosqichi, mavjud kod o'zgartirilmaydi.
abstract interface class LocalDataSource<T> {
  /// Yozuvni mahalliy nusxaga saqlaydi (serverdan kelgan yoki
  /// foydalanuvchi yaratgan).
  Future<void> save(String id, T item);

  /// Bir nechta yozuvni birdaniga saqlaydi (masalan serverdan ro'yxat
  /// olingandan keyin).
  Future<void> saveAll(Map<String, T> items);

  Future<T?> getById(String id);

  /// Mahalliy nusxadagi barcha yozuvlar — internet bo'lmaganda ham
  /// ko'rsatiladigan ma'lumot (*"Faqat ko'rish uchun ham offline
  /// qamrov"*).
  Future<List<T>> getAll();

  Future<void> delete(String id);

  /// Mahalliy nusxani butunlay tozalaydi (masalan chiqishda).
  Future<void> clear();

  /// Mahalliy nusxa oxirgi marta qachon serverdan yangilangani —
  /// `null` bo'lsa, hech qachon yangilanmagan.
  ///
  /// Bu ma'lumot foydalanuvchiga "ma'lumot eskirgan bo'lishi mumkin"
  /// deb ko'rsatish uchun kerak (*"faqat eng so'nggi o'zgarishlar
  /// internet tiklanganda yangilanadi"*).
  Future<DateTime?> lastSyncedAt();

  Future<void> markSyncedAt(DateTime timestamp);
}

/// Mahalliy yozuvning sinxronizatsiya nuqtai nazaridan holati —
/// foydalanuvchiga ro'yxatda belgi sifatida ko'rsatiladi
/// (`docs/ARCHITECTURE.md`: *"lokal saqlangan / yuborilishi
/// kutilmoqda", "sinxronlanmoqda", "serverga yetkazildi"*).
///
/// **`PendingOperationStatus` bilan ADASHTIRILMASIN:** u BITTA
/// AMALning holati (masalan "faylni yuklash"), bu esa YOZUVning
/// (masalan murojaatning) umumiy ko'rinishi — bitta yozuv ustida bir
/// nechta amal bo'lishi mumkin.
enum RecordSyncStatus {
  /// Faqat qurilmada mavjud, serverga hali yuborilmagan.
  localOnly,

  /// Yuborilishi kutilmoqda (navbatda).
  pendingSync,

  /// Hozir yuborilmoqda.
  syncing,

  /// Serverga yetkazilgan va mahalliy nusxa server bilan mos.
  synced,

  /// Foydalanuvchi e'tibori kerak (doimiy xatolik yoki ziddiyat).
  needsAttention,
}

/// Sinxronizatsiya holatini ham bera oladigan repository shartnomasi.
///
/// Mavjud feature repository'lari (`AppealsRepository` va h.k.) bu
/// interfeysni ALMASHTIRMAYDI — kelgusida ular shu qo'shimcha
/// shartnomani ham amalga oshirishi mumkin (`implements
/// AppealsRepository, OfflineCapableRepository`), shu bilan UI
/// yozuvning holatini so'rashi mumkin bo'ladi.
abstract interface class OfflineCapableRepository {
  /// Berilgan yozuvning joriy sinxronizatsiya holati.
  Future<RecordSyncStatus> syncStatusOf(String entityId);

  /// Shu repository'ga tegishli, hali yuborilmagan amallar soni.
  Future<int> pendingOperationCount();
}
