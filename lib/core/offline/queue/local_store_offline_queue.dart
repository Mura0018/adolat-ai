import '../storage/local_store.dart';
import 'offline_queue.dart';
import 'pending_operation.dart';

/// `OfflineQueue`ning `LocalStore` ustiga qurilgan implementatsiyasi
/// (Module 6C).
///
/// **Nega bu bo'g'in muhim:** Phase 6A `LocalStore` (saqlash) va
/// `OfflineQueue` (navbat) shartnomalarini alohida belgilagan, lekin
/// ularni ULAYDIGAN kod yo'q edi — natijada navbat har doim xotirada
/// qolar, ilova yopilganda yo'qolardi. Bu esa
/// `docs/ARCHITECTURE.md`ning **"Doimiylik (persistence)"** talabini —
/// *"foydalanuvchi qurilmani o'chirib-yoqsa ham, hali sinxronlanmagan
/// murojaat/nizo va navbatdagi vazifalar saqlanib qoladi"* —
/// bajarib bo'lmasligini bildirardi.
///
/// Shu klass yozilgach, doimiylik uchun **faqat bitta narsa**
/// qoladi: `LocalStore`ning doimiy implementatsiyasi (paket tanlovi
/// ADR bilan). Navbat mantig'ining o'zi qayta yozilmaydi.
///
/// **Xatti-harakat `InMemoryOfflineQueue` bilan AYNAN bir xil**
/// bo'lishi shart — shu sababli ikkalasi ham bir xil shartnoma
/// testlaridan o'tkaziladi (`test/core/offline/offline_queue_contract_test.dart`).
class LocalStoreOfflineQueue implements OfflineQueue {
  const LocalStoreOfflineQueue(this._store);

  final LocalStore<Map<String, Object?>> _store;

  Future<List<PendingOperation>> _allOrdered() async {
    final rows = await _store.getAll();
    return [for (final row in rows) PendingOperation.fromJson(row)];
  }

  @override
  Future<void> enqueue(PendingOperation operation) async {
    final existingRow = await _store.get(operation.id);
    if (existingRow != null) {
      final existing = PendingOperation.fromJson(existingRow);
      // Boshlangan/yakunlangan amal ustiga yozilmaydi.
      if (!existing.status.isSyncable) return;
    }

    // Mantiqan bir xil, hali boshlanmagan amallar almashtiriladi.
    for (final candidate in await _allOrdered()) {
      if (candidate.id == operation.id) continue;
      if (candidate.status != PendingOperationStatus.pending) continue;
      if (!candidate.canBeSupersededBy(operation)) continue;
      await _store.delete(candidate.id);
    }

    await _store.put(operation.id, operation.toJson());
  }

  @override
  Future<List<PendingOperation>> nextBatch({int limit = 20}) async {
    final all = await _allOrdered();
    final byId = {for (final operation in all) operation.id: operation};
    final ready = <PendingOperation>[];

    for (final operation in all) {
      if (ready.length >= limit) break;
      if (!operation.isSyncable) continue;

      final dependencyId = operation.dependsOnOperationId;
      if (dependencyId != null) {
        final dependency = byId[dependencyId];
        // Bog'liqlik topilmasa -- tozalangan deb qaraladi (aks holda
        // amal mangu kutib qolardi).
        if (dependency != null && dependency.status != PendingOperationStatus.completed) {
          continue;
        }
      }

      ready.add(operation);
    }

    return List<PendingOperation>.unmodifiable(ready);
  }

  @override
  Future<void> update(PendingOperation operation) async {
    if (!await _store.containsKey(operation.id)) return;
    await _store.put(operation.id, operation.toJson());
  }

  @override
  Future<PendingOperation?> getById(String operationId) async {
    final row = await _store.get(operationId);
    return row == null ? null : PendingOperation.fromJson(row);
  }

  @override
  Future<List<PendingOperation>> getAll() async =>
      List<PendingOperation>.unmodifiable(await _allOrdered());

  @override
  Future<List<PendingOperation>> getByStatus(PendingOperationStatus status) async {
    final all = await _allOrdered();
    return List<PendingOperation>.unmodifiable(all.where((o) => o.status == status));
  }

  @override
  Future<void> remove(String operationId) => _store.delete(operationId);

  @override
  Future<void> retryNow(String operationId) async {
    final existing = await getById(operationId);
    if (existing == null) return;
    if (existing.status != PendingOperationStatus.needsAttention) return;

    await _store.put(operationId, existing.resetForManualRetry().toJson());
  }

  @override
  Future<List<PendingOperation>> dependentsOf(String operationId) async {
    final all = await _allOrdered();
    return List<PendingOperation>.unmodifiable(
      all.where((o) => o.dependsOnOperationId == operationId),
    );
  }

  @override
  Future<int> removeCompleted() async {
    final completed = await getByStatus(PendingOperationStatus.completed);
    for (final operation in completed) {
      await _store.delete(operation.id);
    }
    return completed.length;
  }

  @override
  Future<int> pendingCount() async {
    final all = await _allOrdered();
    return all.where((o) => !o.status.isTerminal).length;
  }
}
