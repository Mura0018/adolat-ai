import 'offline_queue.dart';
import 'pending_operation.dart';

/// `OfflineQueue`ning xotiradagi POYDEVOR implementatsiyasi.
///
/// Bu klass shartnomadagi UCHALA qoidani (FIFO, bog'liqlik tartibi,
/// amal jimgina yo'qolmasligi) haqiqatan amalga oshiradi — ya'ni
/// qoidalar faqat hujjatda emas, ishlaydigan va sinaladigan kodda.
/// Doimiy (persistent) implementatsiya kelganda shu xatti-harakat
/// TAKRORLANISHI kerak; shu sababli testlar shartnoma testlari
/// sifatida yozilgan.
///
/// **Cheklov:** ma'lumot ilova yopilganda yo'qoladi —
/// `InMemoryLocalStore`dagi bilan bir xil ogohlantirish.
class InMemoryOfflineQueue implements OfflineQueue {
  /// Kalit — `PendingOperation.id`. Dart `Map`i qo'shilish tartibini
  /// saqlagani uchun FIFO tabiiy ravishda ta'minlanadi.
  final Map<String, PendingOperation> _operations = <String, PendingOperation>{};

  @override
  Future<void> enqueue(PendingOperation operation) async {
    // Mavjud kalit ustiga yozish tartibni O'ZGARTIRMAYDI (Dart Map
    // xatti-harakati) — qayta navbatga qo'yilgan amal navbat oxiriga
    // "sakramaydi", bu FIFO adolatini saqlaydi.
    _operations[operation.id] = operation;
  }

  @override
  Future<List<PendingOperation>> nextBatch({int limit = 20}) async {
    final ready = <PendingOperation>[];

    for (final operation in _operations.values) {
      if (ready.length >= limit) break;
      if (!operation.isSyncable) continue;
      if (!_isDependencySatisfied(operation)) continue;
      ready.add(operation);
    }

    return List<PendingOperation>.unmodifiable(ready);
  }

  /// Bog'liqlik qanoatlantirilganmi.
  ///
  /// Bog'langan amal TOPILMASA — qanoatlantirilgan deb hisoblanadi:
  /// u allaqachon tugab, tozalangan bo'lishi mumkin
  /// (`removeCompleted()`). Aks holda amal navbatda MANGU qolib
  /// ketardi — bu "boshi berk holat"ning aynan o'zi bo'lardi
  /// (`DEVELOPMENT_RULES.md`, 18-band).
  bool _isDependencySatisfied(PendingOperation operation) {
    final dependencyId = operation.dependsOnOperationId;
    if (dependencyId == null) return true;

    final dependency = _operations[dependencyId];
    if (dependency == null) return true;

    return dependency.status == PendingOperationStatus.completed;
  }

  @override
  Future<void> update(PendingOperation operation) async {
    if (!_operations.containsKey(operation.id)) return;
    _operations[operation.id] = operation;
  }

  @override
  Future<PendingOperation?> getById(String operationId) async => _operations[operationId];

  @override
  Future<List<PendingOperation>> getAll() async =>
      List<PendingOperation>.unmodifiable(_operations.values);

  @override
  Future<List<PendingOperation>> getByStatus(PendingOperationStatus status) async {
    return List<PendingOperation>.unmodifiable(
      _operations.values.where((operation) => operation.status == status),
    );
  }

  @override
  Future<void> remove(String operationId) async {
    _operations.remove(operationId);
  }

  @override
  Future<int> removeCompleted() async {
    final completedIds = _operations.values
        .where((operation) => operation.status == PendingOperationStatus.completed)
        .map((operation) => operation.id)
        .toList(growable: false);

    for (final id in completedIds) {
      _operations.remove(id);
    }

    return completedIds.length;
  }

  @override
  Future<int> pendingCount() async {
    return _operations.values.where((operation) => !operation.status.isTerminal).length;
  }
}
