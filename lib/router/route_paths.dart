/// Marshrut yo'llari uchun markazlashgan konstantalar.
///
/// Feature qo'shilganda, uning yo'li shu klassga qo'shiladi — bu qattiq
/// kodlangan satrlarning ilova bo'ylab tarqalib ketishini oldini oladi.
abstract final class RoutePaths {
  /// Ilova ochilganda ko'rsatiladigan boshlang'ich ekran — sessiya
  /// tekshirilayotgan paytda ko'rinadi (docs/UI.md, "App Entry Flow").
  static const String splash = '/splash';

  // --- auth (docs/UI.md, "Authentication Screens") ---
  static const String authRoleSelect = '/auth/role';
  static const String authRegisterCitizen = '/auth/register/citizen';
  static const String authRegisterOrganization = '/auth/register/organization';
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String authLogin = '/auth/login';
  static const String authResetPasswordRequest = '/auth/reset-password';
  static const String authResetPasswordConfirm = '/auth/reset-password/confirm';

  // --- Fuqaro/Tashkilot asosiy navigatsiya (docs/UI.md, "Navigation Structure") ---
  static const String home = '/home';
  static const String appeals = '/appeals';
  static const String appealCreate = '/appeals/new';
  static const String appealDetail = '/appeals/:appealId';
  static const String disputes = '/disputes';
  static const String disputeCreate = '/disputes/new';
  static const String disputeDetail = '/disputes/:disputeId';
  static const String notifications = '/notifications';
  static const String profile = '/profile';

  static String appealDetailFor(String appealId) => '/appeals/$appealId';
  static String disputeDetailFor(String disputeId) => '/disputes/$disputeId';

  // --- Admin asosiy navigatsiya (docs/UI.md, "Navigation Structure") ---
  static const String adminAppeals = '/admin/appeals';
  static const String adminDisputes = '/admin/disputes';
  static const String adminReference = '/admin/reference';
  static const String adminAuditLog = '/admin/audit-log';
  static const String adminProfile = '/admin/profile';
}
