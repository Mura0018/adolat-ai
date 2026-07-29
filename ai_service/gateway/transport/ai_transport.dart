import '../../protocol/ai_protocol_stream_event.dart';
import '../../protocol/ai_request_envelope.dart';
import 'ai_transport_kind.dart';

/// `AIRequestEnvelope`ni backendga yetkazuvchi va `AIProtocolStreamEvent`
/// oqimini qaytaruvchi, simli mexanizmdan MUSTAQIL shartnoma (Module 4,
/// Phase 3B talabi: "Transport Abstraction" -- **faqat interfeys, hech
/// qanday implementatsiya yo'q**).
///
/// Bitta `AIGateway.handle()` (yuqori darajadagi, `AIRequestEnvelope`ni
/// qabul qilib `AIProtocolStreamEvent` oqimini qaytaruvchi kontrakt)
/// turli xil `AITransport` implementatsiyalari orqali (HTTP/streaming
/// HTTP/WebSocket/gRPC) chaqirilishi mumkin bo'lishi kerak -- shu
/// sababli ikkalasi bir xil IMZOga ega. Farqi: `AIGateway` --
/// backendning MANTIQIY kontrakti (bitta jarayon ichida, serializatsiya
/// yo'q); `AITransport` -- klient tomonidagi (yoki gateway oldidagi)
/// SIMLI adapter, `AIRequestEnvelope`/`AIProtocolStreamEvent`ni
/// haqiqiy baytlarga aylantiradi/dan qaytaradi.
///
/// Kelgusi implementatsiyalar (bu bosqichda YO'Q): `HttpAITransport`,
/// `WebSocketAITransport`, `GrpcAITransport`, ... -- har biri shu
/// interfeysni amalga oshiradi, chaqiruvchi kod (masalan klientning
/// AI-repository'si) qaysi biri ishlatilayotganini bilishi shart emas.
abstract interface class AITransport {
  AITransportKind get kind;

  /// So'rovni yuboradi va natijani oqim sifatida qaytaradi. Bitta
  /// yakuniy javob beruvchi transport (`http`) uchun ham bir xil imzo
  /// ishlatiladi -- oqim faqat `started` → `completed` (yoki `failed`)
  /// dan iborat bo'ladi, `chunk` chiqarilmaydi.
  Stream<AIProtocolStreamEvent> send(AIRequestEnvelope request);
}
