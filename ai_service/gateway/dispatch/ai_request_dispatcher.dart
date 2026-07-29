import '../../domain/entities/ai_context.dart';
import '../../domain/entities/ai_failure.dart';
import '../../domain/entities/ai_provider_id.dart';
import '../../domain/entities/ai_stream_event.dart';
import '../../domain/usecases/send_conversation_message_usecase.dart';
import '../../protocol/ai_request_envelope.dart';
import '../auth/ai_auth_context.dart';

/// Simli `AIRequestEnvelope`ni ichki `SendConversationMessageUseCase`
/// chaqiruviga aylantiradi (Module 4, Phase 3B talabi: "Request
/// Dispatcher").
///
/// **Ko'lam:** `AIRequestEnvelope` (Phase 3A) faqat "xabar yuborish"
/// amalini ifodalaydi (`message` maydoni bilan) -- suhbat
/// boshlash/bekor qilish/yopish uchun alohida konvert turi hali
/// yo'q, shuning uchun bu dispatcher faqat `SendConversationMessageUseCase`ga
/// yo'naltiradi. Boshqa amallar uchun marshrutlash kelgusi bosqichda.
///
/// **Xavfsizlik tekshiruvi (Authentication Boundary bilan bog'liq):**
/// `request.userId` -- KLIENT da'vosi, `auth.userId` -- autentifikatsiya
/// qatlami TASDIQLAGAN shaxs. Ikkalasi mos kelmasa (`request.userId
/// != auth.userId`), so'rov soxtalashtirish urinishi sifatida rad
/// etiladi (`AIUnauthorizedFailure`) -- provayderga umuman murojaat
/// qilinmaydi.
///
/// **`context` tarjimasi:** `AIRequestEnvelope.context` (xom
/// `Map<String, dynamic>`, Phase 3A'da ichki `AIContext`dan ATAYLAB
/// mustaqil qilingan) shu yerda `AIContext.sections`ning kutilgan
/// shakliga (`Map<String, Map<String, dynamic>>`) aylantiriladi. Shakl
/// mos kelmasa (masalan ichki qiymat `Map` emas), `AIInvalidRequestFailure`
/// bilan yakunlanadi -- bu KLIENT xatosi, backend ichki xatosi emas.
class AIRequestDispatcher {
  const AIRequestDispatcher({
    required SendConversationMessageUseCase sendMessageUseCase,
    required AIProviderId Function(AIRequestEnvelope request) selectProvider,
  }) : _sendMessageUseCase = sendMessageUseCase,
       _selectProvider = selectProvider;

  final SendConversationMessageUseCase _sendMessageUseCase;

  /// Qaysi AI provayder ushbu so'rovga xizmat qilishini backend hal
  /// qiladi (`docs/adr/ADR-005-ai-vendor-fallback.md`) -- klient bu
  /// haqda hech narsa so'ramaydi (`AIRequestEnvelope`da `providerId`
  /// yo'qligiga qarang). Haqiqiy tanlov strategiyasi (fallback
  /// zanjiri, yuklama balansi) kelgusi bosqich -- bu yerda faqat
  /// chaqiruvchi tomonidan in'ektsiya qilinadigan joy ajratilgan.
  final AIProviderId Function(AIRequestEnvelope request) _selectProvider;

  Stream<AIStreamEvent> dispatch(
    AIRequestEnvelope request, {
    required AIAuthContext auth,
  }) async* {
    if (!auth.isAuthenticated || auth.userId != request.userId) {
      yield const AIStreamEventError(failure: AIUnauthorizedFailure());
      return;
    }

    final AIContext context;
    try {
      context = AIContext(
        sections: request.context.map(
          (key, value) => MapEntry(key, Map<String, dynamic>.from(value as Map)),
        ),
      );
    } on TypeError {
      yield const AIStreamEventError(
        failure: AIInvalidRequestFailure(
          reason: 'context maydoni Map<String, Map<String, dynamic>> shaklida emas',
        ),
      );
      return;
    }

    yield* _sendMessageUseCase(
      conversationId: request.conversationId,
      userMessageContent: request.message,
      context: context,
      providerId: _selectProvider(request),
    );
  }
}
