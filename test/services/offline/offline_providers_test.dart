import 'package:adolat_ai/core/offline/queue/local_store_offline_queue.dart';
import 'package:adolat_ai/core/offline/queue/pending_operation.dart';
import 'package:adolat_ai/core/offline/sync/sync_coordinator.dart';
import 'package:adolat_ai/core/offline/sync/sync_engine.dart';
import 'package:adolat_ai/core/offline/sync/sync_operation_outcome.dart';
import 'package:adolat_ai/features/appeals/data/repositories/offline_first_appeals_repository.dart';
import 'package:adolat_ai/features/appeals/domain/repositories/appeals_repository.dart';
import 'package:adolat_ai/features/appeals/presentation/providers/appeals_providers.dart';
import 'package:adolat_ai/services/local_database/app_local_database.dart';
import 'package:adolat_ai/services/offline/offline_providers.dart';
import 'package:adolat_ai/services/supabase/supabase_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/result_matchers.dart';

/// **DI kompozitsiyasi testlari (Module 7D).**
///
/// Nima uchun bular muhim: 7D ilova xatti-harakatini o'zgartiradi —
/// `appealsRepositoryProvider` endi offline-first implementatsiyani
/// quradi. `appeals` ekranlari testsiz bo'lgani uchun (o'z auditimda
/// qayd etilgan bo'shliq), ulanishning O'ZI hech bo'lmaganda shu
/// yerda qulflanadi: kompozitsiya quriladimi, to'g'ri turlar
/// yig'iladimi, va offline yozish yo'li haqiqatan navbatga tushadimi.
///
/// Widget testlari o'rnini bosmaydi, lekin "provayder noto'g'ri
/// ulangan" turidagi eng ehtimolli regressiyani ushlaydi.
class _NoopHandler implements SyncOperationHandler {
  final List<String> performed = <String>[];

  @override
  bool canHandle(PendingOperation operation) => true;

  @override
  Future<SyncOperationOutcome> perform(PendingOperation operation) async {
    performed.add(operation.id);
    return const SyncSuccess();
  }
}

void main() {
  late AppLocalDatabase db;
  late ProviderContainer container;
  late _NoopHandler handler;

  ProviderContainer buildContainer({List<Override> extra = const []}) {
    return ProviderContainer(
      overrides: [
        appLocalDatabaseProvider.overrideWithValue(db),
        featureSyncHandlersProvider.overrideWithValue([handler]),
        // Supabase testda ishga tushirilmagan -- foydalanuvchi
        // identifikatori override orqali beriladi.
        currentUserIdProvider.overrideWithValue(() => 'user-1'),
        ...extra,
      ],
    );
  }

  setUp(() {
    db = AppLocalDatabase.memory();
    handler = _NoopHandler();
    container = buildContainer();
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('kompozitsiya quriladi', () {
    test('navbat Drift saqlash ustida quriladi', () {
      final queue = container.read(offlineQueueProvider);

      expect(queue, isA<LocalStoreOfflineQueue>());
    });

    test('dvigatel va koordinator quriladi', () {
      expect(container.read(syncEngineProvider), isA<SyncEngine>());
      expect(container.read(syncCoordinatorProvider), isA<SyncCoordinator>());
    });

    test('to\'plamlar alohida nom bilan ajratiladi', () async {
      await container.read(pendingOperationsStoreProvider).put('a', const {'v': 1});
      await container.read(appealsCacheStoreProvider).put('a', const {'v': 2});

      expect(await container.read(pendingOperationsStoreProvider).get('a'), {'v': 1});
      expect(await container.read(appealsCacheStoreProvider).get('a'), {'v': 2});
    });

    test('baza override qilinmasa aniq xabar bilan yiqiladi', () {
      final bare = ProviderContainer();

      expect(
        () => bare.read(offlineQueueProvider),
        throwsA(isA<UnimplementedError>()),
      );
      bare.dispose();
    });
  });

  group('feature handlerlari ulanadi', () {
    test('handler tarmoq monitoriga xabar beruvchi dekorator bilan o\'raladi', () {
      final handlers = container.read(syncOperationHandlersProvider);

      expect(handlers, hasLength(1));
      // O'ram (wrapper) ichkarini yashiradi, lekin shartnomani saqlaydi.
      expect(handlers.single, isA<SyncOperationHandler>());
      expect(handlers.single, isNot(same(handler)));
    });

    test('handler ro\'yxati bo\'sh bo\'lsa ham kompozitsiya buzilmaydi', () {
      final empty = ProviderContainer(
        overrides: [appLocalDatabaseProvider.overrideWithValue(db)],
      );

      expect(empty.read(syncOperationHandlersProvider), isEmpty);
      empty.dispose();
    });
  });

  group('appeals repozitoriysi offline-first ga ulangan', () {
    test('appealsRepositoryProvider offline-first implementatsiyani quradi', () {
      final repository = container.read(appealsRepositoryProvider);

      expect(repository, isA<OfflineFirstAppealsRepository>());
      // Shartnoma o'zgarmagan.
      expect(repository, isA<AppealsRepository>());
    });

    test('usecase\'lar xuddi shu repozitoriyni oladi', () {
      // Usecase'lar o'zgarmagan -- ular repozitoriyni provayder
      // orqali oladi, ya'ni offline-first avtomatik amal qiladi.
      final repository = container.read(appealsRepositoryProvider);
      final another = container.read(appealsRepositoryProvider);

      expect(identical(repository, another), isTrue);
    });
  });

  group('yozish yo\'li haqiqatan navbatga tushadi', () {
    test('offline yaratilgan murojaat navbatga va keshga yoziladi', () async {
      final repository = container.read(appealsRepositoryProvider);

      await repository.createDraft(
        categoryId: 'cat-1',
        recipientBodyId: 'body-1',
        title: 'DI orqali yaratilgan',
        bodyText: 'matn',
      );

      final queue = container.read(offlineQueueProvider);
      final operations = await queue.getAll();
      expect(operations, hasLength(1));
      expect(operations.single.kind, PendingOperationKind.createRecord);
      expect(operations.single.entityType, 'appeal');

      // Kesh ham to'ldirilgan.
      final cached = await container.read(appealsCacheStoreProvider).getAll();
      expect(cached, hasLength(1));
    });

    test('yaratilgan yozuv bir xil bazada saqlanadi (qayta ochish)', () async {
      final repository = container.read(appealsRepositoryProvider);
      await repository.createDraft(
        categoryId: 'cat-1',
        recipientBodyId: 'body-1',
        title: 'Saqlanadi',
        bodyText: 'matn',
      );

      // "Ilova qayta ochildi" -- yangi konteyner, bir xil baza.
      final reopened = buildContainer();
      final queue = reopened.read(offlineQueueProvider);

      expect(await queue.getAll(), hasLength(1));
      reopened.dispose();
    });
  });

  group('foydalanuvchi tizimga kirmagan holat', () {
    test('createDraft xatolik qaytaradi, navbat bo\'sh qoladi', () async {
      final anonymous = buildContainer(
        extra: [currentUserIdProvider.overrideWithValue(() => null)],
      );
      addTearDown(anonymous.dispose);
      final repository = anonymous.read(appealsRepositoryProvider);

      final result = await repository.createDraft(
        categoryId: 'cat-1',
        recipientBodyId: 'body-1',
        title: 'Sessiyasiz',
        bodyText: 'matn',
      );

      expectFailure(result);
      expect(await anonymous.read(offlineQueueProvider).getAll(), isEmpty);
    });
  });
}
