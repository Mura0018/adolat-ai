import '../../domain/entities/ai_cancellation_token.dart';
import '../../domain/entities/ai_provider_id.dart';
import '../../domain/entities/ai_request.dart';
import '../../domain/entities/ai_stream_event.dart';
import 'ai_provider_adapter.dart';

/// Mahalliy (o'z infratuzilmasida joylashtirilgan) LLM uchun
/// `AIProviderAdapter` implementatsiyasi — **foundation skelet**.
///
/// Boshqa provayderlardan farqli o'laroq `apiKey` o'rniga `endpointUrl`
/// oladi — bu `AIProviderAdapter` abstraktsiyasining haqiqatan ham
/// turli xil provayder shakllariga (bulutli API kaliti vs. mahalliy
/// server manzili) moslasha olishini ko'rsatadi, `AIRepository`/domain
/// qatlamining o'zi buni bilishi shart emas.
class LocalLlmProviderAdapter implements AIProviderAdapter {
  const LocalLlmProviderAdapter({required this.endpointUrl, this.model});

  final String endpointUrl;
  final String? model;

  @override
  AIProviderId get providerId => AIProviderId.local;

  @override
  Stream<AIStreamEvent> streamCompletion({
    required AIRequest request,
    AICancellationToken? cancellationToken,
  }) {
    throw UnimplementedError(
      'LocalLlmProviderAdapter.streamCompletion: haqiqiy provayder '
      'integratsiyasi hali qurilmagan (Module 4, Phase 1 — faqat '
      'arxitektura poydevori).',
    );
  }
}
