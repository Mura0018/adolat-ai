import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/offline/storage/local_store.dart';
import 'app_local_database.dart';

/// `LocalStore` shartnomasining Drift (SQLite) implementatsiyasi —
/// `docs/adr/ADR-007-offline-local-storage.md` (Qabul qilingan
/// 2026-07-31) qarorining amalga oshirilishi.
///
/// **Nima o'zgardi:** Module 6A'dan beri offline qatlami
/// `InMemoryLocalStore` bilan ishlar edi, ya'ni ma'lumot ilova
/// yopilganda yo'qolardi. Bu klass shu bo'shliqni yopadi —
/// `docs/ARCHITECTURE.md`, "Local Storage" → *"Doimiylik
/// (persistence)"* talabi.
///
/// **Nima O'ZGARMADI:** `LocalStore` interfeysi, `OfflineQueue`,
/// `LocalStoreOfflineQueue`, `QueuedSyncEngine`, `SyncCoordinator` —
/// hech biri. Module 6A shu almashtirish uchun loyihalashtirilgan edi
/// va almashtirish narxi aynan bitta klass bo'lib chiqdi.
///
/// Xatti-harakat `InMemoryLocalStore` bilan **bir xil** bo'lishi shart —
/// ikkalasi bir xil shartnoma testlaridan o'tkaziladi
/// (`test/core/offline/local_store_contract_test.dart`).
class DriftLocalStore implements LocalStore<Map<String, Object?>> {
  const DriftLocalStore(this._db, this._collection);

  final AppLocalDatabase _db;
  final String _collection;

  /// Shu to'plamga tegishli qatorlar, **kiritilish tartibida**.
  ///
  /// Tartib `id` (autoIncrement) bo'yicha aniq belgilanadi — SQL
  /// qatorlar tartibini o'zi kafolatlamaydi.
  SimpleSelectStatement<$LocalStoreEntriesTable, LocalStoreEntry> get _ordered {
    return _db.select(_db.localStoreEntries)
      ..where((row) => row.collection.equals(_collection))
      ..orderBy([(row) => OrderingTerm.asc(row.id)]);
  }

  Map<String, Object?> _decode(String raw) {
    return Map<String, Object?>.from(jsonDecode(raw) as Map);
  }

  @override
  Future<void> put(String key, Map<String, Object?> value) async {
    final encoded = jsonEncode(value);

    // MAVJUD kalit uchun faqat qiymat yangilanadi, `id` TEGILMAYDI --
    // shu bilan yozuv navbatdagi o'z o'rnini saqlaydi.
    // `InMemoryLocalStore` (Dart Map) xuddi shunday ishlaydi va
    // `OfflineQueue`ning FIFO adolati shunga bog'liq: qayta yozilgan
    // amal navbat oxiriga "sakramaydi".
    final updated =
        await (_db.update(_db.localStoreEntries)..where(
              (row) => row.collection.equals(_collection) & row.key.equals(key),
            ))
            .write(LocalStoreEntriesCompanion(value: Value(encoded)));

    if (updated == 0) {
      await _db
          .into(_db.localStoreEntries)
          .insert(
            LocalStoreEntriesCompanion.insert(
              collection: _collection,
              key: key,
              value: encoded,
            ),
          );
    }
  }

  @override
  Future<Map<String, Object?>?> get(String key) async {
    final row =
        await (_db.select(_db.localStoreEntries)..where(
              (row) => row.collection.equals(_collection) & row.key.equals(key),
            ))
            .getSingleOrNull();

    return row == null ? null : _decode(row.value);
  }

  @override
  Future<List<Map<String, Object?>>> getAll() async {
    final rows = await _ordered.get();
    return List<Map<String, Object?>>.unmodifiable(
      rows.map((row) => _decode(row.value)),
    );
  }

  @override
  Future<List<String>> keys() async {
    final rows = await _ordered.get();
    return List<String>.unmodifiable(rows.map((row) => row.key));
  }

  @override
  Future<bool> containsKey(String key) async => await get(key) != null;

  @override
  Future<void> delete(String key) async {
    // Kalit bo'lmasa ham xatolik EMAS (shartnoma: idempotent).
    await (_db.delete(_db.localStoreEntries)..where(
          (row) => row.collection.equals(_collection) & row.key.equals(key),
        ))
        .go();
  }

  @override
  Future<void> clear() async {
    await (_db.delete(
      _db.localStoreEntries,
    )..where((row) => row.collection.equals(_collection))).go();
  }

  @override
  Future<int> count() async {
    final rows = await _ordered.get();
    return rows.length;
  }
}

/// `LocalStorage` shartnomasining Drift implementatsiyasi.
///
/// To'plamlar bitta jadval ichida `collection` ustuni bilan
/// ajratiladi (`app_local_database.dart`dagi izohga qarang) —
/// shuning uchun yangi to'plam qo'shish migratsiya talab qilmaydi.
class DriftLocalStorage implements LocalStorage {
  const DriftLocalStorage(this._db);

  final AppLocalDatabase _db;

  /// Bir xil nom uchun mantiqan AYNAN bitta to'plam qaytariladi —
  /// `DriftLocalStore` holat saqlamaydi, u faqat nom bo'yicha
  /// filtrlaydi, shuning uchun har bir chaqiruvda yangi obyekt
  /// qaytarish ham shartnomani buzmaydi.
  @override
  LocalStore<Map<String, Object?>> collection(String name) {
    return DriftLocalStore(_db, name);
  }

  @override
  Future<void> clearAll() async {
    await _db.delete(_db.localStoreEntries).go();
  }
}
