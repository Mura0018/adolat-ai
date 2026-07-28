import '../../domain/entities/ai_cancellation_token.dart';
import '../../domain/entities/ai_provider_id.dart';
import '../../domain/entities/ai_request.dart';
import '../../domain/entities/ai_stream_event.dart';
import 'ai_provider_adapter.dart';

/// Google Gemini uchun `AIProviderAdapter` implementatsiyasi —
/// **foundation skelet**. `OpenAiProviderAdapter`dagi izohga qarang —
/// bir xil xavfsizlik va ko'lam cheklovlari amal qiladi.
class GeminiProviderAdapter implements AIProviderAdapter {
  const GeminiProviderAdapter({
    required this.apiKey,
    this.model = 'gemini-1.5-pro',
  });

  final String apiKey;
  final String model;

  @override
  AIProviderId get providerId => AIProviderId.gemini;

  @override
  Stream<AIStreamEvent> streamCompletion({
    required AIRequest request,
    AICancellationToken? cancellationToken,
  }) {
    throw UnimplementedError(
      'GeminiProviderAdapter.streamCompletion: haqiqiy provayder '
      'integratsiyasi hali qurilmagan (Module 4, Phase 1 — faqat '
      'arxitektura poydevori).',
    );
  }
}
