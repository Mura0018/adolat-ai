import '../protocol/ai_protocol_stream_event.dart';
import '../protocol/ai_request_envelope.dart';

/// Klient tomonidagi, provayderdan MUSTAQIL yagona shartnoma -- Flutter
/// ilovasi AI bilan FAQAT shu interfeys orqali gaplashadi (Module 4,
/// Phase 4A, "AI Client Interface").
///
/// **Hech qanday provayder SDK'si YO'Q va bo'lishi ham mumkin emas:**
/// bu interfeys `AiRequestEnvelope`/`AiProtocolStreamEvent`dan (simli
/// shartnoma) boshqa hech narsani bilmaydi -- OpenAI/Gemini/Claude/Local
/// LLM haqida bu qatlamda (yoki undan yuqorida, `AiRequestPipeline`da)
/// bitta ham import/reference yo'q. Qaysi provayder ishlatilishi butunlay
/// backend'ning (`ai_service/`) qarori (`docs/adr/ADR-005`).
///
/// Bu klass backend'dagi `AIGateway`ning (`ai_service/gateway/
/// ai_gateway.dart`) klient tomonidagi ko'zgusi (mirror) -- ikkalasi ham
/// bir xil "so'rov -> autentifikatsiya -> oqim" shaklini ifodalaydi,
/// lekin mustaqil Dart turlari bilan (`ai_protocol_version.dart`dagi
/// izohga qarang).
///
/// **Hozirgi implementatsiya:** `mock/mock_ai_gateway_client.dart` --
/// haqiqiy HTTP/WebSocket orqali backend'ga ulanuvchi implementatsiya
/// (`HttpAiGatewayClient` va sh.k.) Module 4, Phase 4A doirasidan
/// tashqarida (haqiqiy backend qurilganda qo'shiladi -- quyidagi
/// "Kelgusi backend almashtirish strategiyasi"ga, `docs/
/// AI_ARCHITECTURE.md`ga qarang).
abstract interface class AiGatewayClient {
  /// [request]ni backend AI Gateway'iga yuboradi va natijani oqim
  /// sifatida qaytaradi.
  ///
  /// [credential] -- transportga xos, xom autentifikatsiya ma'lumoti
  /// (masalan joriy Supabase sessiyasining access token'i). Shakli
  /// ATAYLAB `Object?` -- backend `AIAuthenticator.authenticate()`
  /// (`ai_service/gateway/auth/ai_authenticator.dart`) bilan bir xil
  /// sabab bilan, transport turi qaysi bo'lishidan mustaqil.
  Stream<AiProtocolStreamEvent> sendMessage(AiRequestEnvelope request, {Object? credential});
}
