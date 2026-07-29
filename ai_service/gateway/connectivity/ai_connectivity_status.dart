/// Transport ulanishining bilingan holati (Module 4, Phase 3B talabi:
/// "Connectivity Abstraction" -- kelgusi onlayn/oflayn qo'llab-
/// quvvatlash uchun).
enum AIConnectivityStatus {
  online,
  offline,

  /// Holat hali aniqlanmagan (masalan ilova endigina ishga tushdi).
  unknown,
}
