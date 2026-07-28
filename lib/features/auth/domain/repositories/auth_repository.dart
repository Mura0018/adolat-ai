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
  /// o'tish shakli"). `phoneNumber`/`email`dan **aynan bittasi** talab
  /// qilinadi (ikkalasi ham emas, birontasi ham bo'lmasa ham emas) — bu
  /// Supabase Auth'ning o'zi qo'yadigan cheklov (`GoTrueClient.signUp`),
  /// chaqiruvchi tomonda (presentation/use case) tekshiriladi.
  ///
  /// **Nega `Result<void>`, `Result<AppUser>` emas:** telefon orqali
  /// ro'yxatdan o'tishda Supabase hech qanday sessiya bermaydi (SMS
  /// tasdiqlanmaguncha) — shu paytda `profiles`ni o'qishga urinish RLS
  /// tomonidan rad etiladi, chunki `auth.uid()` hali `null`. Haqiqiy
  /// `AppUser` faqat [verifyPhoneOtp] muvaffaqiyatli tugagandan keyin
  /// mavjud bo'ladi. Agar `phoneNumber` berilgan bo'lsa, chaqiruvchi
  /// tomon [verifyPhoneOtp]ga o'tishi shart (docs/SECURITY.md: "Telefon
  /// orqali ro'yxatdan o'tishda SMS-kod bilan tasdiqlash talab qilinadi").
  Future<Result<void>> registerCitizen({
    required String password,
    required String fullName,
    String? phoneNumber,
    String? email,
  });

  /// Tashkilot sifatida ro'yxatdan o'tkazadi (docs/UI.md: "Tashkilot
  /// ro'yxatdan o'tish shakli"; docs/DATABASE.md, 2-jadval). Fuqaro
  /// maydonlariga qo'shimcha ravishda yuridik ma'lumotlarni talab qiladi.
  /// `Result<void>` sababi [registerCitizen]dagi bilan bir xil.
  Future<Result<void>> registerOrganization({
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
  /// tasdiqlash (SMS) ekrani") — muvaffaqiyatli bo'lsa sessiya
  /// o'rnatiladi, shuning uchun to'liq `AppUser` qaytariladi (registratsiya
  /// oqimida bu sessiya birinchi marta shu yerda paydo bo'ladi).
  Future<Result<AppUser>> verifyPhoneOtp({
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
