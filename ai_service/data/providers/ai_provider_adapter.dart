import '../../domain/entities/ai_cancellation_token.dart';
import '../../domain/entities/ai_provider_id.dart';
import '../../domain/entities/ai_request.dart';
import '../../domain/entities/ai_stream_event.dart';

/// Har bir AI provayder (OpenAI/Gemini/Claude/Local LLM) shu shartnomani
/// amalga oshiradi. `AIRepositoryImpl` faqat shu interfeys bilan
/// ishlaydi — provayderga xos SDK/HTTP tafsilotlari bu qatlamdan
/// tashqariga chiqmaydi (`docs/AI_ARCHITECTURE.md`, "Provider
/// Abstraction").
///
/// **Yangi provayder qo'shish** = shu interfeysni amalga oshiruvchi
/// bitta yangi klass + `ai_service/di/ai_service_locator.dart`da bitta
/// qator — boshqa hech narsa (domain, repository, prompt pipeline)
/// o'zgarmaydi.
abstract interface class AIProviderAdapter {
  AIProviderId get providerId;

  /// Foundation bosqichida barcha implementatsiyalar `UnimplementedError`
  /// tashlaydi — haqiqiy provayder chaqiruvi (HTTP/SDK) va prompt
  /// mazmuni Module 4, Phase 1 doirasidan tashqarida.
  Stream<AIStreamEvent> streamCompletion({
    required AIRequest request,
    AICancellationToken? cancellationToken,
  });
}
