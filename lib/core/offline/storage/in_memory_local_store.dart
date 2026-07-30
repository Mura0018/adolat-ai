import 'local_store.dart';

/// `LocalStore`ning xotiradagi (in-memory) POYDEVOR implementatsiyasi.
///
/// **Cheklov ATAYLAB va ochiq:** ma'lumot ilova yopilganda YO'QOLADI —
/// ya'ni bu `docs/ARCHITECTURE.md`ning "Doimiylik (persistence)"
/// talabini QONDIRMAYDI. U ikki maqsad uchun mavjud:
/// 1. shartnomaning (`LocalStore`) haqiqatan ishlashini ko'rsatish va
///    testlarda ishlatish;
/// 2. haqiqiy doimiy implementatsiya kelgunga qadar yuqori qatlamlarni
///    (`OfflineQueue`, `QueuedSyncEngine`) to'liq qurish va sinash
///    imkonini berish.
///
/// `ai_service/data/session/in_memory_conversation_repository.dart`
/// (Module 4) va `InMemoryCaseRepository` (Module 5) bilan bir xil
/// naqsh va bir xil ogohlantirish.
class InMemoryLocalStore<T> implements LocalStore<T> {
  final Map<String, T> _entries = <String, T>{};

  @override
  Future<void> put(String key, T value) async {
    _entries[key] = value;
  }

  @override
  Future<T?> get(String key) async => _entries[key];

  // Dart'ning `Map`i kalitlarni QO'SHILISH tartibida saqlaydi
  // (LinkedHashMap) — `LocalStore` shartnomasidagi FIFO kafolati shunga
  // tayanadi.
  @override
  Future<List<T>> getAll() async => List<T>.unmodifiable(_entries.values);

  @override
  Future<List<String>> keys() async => List<String>.unmodifiable(_entries.keys);

  @override
  Future<bool> containsKey(String key) async => _entries.containsKey(key);

  @override
  Future<void> delete(String key) async {
    _entries.remove(key);
  }

  @override
  Future<void> clear() async {
    _entries.clear();
  }

  @override
  Future<int> count() async => _entries.length;
}

/// `LocalStorage`ning xotiradagi implementatsiyasi — nomlangan
/// to'plamlarni saqlaydi va bir xil nom uchun AYNAN bitta to'plam
/// qaytaradi.
class InMemoryLocalStorage implements LocalStorage {
  final Map<String, InMemoryLocalStore<Map<String, Object?>>> _collections =
      <String, InMemoryLocalStore<Map<String, Object?>>>{};

  @override
  LocalStore<Map<String, Object?>> collection(String name) {
    return _collections.putIfAbsent(name, InMemoryLocalStore<Map<String, Object?>>.new);
  }

  @override
  Future<void> clearAll() async {
    for (final store in _collections.values) {
      await store.clear();
    }
  }
}
