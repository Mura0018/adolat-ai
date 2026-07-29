/// `AITransport`ning simli (wire) mexanizmi -- qaysi kanal orqali
/// `AIRequestEnvelope`/`AIProtocolStreamEvent` uzatiladi.
///
/// Ro'yxat Module 4, Phase 3B talab ro'yxatiga aynan mos ("Support
/// future: HTTP, Streaming, WebSocket, gRPC") -- hech biri hali
/// implementatsiya qilinmagan.
enum AITransportKind {
  /// Oddiy so'rov/javob (bitta yakuniy javob, oqim yo'q).
  http,

  /// Uzoq muddatli, bir yo'nalishli oqim ustidagi HTTP (masalan
  /// Server-Sent Events yoki chunked transfer encoding).
  streamingHttp,

  /// Ikki yo'nalishli, doimiy ulanish.
  webSocket,

  /// Ikki yo'nalishli oqim, HTTP/2 ustida (masalan gRPC bidirectional
  /// streaming).
  grpc,
}
