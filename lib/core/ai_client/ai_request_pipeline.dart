import '../error/failure.dart';
import 'connectivity/ai_connectivity_monitor.dart';
import 'connectivity/ai_connectivity_status.dart';
import 'context/ai_client_context_assembler.dart';
import 'domain/ai_client_conversation.dart';
import 'domain/ai_client_stream_event.dart';
import 'gateway/ai_gateway_client.dart';
import 'logging/ai_diagnostics_logger.dart';
import 'mapping/ai_response_mapper.dart';
import 'protocol/ai_request_envelope.dart';

/// To'liq AI so'rov quvurini (pipeline) bog'laydi (Module 4, Phase 4A
/// talabi: "AI Request Flow"):
///
/// ```
/// Foydalanuvchi amali -> Conversation -> Context Assembler ->
/// AI Gateway -> Backend Protocol -> Response Mapper
/// ```
///
/// 1. **Foydalanuvchi amali / Conversation** -- chaqiruvchi joriy
///    [AiClientConversation]ni (`conversationId` uchun) va xabar matnini
///    beradi. Bu klass conversation'ning o'zini O'ZGARTIRMAYDI --
///    chaqiruvchi (masalan kelgusi chat controller) qaytgan
///    [AiClientStreamEvent]larga qarab o'z nusxasini yangilaydi (masalan
///    `AiClientStreamCompleted` kelganda `conversation.appendMessage(...)`
///    chaqiradi).
/// 2. **Context Assembler** -- [AiClientContextAssembler.assemble()]
///    orqali `AiRequestEnvelope.context`ga joylanadigan xarita quriladi.
/// 3. **AI Gateway** -- [AiGatewayClient.sendMessage()] chaqiriladi
///    (hozircha `MockAiGatewayClient`, kelgusida haqiqiy HTTP/WebSocket
///    implementatsiyasi -- `mock/mock_ai_gateway_client.dart`ga qarang).
/// 4. **Backend Protocol** -- natija `Stream<AiProtocolStreamEvent>`
///    sifatida qaytadi.
/// 5. **Response Mapper** -- [AiResponseMapper] har bir hodisani
///    presentation qatlami ko'radigan [AiClientStreamEvent]ga
///    (`Failure` bilan) tarjima qiladi.
///
/// **Offline Handling (Module 4, Phase 4A):** [connectivityMonitor]
/// berilsa va `currentStatus == offline` bo'lsa, so'rov gateway'ga
/// UMUMAN yuborilmasdan darhol `Failure.network()` bilan yakunlanadi --
/// foydasiz tarmoq urinishi oldini olinadi. `null` (standart) bo'lsa,
/// bu tekshiruv o'tkazib yuboriladi (hozirgi xatti-harakat) -- haqiqiy
/// monitor implementatsiyasi qo'shilganda faqat shu joyga in'ektsiya
/// qilinadi, pipeline'ning o'zi o'zgarmaydi.
class AiRequestPipeline {
  AiRequestPipeline({
    required AiGatewayClient gatewayClient,
    AiDiagnosticsLogger logger = const DebugConsoleAiDiagnosticsLogger(),
    AiConnectivityMonitor? connectivityMonitor,
    String Function()? requestIdGenerator,
    DateTime Function()? clock,
  }) : _gatewayClient = gatewayClient,
       _logger = logger,
       _connectivityMonitor = connectivityMonitor,
       _generateRequestId = requestIdGenerator ?? _defaultRequestIdGenerator,
       _clock = clock ?? DateTime.now;

  final AiGatewayClient _gatewayClient;
  final AiDiagnosticsLogger _logger;
  final AiConnectivityMonitor? _connectivityMonitor;
  final String Function() _generateRequestId;
  final DateTime Function() _clock;

  static int _requestCounter = 0;

  static String _defaultRequestIdGenerator() {
    _requestCounter += 1;
    return 'req_${DateTime.now().microsecondsSinceEpoch}_$_requestCounter';
  }

  Stream<AiClientStreamEvent> sendMessage({
    required AiClientConversation conversation,
    required String userId,
    required String userMessageContent,
    required AiClientContextAssembler contextAssembler,
    Object? credential,
  }) async* {
    final requestId = _generateRequestId();

    if (_connectivityMonitor?.currentStatus == AiConnectivityStatus.offline) {
      _logger.logError('Oflayn holatda so\'rov rad etildi (requestId=$requestId)');
      yield AiClientStreamFailed(
        requestId: requestId,
        conversationId: conversation.id,
        failure: const Failure.network(),
      );
      return;
    }

    final request = AiRequestEnvelope(
      requestId: requestId,
      conversationId: conversation.id,
      userId: userId,
      message: userMessageContent,
      context: contextAssembler.assemble(),
      requestedAt: _clock(),
    );

    _logger.logRequestSent(request);

    await for (final protocolEvent in _gatewayClient.sendMessage(request, credential: credential)) {
      final clientEvent = AiResponseMapper.mapStreamEvent(protocolEvent);
      _logger.logStreamEvent(clientEvent);
      yield clientEvent;
    }
  }
}
