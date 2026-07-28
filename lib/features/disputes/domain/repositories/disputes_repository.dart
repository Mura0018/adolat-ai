import '../../../../core/network/result.dart';
import '../entities/dispute.dart';

/// `public.disputes` ustidagi biznes amallar uchun abstrakt shartnoma
/// (docs/DATABASE.md, 6-jadval; docs/ARCHITECTURE.md, "Case Lifecycle"
/// bo'limi).
///
/// MVP ko'lami: faqat ro'yxatdan o'tmagan (`unregistered`) qarshi tomon
/// bilan nizo yaratish qo'llab-quvvatlanadi — ro'yxatdan o'tgan
/// foydalanuvchini qidirib biriktirish alohida feature (foydalanuvchi
/// qidiruvi) bo'lib, ushbu foundation doirasidan tashqarida.
abstract interface class DisputesRepository {
  Future<Result<Dispute>> createWithUnregisteredRespondent({
    required String categoryId,
    required String title,
    required String description,
    required String respondentDisplayName,
  });

  /// Faqat `initiator` va faqat `status = 'open'` bo'lganda ishlaydi.
  Future<Result<Dispute>> updateAsInitiator({
    required String disputeId,
    String? title,
    String? description,
  });

  /// Faqat `respondent` va faqat `status IN ('open', 'ai_analyzing')`
  /// bo'lganda ishlaydi.
  Future<Result<Dispute>> submitRespondentStatement({
    required String disputeId,
    required String statement,
  });

  /// Faqat `open` holatida initiator tomonidan.
  Future<Result<void>> deleteAsInitiator(String disputeId);

  Future<Result<Dispute>> getById(String disputeId);

  /// Joriy foydalanuvchi initiator YOKI respondent bo'lgan barcha
  /// nizolar.
  Future<Result<List<Dispute>>> listMine();
}
