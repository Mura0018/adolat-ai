import 'network_status.dart';

/// Tarmoq holatini kuzatuvchi ABSTRAKT shartnoma
/// (`docs/ARCHITECTURE.md`, "Network State Handling").
///
/// **Bu — Module 6B'ning asosiy almashtirish nuqtasi.** Haqiqiy
/// implementatsiya platforma signallarini (`connectivity_plus` kabi
/// paket yoki platform channel) va backend'ga yetish tekshiruvini
/// birlashtiradi — lekin **u paketni tanlash alohida qaror** va yangi
/// bog'liqlik qo'shishni talab qiladi, shuning uchun bu bosqichda
/// ataylab qilinmagan (`DEVELOPMENT_RULES.md`, 3-band).
///
/// Shartnoma oldin belgilangani uchun `SyncScheduler` va
/// `QueuedSyncEngine` haqiqiy kuzatuvsiz ham to'liq qurilgan va
/// sinalgan — paket kelganda faqat shu interfeysning yangi
/// implementatsiyasi yoziladi.
///
/// **Bu komponent ma'lumot saqlamaydi va sinxronlamaydi** —
/// `docs/ARCHITECTURE.md`: *"Network State Handling — Offline-First
/// Architecture'ning 'sezuv organi'; u o'zi ma'lumot saqlamaydi va
/// sinxronlamaydi, faqat Local Storage va Sync Engine'ga qachon
/// harakat qilish kerakligini bildiradi"*.
abstract interface class NetworkStateMonitor {
  /// Joriy holat — sinxron o'qiladi (masalan sikl boshlanishidan
  /// oldin tez tekshiruv uchun).
  NetworkStatus get currentStatus;

  /// Holat O'ZGARISHLARI oqimi.
  ///
  /// Faqat haqiqiy o'zgarishlar chiqariladi (bir xil holat ketma-ket
  /// ikki marta emas) — aks holda har bir platforma signali keraksiz
  /// sinxronizatsiya sikliga sabab bo'lardi.
  Stream<NetworkStatusChange> get changes;

  /// Holatni darhol tekshiradi (masalan ilova ochilganda).
  ///
  /// Implementatsiya kelgusida backend'ga yengil so'rov yuborishi
  /// mumkin — shuning uchun `Future`.
  Future<NetworkStatus> refresh();
}
