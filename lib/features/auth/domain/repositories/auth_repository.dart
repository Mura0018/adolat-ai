import '../../../../core/network/result.dart';
import '../entities/app_user.dart';

/// Autentifikatsiya va profil-yaratish ustidagi biznes amallar uchun
/// abstrakt shartnoma (docs/UI.md, "Authentication Screens" va "App Entry
/// Flow" bo'limlari; docs/ARCHITECTURE.md, "Authentication Flow" bo'limi;
/// docs/SECURITY.md, "Autentifikatsiya" bo'limi).
///
/// docs/adr/ADR-006-hybrid-infrastructure-strategy.md'ga muvofiq: bu
/// interfeys hech qanday backend-maxsus turga bog'liq emas — uni amalga
/// oshiruvchi implementatsiya (`data/repositories/`) qaysi backend
/// (hozircha Supabase Auth) ishlatilishini butunlay yashiradi.
abstract interface class AuthRepository {
  /// Fuqaro sifatida ro'yxatdan o'tkazadi (docs/UI.md: "Fuqaro ro'yxatdan
  /// o'tish shakli"). `phoneNumber`/`email`dan **kamida bittasi** talab
  /// qilinadi — bu invariant chaqiruvchi tomonda (presentation/use case)
  /// tekshiriladi, chunki Dart tur tizimi buni interfeys darajasida
  /// ifodalay olmaydi.
  ///
  /// Agar `phoneNumber` berilgan bo'lsa, hisob faollashishi uchun
  /// [verifyPhoneOtp] chaqirilishi shart (docs/SECURITY.md: "Telefon
  /// orqali ro'yxatdan o'tishda SMS-kod bilan tasdiqlash talab qilinadi").
  Future<Result<AppUser>> registerCitizen({
    required String password,
    required String fullName,
    String? phoneNumber,
    String? email,
  });

  /// Tashkilot sifatida ro'yxatdan o'tkazadi (docs/UI.md: "Tashkilot
  /// ro'yxatdan o'tish shakli"; docs/DATABASE.md, 2-jadval). Fuqaro
  /// maydonlariga qo'shimcha ravishda yuridik ma'lumotlarni talab qiladi.
  Future<Result<AppUser>> registerOrganization({
    required String password,
    required String fullName,
    required String legalName,
    required String taxId,
    required String legalAddress,
    String? phoneNumber,
    String? email,
    String? contactEmail,
  });

  /// Telefon raqamini SMS kodi bilan tasdiqlaydi (docs/UI.md: "Telefon
  /// tasdiqlash (SMS) ekrani").
  Future<Result<void>> verifyPhoneOtp({
    required String phoneNumber,
    required String otpCode,
  });

  /// SMS kodini qayta yuboradi (docs/UI.md: "kodni qayta yuborish...
  /// aniq ko'rsatiladi").
  Future<Result<void>> resendPhoneOtp({required String phoneNumber});

  /// Telefon yoki email va parol bilan kiradi (docs/UI.md: "Kirish
  /// (login) ekrani"). `identifier` — telefon raqami yoki email, qaysi
  /// biri ro'yxatdan o'tishda ishlatilgan bo'lsa.
  Future<Result<AppUser>> login({
    required String identifier,
    required String password,
  });

  /// Parolni tiklash so'rovini boshlaydi — tasdiqlash kodi/havola
  /// yuboriladi (docs/UI.md: "Parolni tiklash oqimi").
  Future<Result<void>> requestPasswordReset({required String identifier});

  /// Parolni tiklash so'rovini tasdiqlash kodi bilan yakunlaydi va yangi
  /// parol o'rnatadi.
  Future<Result<void>> confirmPasswordReset({
    required String identifier,
    required String otpCode,
    required String newPassword,
  });

  /// Joriy sessiyani tugatadi va mahalliy tokenlarni tozalaydi
  /// (docs/UI.md: "Chiqish (logout) tasdiqlashi").
  Future<Result<void>> logout();

  /// Ilova ishga tushganda mahalliy saqlangan sessiyani tiklashga
  /// urinadi — sessiya yo'q bo'lsa `Result.ok(null)` qaytaradi, xatolik
  /// emas (docs/UI.md: "App Entry Flow", 2–4-qadamlar).
  Future<Result<AppUser?>> restoreSession();

  /// Joriy foydalanuvchi holatining reaktiv oqimi — kirish/chiqish sodir
  /// bo'lganda yangi qiymat chiqaradi; sessiya yo'q bo'lsa `null`. GoRouter
  /// auth guard shu oqimni tinglab marshrutlarni qayta baholaydi
  /// (docs/UI.md: "Autentifikatsiya to'sig'i (auth guard)").
  Stream<AppUser?> get authStateChanges;
}
