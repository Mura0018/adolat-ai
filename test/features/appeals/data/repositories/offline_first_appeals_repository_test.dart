import 'package:adolat_ai/core/error/failure.dart';
import 'package:adolat_ai/core/network/result.dart';
import 'package:adolat_ai/core/offline/queue/in_memory_offline_queue.dart';
import 'package:adolat_ai/core/offline/queue/pending_operation.dart';
import 'package:adolat_ai/core/offline/storage/in_memory_local_store.dart';
import 'package:adolat_ai/core/utils/uuid_v7.dart';
import 'package:adolat_ai/features/appeals/data/models/appeal_model.dart';
import 'package:adolat_ai/features/appeals/data/repositories/offline_first_appeals_repository.dart';
import 'package:adolat_ai/features/appeals/domain/entities/appeal.dart';
import 'package:adolat_ai/features/appeals/domain/entities/appeal_status.dart';
import 'package:adolat_ai/features/appeals/domain/repositories/appeals_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/result_matchers.dart';
import '../../../../helpers/supabase_fixtures.dart';

/// Boshqariladigan "server" repository — dekorator uni o'raydi.
class _FakeRemote implements AppealsRepository {
  Result<Appeal>? getByIdResult;
  Result<List<Appeal>>? listMineResult;
  final List<String> calls = <String>[];

  @override
  Future<Result<Appeal>> createDraft({
    required String categoryId,
    required String recipientBodyId,
    required String title,
    required String bodyText,
    String? aiDraftText,
  }) async {
    calls.add('createDraft');
    return const Result.error(Failure.unknown(message: 'chaqirilmasligi kerak'));
  }

  @override
  Future<Result<Appeal>> updateDraft({
    required String appealId,
    String? title,
    String? bodyText,
  }) async {
    calls.add('updateDraft');
    return const Result.error(Failure.unknown(message: 'chaqirilmasligi kerak'));
  }

  @override
  Future<Result<Appeal>> submit(String appealId) async {
    calls.add('submit');
    return const Result.error(Failure.unknown(message: 'chaqirilmasligi kerak'));
  }

  @override
  Future<Result<void>> deleteDraft(String appealId) async {
    calls.add('deleteDraft');
    return const Result.error(Failure.unknown(message: 'chaqirilmasligi kerak'));
  }

  @override
  Future<Result<Appeal>> getById(String appealId) async {
    calls.add('getById');
    return getByIdResult ?? const Result.error(Failure.network());
  }

  @override
  Future<Result<List<Appeal>>> listMine() async {
    calls.add('listMine');
    return listMineResult ?? const Result.error(Failure.network());
  }
}

Appeal _appeal({String id = 'server-1', String title = 'Server murojaati'}) {
  return AppealModel.fromJson(buildAppealJson(id: id, title: title)).toEntity();
}

