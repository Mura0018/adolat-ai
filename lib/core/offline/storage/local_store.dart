/// Mahalliy (on-device) ma'lumot to'plami ustidagi ABSTRAKT shartnoma
/// (`docs/ARCHITECTURE.md`, "Local Storage").
///
/// **Bu — Module 6A'ning asosiy almashtirish nuqtasi.** Hozircha yagona
/// implementatsiya — `InMemoryLocalStore` (poydevor, testda ishlaydi).
///
/// **Doimiy (persistent) implementatsiya — Drift** (`docs/adr/ADR-007-offline-local-storage.md`,
/// Qabul qilingan 2026-07-31). U shu interfeys ORTIGA qo'yiladi;
/// chaqiruvchi kod (`OfflineQueue`, `LocalStoreOfflineQueue`,
/// repository'lar) o'zgarmaydi. **Implementatsiya hali yozilmagan** —
/// alohida vazifa sifatida rejalashtirilgan.
///
/// **Nega Drift** (ADR-007ning qisqa xulosasi): migratsiya vaqtidagi
/// jimgina ma'lumot yo'qolishi shu qatlamning eng katta uzoq muddatli
/// xavfi va Drift unga versiyalangan migratsiya hamda migratsiyani
/// sinovdan o'tkazish vositalari bilan yagona to'liq javob beradi;
/// uning asosiy kamchiligi (kodgen) esa loyihada allaqachon mavjud
/// (`build_runner`), ya'ni qo'shimcha xarajat yaratmaydi.
///
/// **Xavfsizlik chegarasi:** bu yerga autentifikatsiya tokenlari
/// saqlanmaydi — ular `Flutter Secure Storage`da, alohida
/// (`docs/ARCHITECTURE.md`, "Local Storage" → *"Maxfiy ma'lumotlar
/// bilan chegara"*; `docs/SECURITY.md`, "JWT Security"). Bu qoida
/// `test/core/offline/offline_architecture_boundary_test.dart` bilan
/// avtomatik tekshiriladi.
abstract interface class LocalStore<T> {
  /// Qiymatni kalit bo'yicha yozadi (mavjud bo'lsa ustiga yozadi).
  Future<void> put(String key, T value);

  /// Kalit bo'yicha o'qiydi; topilmasa `null`.
  Future<T?> get(String key);

  /// Barcha qiymatlar — YOZILISH tartibida (`docs/ARCHITECTURE.md`,
  /// "Sync Engine": navbat FIFO tartibida qayta ishlanadi, shuning
  /// uchun tartib shartnomaning bir qismi).
  Future<List<T>> getAll();

  /// Barcha kalitlar — yozilish tartibida.
  Future<List<String>> keys();

  Future<bool> containsKey(String key);

  /// Kalitni o'chiradi; kalit bo'lmasa ham xatolik EMAS (idempotent).
  Future<void> delete(String key);

  /// To'plamni butunlay tozalaydi (`docs/ARCHITECTURE.md`, "Local
  /// Storage" → *"Hajm va tozalash siyosati"*).
  Future<void> clear();

  Future<int> count();
}

/// Nomlangan to'plamlarni ochib beruvchi mahalliy saqlash qatlami.
///
/// Bitta ilova ichida bir nechta mustaqil to'plam bo'ladi (masalan
/// `pending_operations`, `appeals_cache`, `laws_cache`) —
/// `docs/ARCHITECTURE.md`, "Local Storage" bo'limidagi saqlanadigan
/// ma'lumot turlariga mos.
abstract interface class LocalStorage {
  /// Nomlangan to'plamni qaytaradi; bir xil [name] bilan qayta
  /// chaqirilganda AYNAN shu to'plam qaytishi shart (aks holda
  /// ma'lumot "yo'qolgandek" ko'rinadi).
  LocalStore<Map<String, Object?>> collection(String name);

  /// Barcha to'plamlarni tozalaydi — masalan foydalanuvchi tizimdan
  /// chiqqanda (bir foydalanuvchining mahalliy ma'lumoti ikkinchisiga
  /// ko'rinib qolmasligi uchun).
  Future<void> clearAll();
}
