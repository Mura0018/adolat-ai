import '../../domain/entities/ai_cancellation_token.dart';
import '../../domain/entities/ai_context.dart';
import '../../domain/entities/ai_conversation.dart';
import '../../domain/entities/ai_failure.dart';
import '../../domain/entities/ai_provider_id.dart';
import '../../domain/entities/ai_request.dart';
import '../../domain/entities/ai_stream_event.dart';
import '../../domain/repositories/ai_repository.dart';
import '../../safety/ai_safety_service.dart';
import '../providers/ai_provider_adapter.dart';

/// `AIRepository`ning yagona implementatsiyasi — o'zi hech qanday
/// provayderni bilmaydi, faqat `providers` xaritasidan `providerId`
/// bo'yicha tanlaydi (`docs/AI_ARCHITECTURE.md`, "Provider
/// Abstraction"). Yangi provayder qo'shish shu klassni O'ZGARTIRISHNI
/// talab qilmaydi — faqat `di/ai_service_locator.dart`dagi xaritaga
/// bitta yozuv qo'shiladi.
class AIRepositoryImpl implements AIRepository {
  AIRepositoryImpl({
    required Map<AIProviderId, AIProviderAdapter> providers,
    required AISafetyService safetyService,
  }) : _providers = providers,
       _safetyService = safetyService;

  final Map<AIProviderId, AIProviderAdapter> _providers;
  final AISafetyService _safetyService;

  @override
  Stream<AIStreamEvent> sendMessage({
    required AIConversation conversation,
    required AIContext context,
    required AIProviderId providerId,
    AICancellationToken? cancellationToken,
  }) async* {
    final adapter = _providers[providerId];
    if (adapter == null) {
      yield AIStreamEventError(
        failure: AIProviderNotConfiguredFailure(providerId: providerId),
      );
      return;
    }

    final request = AIRequest(
      conversationId: conversation.id,
      context: context,
      providerId: providerId,
    );

    // Xavfsizlik qatlami hozircha placeholder (`AISafetyService`da
    // implementatsiya yo'q) — chaqiruv zanjiri shu yerda allaqachon
    // to'g'ri joyga qo'yilgan, shunda kelgusida haqiqiy tekshiruv
    // qo'shilganda bu qatlamga tegilmaydi.
    final requestCheck = await _safetyService.validateRequest(request);
    if (!requestCheck.isSafe) {
      yield AIStreamEventError(
        failure: AISafetyRejectionFailure(
          reason: requestCheck.reason ?? 'So\'rov xavfsizlik tekshiruvidan o\'tmadi',
        ),
      );
      return;
    }

    if (cancellationToken?.isCancelled ?? false) {
      yield const AIStreamEventCancelled();
      return;
    }

    yield* adapter.streamCompletion(
      request: request,
      cancellationToken: cancellationToken,
    );
  }
}
