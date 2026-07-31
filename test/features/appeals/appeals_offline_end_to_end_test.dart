import 'dart:io';

import 'package:adolat_ai/core/network/result.dart';
import 'package:adolat_ai/core/offline/network/in_memory_network_state_monitor.dart';
import 'package:adolat_ai/core/offline/network/network_status.dart';
import 'package:adolat_ai/core/offline/queue/local_store_offline_queue.dart';
import 'package:adolat_ai/core/offline/queue/offline_queue.dart';
import 'package:adolat_ai/core/offline/queue/pending_operation.dart';
import 'package:adolat_ai/core/offline/sync/queued_sync_engine.dart';
import 'package:adolat_ai/core/offline/sync/sync_coordinator.dart';
import 'package:adolat_ai/core/offline/sync/sync_engine.dart';
import 'package:adolat_ai/core/utils/uuid_v7.dart';
import 'package:adolat_ai/features/appeals/data/models/appeal_model.dart';
import 'package:adolat_ai/features/appeals/data/repositories/offline_first_appeals_repository.dart';
import 'package:adolat_ai/features/appeals/data/sync/appeals_sync_operation_handler.dart';
import 'package:adolat_ai/features/appeals/domain/entities/appeal.dart';
import 'package:adolat_ai/features/appeals/domain/repositories/appeals_repository.dart';
import 'package:adolat_ai/core/error/failure.dart';
import 'package:adolat_ai/services/local_database/app_local_database.dart';
import 'package:adolat_ai/services/local_database/drift_local_store.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_appeals_remote_datasource.dart';
import '../../helpers/result_matchers.dart';
import '../../helpers/supabase_fixtures.dart';

/// **Module 7C uchtan-uchga (end-to-end) testi.**
///
/// Butun zanjir haqiqiy komponentlar bilan yig'iladi:
/// `OfflineFirstAppealsRepository` → Drift saqlash (7A) →
/// `LocalStoreOfflineQueue` → `QueuedSyncEngine` →
/// `AppealsSyncOperationHandler` → datasource.
///
/// Faqat eng chekka nuqta (Supabase klienti) soxta — chunki bu
/// nuqtadan narisi tarmoq va tashqi xizmat.
///
/// **Tekshiriladigan asosiy va'da (`docs/ARCHITECTURE.md`,
/// "Offline-First Architecture"):** *"foydalanuvchi tarmoqsiz
/// murojaat yaratadi, ilova yopiladi, internet qaytganda avtomatik
/// yuboriladi"* — va ADR-009 bo'yicha identifikator butun yo'l
/// davomida **o'zgarmaydi**.
class _OnlineOnlyRemote implements AppealsRepository {
  bool online = false;
  final List<Appeal> serverRecords = <Appeal>[];

  Result<T> _offline<T>() => const Result.error(Failure.network());

  @override
  Future<Result<Appeal>> createDraft({
    required String categoryId,
    required String recipientBodyId,
    required String title,
    required String bodyText,
    String? aiDraftText,
  }) async => _offline();

  @override
  Future<Result<Appeal>> updateDraft({
    required String appealId,
    String? title,
    String? bodyText,
  }) async => _offline();

  @override
  Future<Result<Appeal>> submit(String appealId) async => _offline();

  @override
  Future<Result<void>> deleteDraft(String appealId) async => _offline();

  @override
  Future<Result<Appeal>> getById(String appealId) async {
    if (!online) return _offline();
    final match = serverRecords.where((a) => a.id == appealId);
    return match.isEmpty ? _offline() : Result.ok(match.first);
  }

  @override
  Future<Result<List<Appeal>>> listMine() async {
    if (!online) return _offline();
    return Result.ok(List<Appeal>.unmodifiable(serverRecords));
  }
}

