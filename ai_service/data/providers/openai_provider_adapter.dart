import '../../domain/entities/ai_cancellation_token.dart';
import '../../domain/entities/ai_provider_id.dart';
import '../../domain/entities/ai_request.dart';
import '../../domain/entities/ai_stream_event.dart';
import 'ai_provider_adapter.dart';

/// OpenAI uchun `AIProviderAdapter` implementatsiyasi — **foundation
/// skelet**. `apiKey` faqat server-tomon environment o'zgaruvchisidan
/// o'qilishi mo'ljallangan (klient binariga hech qachon joylashtirilmaydi
/// — `docs/SECURITY.md`, "Secrets Management").
///
/// Haqiqiy HTTP/SDK chaqiruvi va prompt shakllantirish Module 4,
/// Phase 1 doirasidan tashqarida.
class OpenAiProviderAdapter implements AIProviderAdapter {
  const OpenAiProviderAdapter({required this.apiKey, this.model = 'gpt-4o'});

  final String apiKey;
  final String model;

  @override
  AIProviderId get providerId => AIProviderId.openAI;

  @override
  Stream<AIStreamEvent> streamCompletion({
    required AIRequest request,
    AICancellationToken? cancellationToken,
  }) {
    throw UnimplementedError(
      'OpenAiProviderAdapter.streamCompletion: haqiqiy provayder '
      'integratsiyasi hali qurilmagan (Module 4, Phase 1 — faqat '
      'arxitektura poydevori).',
    );
  }
}
