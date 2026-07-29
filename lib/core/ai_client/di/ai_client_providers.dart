import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai_request_pipeline.dart';
import '../gateway/ai_gateway_client.dart';
import '../logging/ai_diagnostics_logger.dart';
import '../mock/mock_ai_gateway_client.dart';

/// **Kelgusi backend almashtirish nuqtasi (`docs/AI_ARCHITECTURE.md`,
/// "Kelgusi backend almashtirish strategiyasi"):** hozircha
/// [MockAiGatewayClient]ga bog'langan -- haqiqiy backend qurilganda
/// (Module 4, Phase 4A'dan keyingi bosqich) shu bitta provayder
/// `HttpAiGatewayClient`/`WebSocketAiGatewayClient`ga almashtiriladi.
/// `AiGatewayClient` interfeysidan foydalanadigan hech qanday boshqa kod
/// (`aiRequestPipelineProvider`, kelgusi chat controller/UI) o'zgarmaydi.
final aiGatewayClientProvider = Provider<AiGatewayClient>((ref) {
  return const MockAiGatewayClient();
});

final aiDiagnosticsLoggerProvider = Provider<AiDiagnosticsLogger>((ref) {
  return const DebugConsoleAiDiagnosticsLogger();
});

final aiRequestPipelineProvider = Provider<AiRequestPipeline>((ref) {
  return AiRequestPipeline(
    gatewayClient: ref.watch(aiGatewayClientProvider),
    logger: ref.watch(aiDiagnosticsLoggerProvider),
  );
});
