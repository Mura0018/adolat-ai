import '../../../../core/network/result.dart';
import '../entities/government_body.dart';
import '../entities/legal_category.dart';

/// Murojaat/nizo yaratishda tanlanadigan boshqariladigan ma'lumotnomalar
/// uchun abstrakt shartnoma (docs/DATABASE.md, 3 va 4-jadvallar). Faqat
/// o'qish — bu ma'lumotlarni yozish `admin`ga tegishli, ushbu feature
/// doirasida emas.
abstract interface class LegalReferenceRepository {
  Future<Result<List<LegalCategory>>> getActiveLegalCategories();

  Future<Result<List<GovernmentBody>>> getActiveGovernmentBodies();
}
