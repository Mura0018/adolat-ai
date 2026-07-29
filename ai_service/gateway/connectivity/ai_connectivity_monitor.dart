import 'ai_connectivity_status.dart';

/// Ulanish holatini kuzatish uchun abstrakt shartnoma (Module 4,
/// Phase 3B talabi: "Connectivity Abstraction" -- **faqat interfeys,
/// hech qanday implementatsiya yo'q**, `AISafetyService`/
/// `AIAuthenticator` bilan bir xil konventsiya).
///
/// **Ko'lam:** bu klass hech qanday haqiqiy tarmoq holatini
/// TEKSHIRMAYDI (masalan `connectivity_plus` paketi yoki soket
/// tekshiruvi) -- bu Flutter/platforma-ga xos tafsilot, `ai_service/`
/// esa Flutter'dan mustaqil bo'lishi shart (`docs/AI_ARCHITECTURE.md`,
/// "Nega lib/dan tashqarida"). Kelgusida bu interfeysni klient
/// tomonidagi konkret implementatsiya (masalan `lib/`da, `ai_service/`
/// tashqarisida) amalga oshiradi.
///
/// **Nega kerak:** `AITransport`/`AIGateway` chaqiruvchisi (masalan
/// klientning AI-repository qatlami) so'rov yuborishdan OLDIN
/// `currentStatus == offline` ekanligini bilsa, foydasiz tarmoq
/// urinishi (va foydalanuvchiga chalkash xatolik xabari) o'rniga
/// darhol mos UI holatini ko'rsatishi mumkin.
abstract interface class AIConnectivityMonitor {
  AIConnectivityStatus get currentStatus;

  Stream<AIConnectivityStatus> get statusChanges;
}
