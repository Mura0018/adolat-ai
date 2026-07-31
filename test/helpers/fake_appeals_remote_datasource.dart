import 'package:adolat_ai/features/appeals/data/datasources/appeals_remote_datasource.dart';
import 'package:adolat_ai/features/appeals/data/models/appeal_model.dart';

/// `AppealsRemoteDataSource`ning boshqariladigan o'rnini bosuvchisi --
/// `FakeAuthRemoteDataSource` bilan bir xil naqsh (qo'lda yozilgan fake,
/// mock kutubxonasiz).
class FakeAppealsRemoteDataSource implements AppealsRemoteDataSource {
  AppealModel? modelToReturn;
  List<AppealModel> listToReturn = const [];

  /// Belgilansa, HAR BIR metod shu xatolikni tashlaydi.
  Object? throwOnAnyCall;

  final List<Map<String, Object?>> calls = <Map<String, Object?>>[];

  void _record(String method, [Map<String, Object?> args = const {}]) {
    calls.add(<String, Object?>{'method': method, ...args});
  }

  Map<String, Object?> callOf(String method) =>
      calls.firstWhere((c) => c['method'] == method);

  bool wasCalled(String method) => calls.any((c) => c['method'] == method);

  AppealModel get _model =>
      modelToReturn ?? (throw StateError('Test `modelToReturn`ni belgilamagan'));

  @override
  Future<AppealModel> createDraft({
    required String categoryId,
    required String recipientBodyId,
    required String title,
    required String bodyText,
    String? aiDraftText,
    String? id,
  }) async {
    _record('createDraft', {
      'categoryId': categoryId,
      'recipientBodyId': recipientBodyId,
      'title': title,
      'bodyText': bodyText,
      'aiDraftText': aiDraftText,
      // ADR-009: klient bergan identifikator (berilmasa null).
      'id': id,
    });
    if (throwOnAnyCall != null) throw throwOnAnyCall!;
    return _model;
  }

  @override
  Future<AppealModel> updateDraft({
    required String appealId,
    String? title,
    String? bodyText,
  }) async {
    _record('updateDraft', {'appealId': appealId, 'title': title, 'bodyText': bodyText});
    if (throwOnAnyCall != null) throw throwOnAnyCall!;
    return _model;
  }

  @override
  Future<AppealModel> submit(String appealId) async {
    _record('submit', {'appealId': appealId});
    if (throwOnAnyCall != null) throw throwOnAnyCall!;
    return _model;
  }

  @override
  Future<void> deleteDraft(String appealId) async {
    _record('deleteDraft', {'appealId': appealId});
    if (throwOnAnyCall != null) throw throwOnAnyCall!;
  }

  @override
  Future<AppealModel> getById(String appealId) async {
    _record('getById', {'appealId': appealId});
    if (throwOnAnyCall != null) throw throwOnAnyCall!;
    return _model;
  }

  @override
  Future<List<AppealModel>> listMine() async {
    _record('listMine');
    if (throwOnAnyCall != null) throw throwOnAnyCall!;
    return listToReturn;
  }
}