void main() {
  late AppLocalDatabase db;
  late OfflineQueue queue;
  late _OnlineOnlyRemote remote;
  late FakeAppealsRemoteDataSource datasource;
  late InMemoryNetworkStateMonitor monitor;
  late QueuedSyncEngine engine;
  late OfflineFirstAppealsRepository repository;
  late DateTime now;

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    now = DateTime.utc(2026, 7, 31, 10);
    db = AppLocalDatabase.memory();
    queue = LocalStoreOfflineQueue(DriftLocalStore(db, 'pending_operations'));
    remote = _OnlineOnlyRemote();
    datasource = FakeAppealsRemoteDataSource()
      ..modelToReturn = AppealModel.fromJson(buildAppealJson());
    monitor = InMemoryNetworkStateMonitor(initialStatus: NetworkStatus.offline);
    engine = QueuedSyncEngine(
      queue: queue,
      handlers: [AppealsSyncOperationHandler(datasource)],
      networkMonitor: monitor,
      clock: () => now,
    );
    repository = OfflineFirstAppealsRepository(
      remote: remote,
      cache: DriftLocalStore(db, 'appeals'),
      queue: queue,
      currentUserId: () => 'user-1',
      clock: () => now,
    );
  });

  tearDown(() async {
    await engine.dispose();
    await monitor.dispose();
    await db.close();
  });

  group('to\'liq oqim: oflaynda yaratish → qayta ochish → yuborish', () {
    test('foydalanuvchi ishi yo\'qolmaydi va bir xil id bilan yuboriladi', () async {
      // 1. Tarmoq yo'q. Foydalanuvchi murojaat yaratadi.
      final created = expectOk(
        await repository.createDraft(
          categoryId: 'cat-1',
          recipientBodyId: 'body-1',
          title: 'Ishdan asossiz bo\'shatildim',
          bodyText: 'Batafsil tushuntirish',
        ),
      );
      expect(UuidV7.isValid(created.id), isTrue);
      expect(datasource.calls, isEmpty, reason: 'oflaynda serverga chiqilmaydi');

      // 2. Ilova yopildi va qayta ochildi -- yangi obyektlar, bir xil baza.
      final reopenedQueue = LocalStoreOfflineQueue(
        DriftLocalStore(db, 'pending_operations'),
      );
      expect((await reopenedQueue.getAll()).map((o) => o.entityId), [created.id]);

      // 3. Internet qaytdi.
      monitor.goOnline();
      await engine.sync(trigger: SyncTrigger.connectivityRestored);

      // 4. Server AYNAN shu identifikatorni oldi (ADR-009).
      expect(datasource.callOf('createDraft')['id'], created.id);
      expect(datasource.callOf('createDraft')['title'], 'Ishdan asossiz bo\'shatildim');
      expect(
        (await reopenedQueue.getById((await queue.getAll()).first.id))!.status,
        PendingOperationStatus.completed,
      );
    });

    test('oflaynda yaratilgan murojaat ro\'yxatda ko\'rinadi', () async {
      final created = await repository.createDraft(
        categoryId: 'cat-1',
        recipientBodyId: 'body-1',
        title: 'Oflayn murojaat',
        bodyText: 'matn',
      );
      final id = expectOk(created).id;

      final list = expectOk(await repository.listMine());

      expect(list.map((a) => a.id), [id]);
      expect(list.single.title, 'Oflayn murojaat');
    });

    test('oflaynda yaratilgan murojaatni ochib ko\'rish mumkin', () async {
      final id = expectOk(
        await repository.createDraft(
          categoryId: 'cat-1',
          recipientBodyId: 'body-1',
          title: 'Ko\'rish uchun',
          bodyText: 'matn',
        ),
      ).id;

      final fetched = expectOk(await repository.getById(id));

      expect(fetched.title, 'Ko\'rish uchun');
    });
  });

  group('koordinator bilan avtomatik yuborish', () {
    test('tarmoq qaytishi navbatni o\'zi yuboradi', () async {
      final coordinator = SyncCoordinator(
        engine: engine,
        queue: queue,
        networkMonitor: monitor,
      );
      coordinator.start();

      await repository.createDraft(
        categoryId: 'cat-1',
        recipientBodyId: 'body-1',
        title: 'Avtomatik',
        bodyText: 'matn',
      );
      await settle();
      expect(datasource.calls, isEmpty);

      // Hech kim tugma bosmaydi.
      monitor.goOnline();
      await settle();
      await settle();

      expect(datasource.wasCalled('createDraft'), isTrue);
      await coordinator.dispose();
    });
  });

  group('tahrirlash va yuborish oqimi', () {
    test('oflayn tahrirlar birlashadi va bittasi yuboriladi', () async {
      final id = expectOk(
        await repository.createDraft(
          categoryId: 'cat-1',
          recipientBodyId: 'body-1',
          title: 'v1',
          bodyText: 'matn',
        ),
      ).id;

      await repository.updateDraft(appealId: id, title: 'v2');
      await repository.updateDraft(appealId: id, title: 'v3');

      monitor.goOnline();
      await engine.sync(trigger: SyncTrigger.appStart); // createRecord
      now = now.add(const Duration(minutes: 1));
      await engine.sync(trigger: SyncTrigger.appStart); // updateRecord

      expect(datasource.callOf('updateDraft')['title'], 'v3');
      final updateCalls = datasource.calls.where((c) => c['method'] == 'updateDraft');
      expect(updateCalls, hasLength(1), reason: 'uchta tahrir bittaga birlashadi');
    });

    test('submit oflaynda holatni o\'zgartiradi, keyin yuboriladi', () async {
      final id = expectOk(
        await repository.createDraft(
          categoryId: 'cat-1',
          recipientBodyId: 'body-1',
          title: 'Yuboriladi',
          bodyText: 'matn',
        ),
      ).id;

      final submitted = expectOk(await repository.submit(id));
      expect(submitted.status.name, 'submitted');

      monitor.goOnline();
      await engine.sync(trigger: SyncTrigger.appStart);
      now = now.add(const Duration(minutes: 1));
      await engine.sync(trigger: SyncTrigger.appStart);

      expect(datasource.wasCalled('submit'), isTrue);
    });
  });

  group('xatolikni tasniflash', () {
    test('RLS rad etishi doimiy xatolik sifatida qaraladi', () async {
      await repository.createDraft(
        categoryId: 'cat-1',
        recipientBodyId: 'body-1',
        title: 'Rad etiladi',
        bodyText: 'matn',
      );
      datasource.throwOnAnyCall = buildRlsDeniedException();
      monitor.goOnline();

      await engine.sync(trigger: SyncTrigger.appStart);

      // Qayta urinish ma'nosiz -- foydalanuvchiga ko'rsatiladi.
      final operation = (await queue.getAll()).single;
      expect(operation.status, PendingOperationStatus.needsAttention);
    });

    test('tarmoq xatoligi vaqtinchalik sifatida qaraladi', () async {
      await repository.createDraft(
        categoryId: 'cat-1',
        recipientBodyId: 'body-1',
        title: 'Qayta uriniladi',
        bodyText: 'matn',
      );
      datasource.throwOnAnyCall = const SocketException('tarmoq uzildi');
      monitor.goOnline();

      await engine.sync(trigger: SyncTrigger.appStart);

      final operation = (await queue.getAll()).single;
      expect(operation.status, PendingOperationStatus.failed);
      expect(operation.isSyncable, isTrue, reason: 'navbatda qoladi');
    });
  });
}
