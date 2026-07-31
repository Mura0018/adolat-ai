/// Qurilmaning tarmoq INTERFEYSI holati manbai — `connectivity_plus`
/// ustidagi eng yupqa mavhumlik (`docs/adr/ADR-008-network-signal-source.md`).
///
/// **Nega paketni to'g'ridan-to'g'ri ishlatmaymiz:** `connectivity_plus`
/// platforma kanaliga tayanadi, ya'ni uni `flutter test` ichida
/// (emulatorsiz CI) ishlatib bo'lmaydi. Shu bitta interfeys
/// `ReachabilityAwareNetworkMonitor`ning butun mantig'ini sof Dart
/// testlari bilan qoplash imkonini beradi — paketning o'zi esa
/// bitta juda yupqa faylda (`ConnectivityPlusSource`) qoladi.
///
/// **Bu "onlayn" degani EMAS.** ADR-008ning markaziy xulosasi:
/// interfeys holati backend'ga yetishni bildirmaydi (Wi-Fi'ga
/// ulangan, lekin internetga chiqmaydigan qurilma bu yerda `true`
/// qaytaradi). Shuning uchun tur nomi ataylab `Connectivity...` —
/// `Network...` emas.
abstract interface class ConnectivitySource {
  /// Interfeys hozir ko'tarilganmi (Wi-Fi/mobil/ethernet mavjudmi).
  Future<bool> isInterfaceUp();

  /// Interfeys holati o'zgarishlari oqimi (`true` — ko'tarilgan).
  Stream<bool> get interfaceChanges;
}
