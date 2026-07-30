import 'dart:io';

import 'package:adolat_ai/core/error/failure.dart';
import 'package:adolat_ai/features/appeals/data/models/appeal_model.dart';
import 'package:adolat_ai/features/appeals/data/repositories/appeals_repository_impl.dart';
import 'package:adolat_ai/features/appeals/domain/entities/appeal_status.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_appeals_remote_datasource.dart';
import '../../../../helpers/result_matchers.dart';
import '../../../../helpers/supabase_fixtures.dart';

/// `AppealsRepositoryImpl` -- murojaat oqimining `Exception → Failure`
/// chegarasi. Ayniqsa muhim: RLS rad etishi (masalan qoralama bo'lmagan
/// murojaatni tahrirlashga urinish) ANIQ `PermissionDeniedFailure`
/// bo'lib qaytishi kerak, aks holda foydalanuvchi nima uchun amal
/// bajarilmaganini bilmaydi (`DEVELOPMENT_RULES.md`, 17-band).
void main() {
  late FakeAppealsRemoteDataSource remote;
  late AppealsRepositoryImpl repository;

  setUp(() {
    remote = FakeAppealsRemoteDataSource();
    repository = AppealsRepositoryImpl(remote);
    remote.modelToReturn = AppealModel.fromJson(buildAppealJson());
  });

  group('createDraft', () {
    test('returns the mapped Appeal entity', () async {
      final appeal = expectOk(
        await repository.createDraft(
          categoryId: 'category-1',
          recipientBodyId: 'body-1',
          title: 'Sinov murojaati',
          bodyText: 'Murojaat matni',
        ),
      );

      expect(appeal.id, 'appeal-1');
      expect(appeal.status, AppealStatus.draft);
      expect(appeal.title, 'Sinov murojaati');
    });

    test('forwards every field to the datasource', () async {
      await repository.createDraft(
        categoryId: 'c1',
        recipientBodyId: 'b1',
        title: 'sarlavha',
        bodyText: 'matn',
        aiDraftText: 'ai qoralama',
      );

      final call = remote.callOf('createDraft');
      expect(call['categoryId'], 'c1');
      expect(call['recipientBodyId'], 'b1');
      expect(call['aiDraftText'], 'ai qoralama');
    });

    test('maps an offline error to NetworkFailure', () async {
      remote.throwOnAnyCall = const SocketException('tarmoq yo\'q');

      final result = await repository.createDraft(
        categoryId: 'c',
        recipientBodyId: 'b',
        title: 't',
        bodyText: 'm',
      );

      expectFailureOfType<dynamic, NetworkFailure>(result);
    });
  });

  group('updateDraft', () {
    test('maps an RLS denial to PermissionDeniedFailure', () async {
      // Qoralama bo'lmagan murojaatni tahrirlashga urinish -- RLS server
      // tomonida rad etadi.
      remote.throwOnAnyCall = buildRlsDeniedException();

      final result = await repository.updateDraft(appealId: 'appeal-1', title: 'yangi');

      expectFailureOfType<dynamic, PermissionDeniedFailure>(result);
    });

    test('passes null fields through untouched (partial update)', () async {
      await repository.updateDraft(appealId: 'appeal-1', title: 'faqat sarlavha');

      final call = remote.callOf('updateDraft');
      expect(call['title'], 'faqat sarlavha');
      expect(call['bodyText'], isNull);
    });
  });

  group('submit', () {
    test('returns the submitted appeal with its new status', () async {
      remote.modelToReturn = AppealModel.fromJson(
        buildAppealJson(status: 'submitted', submittedAt: '2026-01-03T00:00:00.000Z'),
      );

      final appeal = expectOk(await repository.submit('appeal-1'));

      expect(appeal.status, AppealStatus.submitted);
      expect(appeal.submittedAt, isNotNull);
    });

    test('surfaces an RLS denial rather than pretending success', () async {
      remote.throwOnAnyCall = buildRlsDeniedException();

      expectFailureOfType<dynamic, PermissionDeniedFailure>(
        await repository.submit('appeal-1'),
      );
    });
  });

  group('listMine', () {
    test('maps every row to an entity', () async {
      remote.listToReturn = [
        AppealModel.fromJson(buildAppealJson(id: 'a1')),
        AppealModel.fromJson(buildAppealJson(id: 'a2', status: 'answered')),
      ];

      final appeals = expectOk(await repository.listMine());

      expect(appeals.map((a) => a.id), ['a1', 'a2']);
      expect(appeals.last.status, AppealStatus.answered);
    });

    test('an empty list is a success, not an error', () async {
      remote.listToReturn = const [];

      expect(expectOk(await repository.listMine()), isEmpty);
    });
  });

  group('deleteDraft', () {
    test('reaches the datasource with the right id', () async {
      expectOk(await repository.deleteDraft('appeal-9'));

      expect(remote.callOf('deleteDraft')['appealId'], 'appeal-9');
    });

    test('maps a failure instead of throwing', () async {
      remote.throwOnAnyCall = buildPostgrestException();

      expectFailureOfType<dynamic, ServerFailure>(await repository.deleteDraft('appeal-1'));
    });
  });

  group('every repository method converts exceptions', () {
    test('no method ever lets a raw exception escape', () async {
      remote.throwOnAnyCall = StateError('kutilmagan ichki xato');

      // docs/ARCHITECTURE.md: domain/presentation hech qachon xom
      // exception ko'rmasligi shart -- bu invariantni HAR BIR metod
      // uchun bir joyda tekshiramiz.
      expectFailure(
        await repository.createDraft(
          categoryId: 'c',
          recipientBodyId: 'b',
          title: 't',
          bodyText: 'm',
        ),
      );
      expectFailure(await repository.updateDraft(appealId: 'a'));
      expectFailure(await repository.submit('a'));
      expectFailure(await repository.deleteDraft('a'));
      expectFailure(await repository.getById('a'));
      expectFailure(await repository.listMine());
    });
  });
}
