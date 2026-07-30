import 'package:adolat_ai/features/appeals/data/models/appeal_model.dart';
import 'package:adolat_ai/features/appeals/domain/usecases/create_appeal_draft_usecase.dart';
import 'package:adolat_ai/features/appeals/domain/usecases/delete_appeal_draft_usecase.dart';
import 'package:adolat_ai/features/appeals/domain/usecases/get_appeal_usecase.dart';
import 'package:adolat_ai/features/appeals/domain/usecases/list_my_appeals_usecase.dart';
import 'package:adolat_ai/features/appeals/domain/usecases/submit_appeal_usecase.dart';
import 'package:adolat_ai/features/appeals/domain/usecases/update_appeal_draft_usecase.dart';
import 'package:adolat_ai/features/disputes/data/models/dispute_model.dart';
import 'package:adolat_ai/features/disputes/domain/usecases/create_dispute_usecase.dart';
import 'package:adolat_ai/features/disputes/domain/usecases/delete_dispute_usecase.dart';
import 'package:adolat_ai/features/disputes/domain/usecases/get_dispute_usecase.dart';
import 'package:adolat_ai/features/disputes/domain/usecases/list_my_disputes_usecase.dart';
import 'package:adolat_ai/features/disputes/domain/usecases/submit_respondent_statement_usecase.dart';
import 'package:adolat_ai/features/disputes/domain/usecases/update_dispute_as_initiator_usecase.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/recording_repositories.dart';
import '../helpers/result_matchers.dart';
import '../helpers/supabase_fixtures.dart';

/// Murojaat va nizo usecase'larining SIMLARI (wiring): har biri
/// KUTILGAN repository metodini KUTILGAN argumentlar bilan chaqiradimi.
///
/// `docs/ARCHITECTURE.md`ga ko'ra bu usecase'lar ataylab yupqa -- ular
/// biznes qoidasi saqlamaydi (qoidalar RLS'da, server tomonida).
/// Shuning uchun ular uchun yagona mazmunli test -- ulanish to'g'riligi.
void main() {
  final appeal = AppealModel.fromJson(buildAppealJson()).toEntity();
  final dispute = DisputeModel.fromJson(buildDisputeJson()).toEntity();

  group('Appeals usecases', () {
    late RecordingAppealsRepository repository;

    setUp(() => repository = RecordingAppealsRepository(appeal));

    test('CreateAppealDraftUseCase calls createDraft with every field', () async {
      final result = await CreateAppealDraftUseCase(repository)(
        categoryId: 'c1',
        recipientBodyId: 'b1',
        title: 'sarlavha',
        bodyText: 'matn',
        aiDraftText: 'ai',
      );

      expectOk(result);
      expect(repository.lastCall['method'], 'createDraft');
      expect(repository.lastCall['categoryId'], 'c1');
      expect(repository.lastCall['recipientBodyId'], 'b1');
      expect(repository.lastCall['title'], 'sarlavha');
      expect(repository.lastCall['bodyText'], 'matn');
      expect(repository.lastCall['aiDraftText'], 'ai');
    });

    test('UpdateAppealDraftUseCase calls updateDraft, not submit', () async {
      await UpdateAppealDraftUseCase(repository)(appealId: 'a1', title: 'yangi');

      expect(repository.lastCall['method'], 'updateDraft');
      expect(repository.lastCall['appealId'], 'a1');
      expect(repository.lastCall['title'], 'yangi');
      expect(repository.lastCall['bodyText'], isNull);
    });

    test('SubmitAppealUseCase calls submit', () async {
      await SubmitAppealUseCase(repository)('a1');

      expect(repository.lastCall['method'], 'submit');
      expect(repository.lastCall['appealId'], 'a1');
    });

    test('DeleteAppealDraftUseCase calls deleteDraft', () async {
      await DeleteAppealDraftUseCase(repository)('a1');

      expect(repository.lastCall['method'], 'deleteDraft');
    });

    test('GetAppealUseCase calls getById and returns the entity', () async {
      final result = await GetAppealUseCase(repository)('a1');

      expect(repository.lastCall['method'], 'getById');
      expect(expectOk(result).id, appeal.id);
    });

    test('ListMyAppealsUseCase calls listMine', () async {
      final result = await ListMyAppealsUseCase(repository)();

      expect(repository.lastCall['method'], 'listMine');
      expect(expectOk(result), hasLength(1));
    });
  });

  group('Disputes usecases', () {
    late RecordingDisputesRepository repository;

    setUp(() => repository = RecordingDisputesRepository(dispute));

    test('CreateDisputeUseCase targets the unregistered-respondent flow', () async {
      // MVP faqat ro'yxatdan o'tmagan qarshi tomonni qo'llab-quvvatlaydi
      // (docs/DATABASE.md, 6-jadval) -- usecase aynan shu metodga
      // ulanganini qulflaymiz.
      await CreateDisputeUseCase(repository)(
        categoryId: 'c1',
        title: 'nizo',
        description: 'tavsif',
        respondentDisplayName: 'Qarshi tomon',
      );

      expect(repository.lastCall['method'], 'createWithUnregisteredRespondent');
      expect(repository.lastCall['respondentDisplayName'], 'Qarshi tomon');
    });

    test('UpdateDisputeAsInitiatorUseCase calls updateAsInitiator', () async {
      await UpdateDisputeAsInitiatorUseCase(repository)(
        disputeId: 'd1',
        description: 'yangilangan',
      );

      expect(repository.lastCall['method'], 'updateAsInitiator');
      expect(repository.lastCall['description'], 'yangilangan');
      expect(repository.lastCall['title'], isNull);
    });

    test('SubmitRespondentStatementUseCase calls the respondent-only method', () async {
      // Qarshi tomon FAQAT o'z bayonotini yozishi mumkin (RLS
      // `disputes_update_respondent` siyosati) -- boshqa metodga
      // ulanish avtorizatsiya niyatini buzardi.
      await SubmitRespondentStatementUseCase(repository)(
        disputeId: 'd1',
        statement: 'bayonot',
      );

      expect(repository.lastCall['method'], 'submitRespondentStatement');
      expect(repository.lastCall['statement'], 'bayonot');
    });

    test('DeleteDisputeUseCase calls deleteAsInitiator', () async {
      await DeleteDisputeUseCase(repository)('d1');

      expect(repository.lastCall['method'], 'deleteAsInitiator');
    });

    test('GetDisputeUseCase calls getById and returns the entity', () async {
      final result = await GetDisputeUseCase(repository)('d1');

      expect(repository.lastCall['method'], 'getById');
      expect(expectOk(result).id, dispute.id);
    });

    test('ListMyDisputesUseCase calls listMine', () async {
      final result = await ListMyDisputesUseCase(repository)();

      expect(repository.lastCall['method'], 'listMine');
      expect(expectOk(result), hasLength(1));
    });
  });
}
