/// Marshrut yo'llari uchun markazlashgan konstantalar.
///
/// Feature qo'shilganda, uning yo'li shu klassga qo'shiladi — bu qattiq
/// kodlangan satrlarning ilova bo'ylab tarqalib ketishini oldini oladi.
abstract final class RoutePaths {
  static const String home = '/';

  // --- appeals ---
  static const String appeals = '/appeals';
  static const String appealCreate = '/appeals/new';
  static const String appealDetail = '/appeals/:appealId';

  static String appealDetailFor(String appealId) => '/appeals/$appealId';

  // --- disputes ---
  static const String disputes = '/disputes';
  static const String disputeCreate = '/disputes/new';
  static const String disputeDetail = '/disputes/:disputeId';

  static String disputeDetailFor(String disputeId) => '/disputes/$disputeId';
}
