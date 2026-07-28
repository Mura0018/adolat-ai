import '../../../../core/network/result.dart';
import '../entities/appeal.dart';

/// `public.appeals` ustidagi biznes amallar uchun abstrakt shartnoma
/// (docs/DATABASE.md, 5-jadval; docs/ARCHITECTURE.md, "Case Lifecycle"
/// bo'limi).
abstract interface class AppealsRepository {
  /// Yangi qoralama (`status = 'draft'`) yaratadi. `author_id` datasource
  /// tomonidan joriy foydalanuvchidan avtomatik olinadi.
  Future<Result<Appeal>> createDraft({
    required String categoryId,
    required String recipientBodyId,
    required String title,
    required String bodyText,
    String? aiDraftText,
  });

  /// Faqat `status = 'draft'` bo'lganda ishlaydi (RLS, supabase/migrations/
  /// 20260726000002_rls_policies.sql, appeals_update siyosati).
  Future<Result<Appeal>> updateDraft({
    required String appealId,
    String? title,
    String? bodyText,
  });

  /// Qoralamani yakuniy tasdiqlab, holatni `submitted`ga o'tkazadi.
  Future<Result<Appeal>> submit(String appealId);

  /// Faqat `status = 'draft'` bo'lgan o'z qoralamasini o'chira oladi.
  Future<Result<void>> deleteDraft(String appealId);

  Future<Result<Appeal>> getById(String appealId);

  /// Joriy foydalanuvchining barcha murojaatlari (eng yangisi birinchi).
  Future<Result<List<Appeal>>> listMine();
}
