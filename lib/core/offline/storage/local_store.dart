/// Mahalliy (on-device) ma'lumot to'plami ustidagi ABSTRAKT shartnoma
/// (`docs/ARCHITECTURE.md`, "Local Storage").
///
/// **Bu — Module 6A'ning asosiy almashtirish nuqtasi.** Hozircha yagona
/// implementatsiya — `InMemoryLocalStore` (poydevor, testda ishlaydi).
/// Haqiqiy doimiy (persistent) implementatsiya (Drift/Isar/Hive/sqflite —
/// hali TANLANMAGAN) shu interfeys ORTIGA qo'yiladi; chaqiruvchi kod
/// (`OfflineQueue`, repository'lar) o'zgarmaydi.
///
/// **Nega paket tanlovi hali qilinmagan:** `docs/DEVELOPMENT_RULES.md`,
/// 3-band ("Claude Code hech qachon taxmin qilib kod yozmaydi") —
/// saqlash paketini tanlash mahsulot/infratuzilma qarori (shifrlash,
/// migratsiya, platforma qo'llab-quvvatlashi bo'yicha talablarga
/// bog'liq) va u ADR sifatida rasmiylashtirilishi kerak. Shartnomani
/// oldindan belgilash esa shu qaror kechikkan holda ham ish davom
/// etishiga imkon beradi.
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
