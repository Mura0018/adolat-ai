/// Foydalanuvchi darajasidagi kunlik/oylik AI so'rov cheklovi (Module
/// 4, Phase 4B talabi: "Usage quota model") -- `docs/adr/ADR-004-ai-cost-governance.md`,
/// Variant D ning "B" qismi: "foydalanuvchi chegarasi: kuniga
/// foydalanuvchi boshiga maksimal AI tahlil so'rovi soni".
///
/// **`gateway/ratelimit/ai_rate_limiter.dart` (shu bosqich) bilan
/// FARQI -- ADASHTIRILMASIN:** ikkalasi ham "so'rovlarni sanaydi", lekin
/// mantiqan boshqa-boshqa maqsadga xizmat qiladi:
/// - **Rate limit** -- QISQA oyna (masalan daqiqada N ta), SUIISTE'MOL/
///   DoS'dan himoya (`ADR-004`, "individual suiiste'mol emas, GLOBAL
///   portlashdan" ga yaqinroq, tezkor skript/bot hujumini ushlaydi).
///   Yetilganda `AIProtocolErrorCode.rateLimited` -- odatda TEZDA
///   (soniyalar/daqiqalarda) o'zi tiklanadi (`retryable: true`,
///   `AIRateLimitFailure.retryAfter`).
/// - **Usage quota** -- UZOQ oyna (kuniga/oyiga N ta), MAHSULOT/BIZNES
///   chegarasi (haqiqiy, halol foydalanuvchining necha marta AI tahlil
///   so'rashi mumkinligi). Yetilganda `AIProtocolErrorCode.quotaExceeded`
///   -- ancha KEYIN (ertaga) tiklanadi, foydalanuvchiga boshqacha xabar
///   kerak ("Kunlik so'rov chegarasiga yetdingiz, ertaga qayta urinib
///   ko'ring" -- `ADR-004`, "Tavsiya etilgan qaror", band 3).
///
/// **Nega aniq son bu yerda YO'Q:** `gateway/ratelimit/ai_rate_limiter.dart`dagi
/// bilan bir xil sabab -- `ADR-004` aniq sonni "mahsulot jamoasi bilan
/// kelishilishi kerak" deb ochiq qoldirgan. [AIUsageQuotaPolicy]da
/// yashirin standart qiymat yo'q.
class AIUsageQuotaPolicy {
  // Const konstruktor emas -- `Duration` operatorlari (`>`) doimiy
  // (const) ifodalarda qo'llab-quvvatlanmaydi (`gateway/ratelimit/
  // ai_rate_limiter.dart`dagi `AIRateLimitPolicy` bilan bir xil sabab).
  AIUsageQuotaPolicy({required this.maxRequestsPerWindow, required this.window})
    : assert(maxRequestsPerWindow > 0, 'maxRequestsPerWindow musbat bo\'lishi kerak'),
      assert(window > Duration.zero, 'window musbat bo\'lishi kerak');

  final int maxRequestsPerWindow;
  final Duration window;
}

/// Bitta foydalanuvchining joriy oyna ichidagi holati -- saqlash
/// mexanizmidan (xotira/Postgres/Redis) mustaqil, xolis (pure)
/// ma'lumot.
class AIUsageQuotaState {
  const AIUsageQuotaState({required this.usedInWindow, required this.windowStartedAt})
    : assert(usedInWindow >= 0, 'usedInWindow manfiy bo\'lishi mumkin emas');

  final int usedInWindow;
  final DateTime windowStartedAt;
}

class AIUsageQuotaDecision {
  const AIUsageQuotaDecision({required this.allowed, required this.remaining, required this.resetAt});

  final bool allowed;
  final int remaining;
  final DateTime resetAt;

  @override
  String toString() =>
      'AIUsageQuotaDecision(allowed: $allowed, remaining: $remaining, resetAt: $resetAt)';
}

/// Xolis (pure) baholash funksiyasi -- [state]/[policy]/[now]dan qaror
/// chiqaradi, hech qanday saqlash (I/O) qilmaydi. Oynaning
/// tugaganini (`now` `windowStartedAt + window`dan keyin bo'lsa)
/// aniqlash ham shu funksiyaning ishi -- hisoblagichni ROSTDAN
/// nolga tushirish (reset) esa [AIUsageQuotaStore]ning vazifasi.
AIUsageQuotaDecision evaluateUsageQuota({
  required AIUsageQuotaPolicy policy,
  required AIUsageQuotaState state,
  required DateTime now,
}) {
  final windowEndsAt = state.windowStartedAt.add(policy.window);
  final windowExpired = !now.isBefore(windowEndsAt);

  if (windowExpired) {
    return AIUsageQuotaDecision(
      allowed: true,
      remaining: policy.maxRequestsPerWindow - 1,
      resetAt: now.add(policy.window),
    );
  }

  final remaining = policy.maxRequestsPerWindow - state.usedInWindow;
  return AIUsageQuotaDecision(
    allowed: remaining > 0,
    remaining: remaining > 0 ? remaining - 1 : 0,
    resetAt: windowEndsAt,
  );
}

/// Foydalanuvchi bo'yicha kvota holatini saqlovchi/o'qiydigan
/// CHEGARA -- **faqat interfeys, hech qanday implementatsiya yo'q**
/// (`ConversationRepository`/`AICancellationRegistry` (Phase 2A) bilan
/// bir xil ruhda: abstrakt shartnoma, xotirada (`InMemory...`) yoki
/// haqiqiy DB ustida qurilishi mumkin -- `ADR-004`, "Migratsiya
/// ta'siri": "foydalanuvchi/kunlik hisoblagich uchun kichik jadval").
abstract interface class AIUsageQuotaStore {
  Future<AIUsageQuotaState> getState(String userId);

  /// Bitta so'rov sarflanganini qayd etadi -- hisoblagichni oshiradi
  /// (yoki oyna tugagan bo'lsa, yangi oyna bilan qayta boshlaydi).
  Future<void> recordUsage({required String userId, required DateTime at});
}
