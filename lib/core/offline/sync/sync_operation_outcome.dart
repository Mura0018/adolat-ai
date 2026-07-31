import '../conflict/sync_conflict.dart';

/// BITTA amalni bajarishga urinish NATIJASI.
///
/// `sealed` — to'rtta natijadan boshqasi yo'q, va har birini qayta
/// ishlash kompilyatsiyada majburlanadi.
///
/// **Eng muhim ajratish — [SyncTransientFailure] va
/// [SyncPermanentFailure]:** `docs/ARCHITECTURE.md`, "Sync Engine":
/// vaqtinchalik xatolikda amal navbatda qoladi va backoff bilan qayta
/// uriniladi; doimiy xatolikda esa *"amal 'e'tibor talab qiladi' deb
/// belgilanadi va foydalanuvchiga aniq xabar bilan ko'rsatiladi,
/// jimgina cheksiz qayta urinilmaydi"*.
///
/// Bu ajratishni KIM qiladi: `SyncOperationHandler` implementatsiyasi
/// (server javobini biladigan yagona qatlam). `QueuedSyncEngine` faqat
/// natijaga qarab harakat qiladi — shu bilan "qaysi xatolik
/// vaqtinchalik" bilimi bitta joyda qoladi.
sealed class SyncOperationOutcome {
  const SyncOperationOutcome();
}

/// Amal serverga muvaffaqiyatli yetkazildi.
class SyncSuccess extends SyncOperationOutcome {
  const SyncSuccess({this.remoteId});

  /// Server qaytargan identifikator — **ixtiyoriy, tasdiqlash uchun**.
  ///
  /// **ADR-009 (Qabul qilingan 2026-07-31) buni moslashtirish
  /// mexanizmi bo'lishdan chiqardi.** Yozuv identifikatori endi
  /// KLIENT tomonda (UUID v7) yaratiladi va birinchi kunidanoq
  /// YAKUNIY bo'ladi — ya'ni "server bergan haqiqiy id"ni mahalliy
  /// id o'rniga qo'yish kerak emas, chunki ular AYNAN bir xil.
  ///
  /// Maydon saqlanib qolmoqda (uni olib tashlash public API
  /// o'zgarishi bo'lardi) va ikki holatda foydali: server tomonda
  /// yaratilgan yozuvlar (masalan admin amallari) uchun, hamda
  /// diagnostikada — qaytgan id mahalliy id bilan mos kelmasa, bu
  /// dizayn buzilganini ko'rsatadi.
  final String? remoteId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SyncSuccess && other.remoteId == remoteId);

  @override
  int get hashCode => Object.hash(SyncSuccess, remoteId);

  @override
  String toString() => 'SyncSuccess(remoteId: $remoteId)';
}

/// Vaqtinchalik xatolik (tarmoq uzilishi, server vaqtincha
/// ishlamasligi) — amal navbatda qoladi, qayta uriniladi.
class SyncTransientFailure extends SyncOperationOutcome {
  const SyncTransientFailure(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SyncTransientFailure && other.message == message);

  @override
  int get hashCode => Object.hash(SyncTransientFailure, message);

  @override
  String toString() => 'SyncTransientFailure($message)';
}

/// Doimiy xatolik (validatsiya xatosi, ruxsat rad etilishi) — qayta
/// urinish ma'nosiz, foydalanuvchiga ko'rsatiladi.
class SyncPermanentFailure extends SyncOperationOutcome {
  const SyncPermanentFailure(this.message);

  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SyncPermanentFailure && other.message == message);

  @override
  int get hashCode => Object.hash(SyncPermanentFailure, message);

  @override
  String toString() => 'SyncPermanentFailure($message)';
}

/// Server holati mahalliy taxmin bilan mos kelmadi —
/// `ConflictResolutionStrategy` hal qiladi.
class SyncConflictDetected extends SyncOperationOutcome {
  const SyncConflictDetected(this.conflict);

  final SyncConflict conflict;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is SyncConflictDetected && other.conflict == conflict);

  @override
  int get hashCode => Object.hash(SyncConflictDetected, conflict);

  @override
  String toString() => 'SyncConflictDetected($conflict)';
}
