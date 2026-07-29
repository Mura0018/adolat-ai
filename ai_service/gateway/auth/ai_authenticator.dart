import 'ai_auth_context.dart';

/// Klient ↔ backend autentifikatsiya CHEGARASI (Module 4, Phase 3B
/// talabi: "Authentication Boundary" -- **faqat interfeys, hech qanday
/// implementatsiya yo'q**, `AISafetyService` (Phase 1) bilan bir xil
/// konventsiya).
///
/// Bu chegara `AIGateway`dan OLDIN, transportga xos kirish nuqtasida
/// (masalan HTTP handler) ishlaydi: xom hisob ma'lumotini (credential)
/// oladi, tekshiradi, `AIAuthContext`ga aylantiradi, so'ng
/// `AIGateway.handle(request, auth: ...)`ga uzatadi. Shu ajratish
/// tufayli `AIGateway`/`AIRequestDispatcher` "qanday token tekshiriladi"
/// haqida umuman bilmaydi -- faqat tayyor `AIAuthContext`ni ishlatadi.
abstract interface class AIAuthenticator {
  /// [credential] -- transport-ga xos, xom ma'lumot (masalan HTTP
  /// `Authorization` sarlavhasi qiymati yoki WebSocket handshake
  /// tokeni). Shakli ATAYLAB `Object?` -- bu interfeys qaysi transport
  /// ishlatilishidan mustaqil.
  Future<AIAuthContext> authenticate(Object? credential);
}