void main() {
  late _FakeRemote remote;
  late InMemoryLocalStore<Map<String, Object?>> cache;
  late InMemoryOfflineQueue queue;
  late OfflineFirstAppealsRepository repository;

  setUp(() {
    remote = _FakeRemote();
    cache = InMemoryLocalStore<Map<String, Object?>>();
    queue = InMemoryOfflineQueue();
    repository = OfflineFirstAppealsRepository(
      remote: remote,
      cache: cache,
      queue: queue,
      currentUserId: () => 'user-1',
      clock: () => DateTime.utc(2026, 7, 31, 10),
    );
  });

  Future<Appeal> createOne({String title = 'Ishdan bo\'shatildim'}) async {
    return expectOk(
      await repository.createDraft(
        categoryId: 'cat-1',
        recipientBodyId: 'body-1',
        title: title,
        bodyText: 'Batafsil matn',
      ),
    );
  }

  group('createDraft — ADR-009 ning asosiy va\'dasi', () {
    test('tarmoqsiz ham to\'liq Appeal qaytaradi', () async {
      final appeal = await createOne();

      expect(appeal.id, isNotEmpty);
      expect(appeal.authorId, 'user-1');
      expect(appeal.status, AppealStatus.draft);
      expect(appeal.title, 'Ishdan bo\'shatildim');
      expect(appeal.createdAt, DateTime.utc(2026, 7, 31, 10));
    });

    test('identifikator KLIENT tomonda yaratilgan haqiqiy UUID v7', () async {
      final appeal = await createOne();

      expect(UuidV7.isValid(appeal.id), isTrue, reason: appeal.id);
      expect(appeal.id[14], '7', reason: 'versiya raqami 7 bo\'lishi kerak');
    });

    test('serverga UMUMAN murojaat qilinmaydi', () async {
      await createOne();

      // Yozish yo'li tarmoqqa bog'liq emas -- amal navbatga tushadi.
      expect(remote.calls, isEmpty);
    });

    test('mahalliy nusxaga saqlanadi', () async {
      final appeal = await createOne();

      final cached = await cache.get(appeal.id);
      expect(cached, isNotNull);
      expect(AppealModel.fromJson(cached!).title, 'Ishdan bo\'shatildim');
    });

    test('navbatga createRecord amali qo\'yiladi', () async {
      final appeal = await createOne();

      final operation = (await queue.getAll()).single;
      expect(operation.kind, PendingOperationKind.createRecord);
      expect(operation.entityType, 'appeal');
      expect(operation.entityId, appeal.id);
      expect(operation.payload['title'], 'Ishdan bo\'shatildim');
      expect(operation.payload['categoryId'], 'cat-1');
    });

    test('foydalanuvchi tizimga kirmagan bo\'lsa rad etadi', () async {
      final anonymous = OfflineFirstAppealsRepository(
        remote: remote,
        cache: cache,
        queue: queue,
        currentUserId: () => null,
      );

      final result = await anonymous.createDraft(
        categoryId: 'c',
        recipientBodyId: 'b',
        title: 't',
        bodyText: 'm',
      );

      expectFailureOfType<dynamic, PermissionDeniedFailure>(result);
      expect(await queue.getAll(), isEmpty);
    });
  });

  group('updateDraft', () {
    test('mahalliy nusxani yangilaydi va navbatga qo\'yadi', () async {
      final appeal = await createOne();

      final updated = expectOk(
        await repository.updateDraft(appealId: appeal.id, title: 'Yangi sarlavha'),
      );

      expect(updated.title, 'Yangi sarlavha');
      expect(updated.bodyText, 'Batafsil matn', reason: 'berilmagan maydon saqlanadi');
      final kinds = (await queue.getAll()).map((o) => o.kind);
      expect(kinds, contains(PendingOperationKind.updateRecord));
    });

    test('ketma-ket tahrirlar navbatda BITTAGA birlashadi', () async {
      final appeal = await createOne();

      await repository.updateDraft(appealId: appeal.id, title: 'birinchi');
      await repository.updateDraft(appealId: appeal.id, title: 'ikkinchi');
      await repository.updateDraft(appealId: appeal.id, title: 'uchinchi');

      final updates = (await queue.getAll())
          .where((o) => o.kind == PendingOperationKind.updateRecord)
          .toList();
      expect(updates, hasLength(1), reason: 'Module 6C supersede qoidasi');
      expect(updates.single.payload['title'], 'uchinchi');
    });

    test('noma\'lum yozuv uchun xatolik qaytaradi', () async {
      expectFailure(await repository.updateDraft(appealId: 'yo\'q', title: 'x'));
    });
  });

  group('submit', () {
    test('holatni submitted ga o\'tkazadi va navbatga qo\'yadi', () async {
      final appeal = await createOne();

      final submitted = expectOk(await repository.submit(appeal.id));

      expect(submitted.status, AppealStatus.submitted);
      expect(submitted.submittedAt, isNotNull);
      expect(
        (await queue.getAll()).map((o) => o.kind),
        contains(PendingOperationKind.submitRecord),
      );
    });
  });

  group('deleteDraft', () {
    test('mahalliy nusxadan o\'chiradi va navbatga qo\'yadi', () async {
      final appeal = await createOne();

      expectOk(await repository.deleteDraft(appeal.id));

      expect(await cache.get(appeal.id), isNull);
      expect(
        (await queue.getAll()).map((o) => o.kind),
        contains(PendingOperationKind.deleteRecord),
      );
    });
  });

  group('getById — server birinchi, kesh zaxira', () {
    test('server javob bersa uni qaytaradi va keshlaydi', () async {
      remote.getByIdResult = Result.ok(_appeal(id: 'server-1'));

      final appeal = expectOk(await repository.getById('server-1'));

      expect(appeal.id, 'server-1');
      expect(await cache.get('server-1'), isNotNull);
    });

    test('server yetib bo\'lmasa mahalliy nusxadan beradi', () async {
      final created = await createOne(title: 'Oflayn murojaat');
      remote.getByIdResult = const Result.error(Failure.network());

      final appeal = expectOk(await repository.getById(created.id));

      expect(appeal.title, 'Oflayn murojaat');
    });

    test('na serverda, na keshda bo\'lsa xatolik qaytadi', () async {
      remote.getByIdResult = const Result.error(Failure.network());

      expectFailure(await repository.getById('nomavjud'));
    });
  });

  group('listMine — yuborilmagan yozuvlar yo\'qolmaydi', () {
    test('server ro\'yxatiga navbatdagi mahalliy yozuv qo\'shiladi', () async {
      final local = await createOne(title: 'Hali yuborilmagan');
      remote.listMineResult = Result.ok([_appeal(id: 'server-1')]);

      final list = expectOk(await repository.listMine());

      // Foydalanuvchi oflaynda yaratgan murojaati ro'yxatdan
      // "yo'qolgandek" ko'rinmasligi kerak.
      expect(list.map((a) => a.id), containsAll(['server-1', local.id]));
    });

    test('tarmoq yo\'q bo\'lsa mahalliy nusxa qaytariladi', () async {
      await createOne(title: 'Oflayn');
      remote.listMineResult = const Result.error(Failure.network());

      final list = expectOk(await repository.listMine());

      expect(list, hasLength(1));
      expect(list.single.title, 'Oflayn');
    });

    test('kesh bo\'sh va tarmoq yo\'q bo\'lsa xatolik qaytadi', () async {
      remote.listMineResult = const Result.error(Failure.network());

      expectFailure(await repository.listMine());
    });
  });

  group('shartnoma saqlanganini tasdiqlash', () {
    test('AppealsRepository interfeysining o\'zi amalga oshirilgan', () {
      expect(repository, isA<AppealsRepository>());
    });
  });
}
