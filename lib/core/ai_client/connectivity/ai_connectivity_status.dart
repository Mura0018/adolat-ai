/// Klientning tarmoq ulanishi haqidagi bilingan holati -- backend
/// `AIConnectivityStatus` (`ai_service/gateway/connectivity/
/// ai_connectivity_status.dart`) bilan wire-shaklda mos.
enum AiConnectivityStatus {
  online,
  offline,

  /// Holat hali aniqlanmagan (masalan ilova endigina ishga tushdi).
  unknown,
}
