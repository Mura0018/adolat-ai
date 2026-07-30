/// Qayta urinishlar orasidagi kutish oralig'ini hisoblovchi XOLIS
/// (pure) qoida (`docs/ARCHITECTURE.md`, "Sync Engine": *"ortib
/// boruvchi kutish oralig'i (backoff) bilan qayta uriniladi"*).
///
/// Holat saqlamaydi, vaqtga bog'liq emas, tasodifiylik ishlatmaydi —
/// shuning uchun to'liq sinaladigan. `AIRetryPolicy` (Module 4,
/// Phase 2C) bilan bir xil falsafa: qoida — funksiya, holat —
/// chaqiruvchida.
class SyncBackoffPolicy {
  const SyncBackoffPolicy({
    this.initialDelay = const Duration(seconds: 5),
    this.maxDelay = const Duration(minutes: 30),
    this.multiplier = 2,
    this.maxAttempts = 8,
  }) : assert(multiplier >= 1),
       assert(maxAttempts > 0);

  final Duration initialDelay;

  /// Yuqori chegara — kutish oralig'i cheksiz o'smaydi, aks holda
  /// amal amalda "abadiy kutish" holatiga tushib qolardi.
  final Duration maxDelay;

  final int multiplier;

  /// Shuncha urinishdan keyin amal `needsAttention` holatiga
  /// o'tkaziladi — *"jimgina cheksiz qayta urinilmaydi"* talabining
  /// sonli ifodasi.
  final int maxAttempts;

  /// [attemptCount] — ALLAQACHON qilingan urinishlar soni
  /// (`PendingOperation.attemptCount`).
  ///
  /// 0 → [initialDelay]; keyin har safar [multiplier] barobar ortadi,
  /// [maxDelay]dan oshmaydi.
  Duration delayFor(int attemptCount) {
    if (attemptCount <= 0) return initialDelay;

    var delayMicroseconds = initialDelay.inMicroseconds;
    for (var i = 0; i < attemptCount; i++) {
      delayMicroseconds *= multiplier;
      if (delayMicroseconds >= maxDelay.inMicroseconds) {
        return maxDelay;
      }
    }

    return Duration(microseconds: delayMicroseconds);
  }

  /// Yana urinish mumkinmi.
  bool shouldRetry(int attemptCount) => attemptCount < maxAttempts;

  /// Chegaraga yetgan amal uchun foydalanuvchiga ko'rsatiladigan
  /// sabab (xom texnik matn emas).
  String exhaustedReason(int attemptCount) =>
      'Amal $attemptCount marta yuborishga urinildi, lekin muvaffaqiyatsiz '
      'tugadi — davom etish uchun tekshiruv kerak.';
}
