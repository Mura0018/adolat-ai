import '../protocol/ai_protocol_stream_event.dart';
import '../protocol/ai_request_envelope.dart';
import 'auth/ai_auth_context.dart';

/// Provayderdan mustaqil AI Backend Gateway shartnomasi (Module 4,
/// Phase 3B talabi: "Backend Gateway Contracts").
///
/// Bu -- klient ↔ backend chegarasining MANTIQIY (logical) kontrakti:
/// transportga xos kirish nuqtasi (masalan HTTP handler) allaqachon
/// `AIRequestEnvelope`ni deserializatsiya qilib, `AIAuthenticator`
/// orqali `AIAuthContext` olib bo'lgach, shu metodni chaqiradi.
/// `AIGateway`ning o'zi HTTP/WebSocket/gRPC haqida HECH NARSA bilmaydi
/// -- shu mustaqillik `AITransport` (`transport/ai_transport.dart`)
/// bilan bir xil sabab bilan qasddan qilingan
/// (`docs/AI_ARCHITECTURE.md`, "Provider Abstraction"dagi bir xil
/// naqsh, endi transport uchun ham).
abstract interface class AIGateway {
  Stream<AIProtocolStreamEvent> handle({
    required AIRequestEnvelope request,
    required AIAuthContext auth,
  });
}
