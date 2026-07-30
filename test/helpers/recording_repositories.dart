import 'package:adolat_ai/core/network/result.dart';
import 'package:adolat_ai/features/appeals/domain/entities/appeal.dart';
import 'package:adolat_ai/features/appeals/domain/repositories/appeals_repository.dart';
import 'package:adolat_ai/features/disputes/domain/entities/dispute.dart';
import 'package:adolat_ai/features/disputes/domain/repositories/disputes_repository.dart';

/// UseCase qatlamini tekshirish uchun "yozib boruvchi" (recording)
/// repository'lar.
///
/// **Nega bu testlar arziydi, garchi usecase'lar sof delegatsiya
/// bo'lsa ham:** usecase'ning YAGONA vazifasi -- to'g'ri repository
/// metodini to'g'ri argumentlar bilan chaqirish. Noto'g'ri metodga
/// ulanish (masalan `submit` o'rniga `updateDraft`) kompilyatsiyada
/// TUTILMAYDI, chunki imzolar mos kelishi mumkin -- bu aynan jimgina
/// yuzaga keladigan xato turi. Shu sababli bu yerdagi tasdiqlash
/// "qaysi metod chaqirildi va qanday argument bilan" ustida.
class RecordingAppealsRepository implements AppealsRepository {
  RecordingAppealsRepository(this._appeal);

  final Appeal _appeal;
  final List<Map<String, Object?>> calls = <Map<String, Object?>>[];

  Map<String, Object?> get lastCall => calls.last;

  void _record(String method, [Map<String, Object?> args = const {}]) {
    calls.add(<String, Object?>{'method': method, ...args});
  }

  @override
  Future<Result<Appeal>> createDraft({
    required String categoryId,
    required String recipientBodyId,
    required String title,
    required String bodyText,
    String? aiDraftText,
  }) async {
    _record('createDraft', {
      'categoryId': categoryId,
      'recipientBodyId': recipientBodyId,
      'title': title,
      'bodyText': bodyText,
      'aiDraftText': aiDraftText,
    });
    return Result.ok(_appeal);
  }

  @override
  Future<Result<Appeal>> updateDraft({
    required String appealId,
    String? title,
    String? bodyText,
  }) async {
    _record('updateDraft', {'appealId': appealId, 'title': title, 'bodyText': bodyText});
    return Result.ok(_appeal);
  }

  @override
  Future<Result<Appeal>> submit(String appealId) async {
    _record('submit', {'appealId': appealId});
    return Result.ok(_appeal);
  }

  @override
  Future<Result<void>> deleteDraft(String appealId) async {
    _record('deleteDraft', {'appealId': appealId});
    return const Result.ok(null);
  }

  @override
  Future<Result<Appeal>> getById(String appealId) async {
    _record('getById', {'appealId': appealId});
    return Result.ok(_appeal);
  }

  @override
  Future<Result<List<Appeal>>> listMine() async {
    _record('listMine');
    return Result.ok([_appeal]);
  }
}

class RecordingDisputesRepository implements DisputesRepository {
  RecordingDisputesRepository(this._dispute);

  final Dispute _dispute;
  final List<Map<String, Object?>> calls = <Map<String, Object?>>[];

  Map<String, Object?> get lastCall => calls.last;

  void _record(String method, [Map<String, Object?> args = const {}]) {
    calls.add(<String, Object?>{'method': method, ...args});
  }

  @override
  Future<Result<Dispute>> createWithUnregisteredRespondent({
    required String categoryId,
    required String title,
    required String description,
    required String respondentDisplayName,
  }) async {
    _record('createWithUnregisteredRespondent', {
      'categoryId': categoryId,
      'title': title,
      'description': description,
      'respondentDisplayName': respondentDisplayName,
    });
    return Result.ok(_dispute);
  }

  @override
  Future<Result<Dispute>> updateAsInitiator({
    required String disputeId,
    String? title,
    String? description,
  }) async {
    _record('updateAsInitiator', {
      'disputeId': disputeId,
      'title': title,
      'description': description,
    });
    return Result.ok(_dispute);
  }

  @override
  Future<Result<Dispute>> submitRespondentStatement({
    required String disputeId,
    required String statement,
  }) async {
    _record('submitRespondentStatement', {'disputeId': disputeId, 'statement': statement});
    return Result.ok(_dispute);
  }

  @override
  Future<Result<void>> deleteAsInitiator(String disputeId) async {
    _record('deleteAsInitiator', {'disputeId': disputeId});
    return const Result.ok(null);
  }

  @override
  Future<Result<Dispute>> getById(String disputeId) async {
    _record('getById', {'disputeId': disputeId});
    return Result.ok(_dispute);
  }

  @override
  Future<Result<List<Dispute>>> listMine() async {
    _record('listMine');
    return Result.ok([_dispute]);
  }
}
