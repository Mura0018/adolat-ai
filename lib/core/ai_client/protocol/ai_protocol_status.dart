/// `AiResponseEnvelope.status`ning yakuniy holati. `ai_service/protocol/
/// ai_protocol_status.dart`ning klient tomonidagi mustaqil ko'chirmasi --
/// bir xil uchta qiymat, wire orqali `.name` bilan serialize qilinadi.
enum AiProtocolStatus { completed, failed, cancelled }
