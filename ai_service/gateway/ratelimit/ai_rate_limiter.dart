import '../../protocol/ai_rate_limit_contract.dart';
import '../endpoint/ai_backend_endpoint.dart';

/// So'rovlar sonini cheklash CHEGARASI (Module 4, Phase 4B talabi:
/// "Rate-limit contract") -- `docs/adr/ADR-004-ai-cost-governance.md`,
/// Variant D ("foydalanuvchi darajasidagi statik chegara")ning
/// arxitektura darajasidagi ifodasi.
///
/// **Nega aniq son (masalan "kuniga 20 ta so'rov") bu yerda YO'Q:**
/// `ADR-004`ning o'zi buni ochiq qoldiradi -- "aniq son mahsulot
/// jamoasi bilan kelishilishi kerak, real foydalanuvchi ehtiyojidan
/// 3-5 baravar yuqori qilib boshlanadi, keyin monitoring asosida
/// moslashtiriladi". Shuning uchun [AIRateLimitPolicy] -- `AITimeoutPolicy`
/// (Phase 3B)dan farqli o'laroq -- hech qanday YASHIRIN standart
/// qiymatga ega EMAS, `maxRequests`/`window` har doim chaqiruvchi
/// tomonidan aniq berilishi shart.
class AIRateLimitPolicy {
  // Const konstruktor emas -- `Duration` operatorlari (`>`) doimiy
  // (const) ifodalarda qo'llab-quvvatlanmaydi, shuning uchun bu klass
  // hech qachon `const` bilan chaqirilmasligi kerak (`AITimeoutPolicy`,
  // Phase 3B'dan farqli o'laroq -- o'sha yerda bunday assert yo'q).
  AIRateLimitPolicy({required this.maxRequests, required this.window})
    : assert(maxRequests > 0, 'maxRequests musbat bo\'lishi kerak'),
      assert(window > Duration.zero, 'window musbat bo\'lishi kerak');

  /// [window] davomida bitta doira (scope, masalan bitta foydalanuvchi)
  /// uchun ruxsat etilgan maksimal so'rov soni.
  final int maxRequests;

  final Duration window;
}

/// Bitta cheklov tekshiruvining natijasi.
class AIRateLimitDecision {
  const AIRateLimitDecision({required this.allowed, required this.status});

  final bool allowed;
  final AIRateLimitStatus status;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIRateLimitDecision && other.allowed == allowed && other.status == status);
  }

  @override
  int get hashCode => Object.hash(allowed, status);

  @override
  String toString() => 'AIRateLimitDecision(allowed: $allowed, status: $status)';
}

/// Rate-limit tekshiruvi -- **faqat interfeys, hech qanday
/// implementatsiya yo'q** (`AISafetyService`/`AIAuthenticator`/
/// `AIConnectivityMonitor`/`AITransport` bilan bir xil, allaqachon
/// o'rnatilgan konventsiya).
///
/// Haqiqiy implementatsiya (masalan Redis/Postgres hisoblagich
/// ustiga qurilgan) kelgusi bosqichda qo'shiladi -- hisoblagichning
/// qayerda saqlanishi (xotirada, Redis, DB) bu interfeysning ishi
/// emas, faqat natija (`AIRateLimitDecision`) muhim.
abstract interface class AIRateLimiter {
  /// [userId] va [endpoint] bo'yicha joriy so'rovni HISOBLAYDI va
  /// ruxsat berish/bermaslik haqida qaror qaytaradi -- "faqat tekshirish"
  /// emas, chaqirilishning o'zi bitta so'rovni sarflaydi (shuning
  /// uchun `checkAndConsume`, alohida `check()`/`consume()` juftligi
  /// emas -- ikkitasi orasida race condition xavfi bo'lmasligi uchun).
  Future<AIRateLimitDecision> checkAndConsume({
    required String userId,
    required AIBackendEndpointId endpoint,
  });
}
