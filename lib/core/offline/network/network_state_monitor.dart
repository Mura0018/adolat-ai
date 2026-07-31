import 'network_status.dart';

/// Tarmoq holatini kuzatuvchi ABSTRAKT shartnoma
/// (`docs/ARCHITECTURE.md`, "Network State Handling").
///
/// **Bu — Module 6B'ning asosiy almashtirish nuqtasi.**
///
/// **Qabul qilingan qaror (`docs/adr/ADR-008-network-signal-source.md`,
/// 2026-07-31):** haqiqiy implementatsiya IKKI manbani birlashtiradi —
/// `connectivity_plus` **turtki (hint)** sifatida (interfeys
/// yo'qolganda darhol to'xtash, qaytganda urinishga signal) va
/// **so'rov natijalari** (`SyncOperationOutcome`) **haqiqat manbai**
/// sifatida. Sabab: hujjat oflaynni *"backend'ga yeta olmaslik"* deb
/// ta'riflaydi, interfeys holatini o'lchaydigan paket esa bunga javob
/// bera olmaydi — Wi-Fi'ga ulangan, lekin internetga chiqmaydigan
/// qurilma unga "onlayn" bo'lib ko'rinadi.
///
/// **Implementatsiya hali yozilmagan** — alohida vazifa sifatida
/// rejalashtirilgan. Shartnoma oldin belgilangani uchun
/// `SyncScheduler` va `QueuedSyncEngine` haqiqiy kuzatuvsiz ham to'liq
/// qurilgan va sinalgan.
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
