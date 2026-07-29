import '../protocol/ai_protocol_error.dart';
import '../protocol/ai_protocol_stream_event.dart';
import '../protocol/ai_request_envelope.dart';
import 'ai_gateway.dart';
import 'auth/ai_auth_context.dart';
import 'dispatch/ai_request_dispatcher.dart';
import 'dispatch/ai_response_dispatcher.dart';
import 'timeout/ai_timeout_guard.dart';
import 'timeout/ai_timeout_policy.dart';

/// `AIGateway`ning yagona implementatsiyasi -- autentifikatsiya
/// tekshiruvi, so'rov dispatch, muddat nazorati va javob dispatchni
/// bitta zanjirga bog'laydi (Module 4, Phase 3B).
///
/// **Zanjir:** autentifikatsiya tekshiruvi → `AIRequestDispatcher`
/// (ichki usecase'ga yo'naltirish) → `AITimeoutGuard` (muddat nazorati)
/// → `AIResponseDispatcher` (simli formatga tarjima).
///
/// `AIRequestDispatcher.dispatch()`ning o'zi ham `auth`ni tekshiradi
/// (`request.userId` soxtalashtirishga qarshi) -- bu yerdagi tekshiruv
/// FAQAT "umuman autentifikatsiya qilinganmi" (`AIAuthContext.
/// isAuthenticated`) darajasida, chunki bu eng tez, eng arzon rad
/// etish -- provayderga, hatto dispatcher'ning o'ziga ham
/// murojaat qilinmasdan.
class AIGatewayImpl implements AIGateway {
  AIGatewayImpl({
    required AIRequestDispatcher requestDispatcher,
    AIResponseDispatcher responseDispatcher = const AIResponseDispatcher(),
    AITimeoutPolicy timeoutPolicy = const AITimeoutPolicy(),
  }) : _requestDispatcher = requestDispatcher,
       _responseDispatcher = responseDispatcher,
       _timeoutGuard = AITimeoutGuard(timeoutPolicy);

  final AIRequestDispatcher _requestDispatcher;
  final AIResponseDispatcher _responseDispatcher;
  final AITimeoutGuard _timeoutGuard;

  @override
  Stream<AIProtocolStreamEvent> handle({
    required AIRequestEnvelope request,
    required AIAuthContext auth,
  }) async* {
    final receivedAt = DateTime.now();

    if (!auth.isAuthenticated) {
      yield AIProtocolStreamEventFailed(
        requestId: request.requestId,
        conversationId: request.conversationId,
        error: const AIProtocolError(
          code: AIProtocolErrorCode.unauthenticated,
          message: 'Autentifikatsiyadan o\'tilmagan',
          retryable: false,
        ),
      );
      return;
    }

    final internalEvents = _timeoutGuard.guard(
      _requestDispatcher.dispatch(request, auth: auth),
    );

    yield* _responseDispatcher.dispatch(
      request: request,
      receivedAt: receivedAt,
      events: internalEvents,
    );
  }
}
