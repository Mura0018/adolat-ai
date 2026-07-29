import '../domain/quota/ai_usage_quota.dart';
import '../protocol/ai_protocol_error.dart';
import '../protocol/ai_protocol_stream_event.dart';
import '../protocol/ai_request_envelope.dart';
import 'ai_gateway.dart';
import 'auth/ai_auth_context.dart';
import 'dispatch/ai_request_dispatcher.dart';
import 'dispatch/ai_response_dispatcher.dart';
import 'endpoint/ai_backend_endpoint.dart';
import 'ratelimit/ai_rate_limiter.dart';
import 'timeout/ai_timeout_guard.dart';
import 'timeout/ai_timeout_policy.dart';

/// `AIGateway`ning yagona implementatsiyasi -- autentifikatsiya
/// tekshiruvi, so'rov dispatch, muddat nazorati va javob dispatchni
/// bitta zanjirga bog'laydi (Module 4, Phase 3B).
///
/// **Zanjir (Phase 4C'dan keyin):** autentifikatsiya tekshiruvi →
/// **rate-limit tekshiruvi (ixtiyoriy)** → **kvota tekshiruvi
/// (ixtiyoriy)** → `AIRequestDispatcher` (ichki usecase'ga yo'naltirish)
/// → `AITimeoutGuard` (muddat nazorati) → `AIResponseDispatcher` (simli
/// formatga tarjima).
///
/// `AIRequestDispatcher.dispatch()`ning o'zi ham `auth`ni tekshiradi
/// (`request.userId` soxtalashtirishga qarshi) -- bu yerdagi tekshiruv
/// FAQAT "umuman autentifikatsiya qilinganmi" (`AIAuthContext.
/// isAuthenticated`) darajasida, chunki bu eng tez, eng arzon rad
/// etish -- provayderga, hatto dispatcher'ning o'ziga ham
/// murojaat qilinmasdan.
///
/// **Phase 4C yangilanishi ("Backend Implementation Readiness"):**
/// [rateLimiter]/[quotaStore] -- Module 4, Phase 4B'da faqat SHAKL
/// sifatida belgilangan `AIRateLimiter`/`AIUsageQuotaStore`
/// kontraktlarini haqiqiy ijro zanjiriga ulaydi. Ikkalasi ham
/// **ixtiyoriy** (standart holatda `null`) -- `null` bo'lganda tekshiruv
/// butunlay o'tkazib yuboriladi, shuning uchun mavjud xatti-harakat
/// (va mavjud testlar) o'zgarishsiz qoladi. Bu -- `AIConnectivityMonitor`
/// (Phase 3B, "hozircha AIGateway/AIGatewayImpl'ning hech qaysi qismiga
/// ulanmagan") bilan solishtirganda bir qadam OLDINGA: endi haqiqiy
/// implementatsiya kelganda faqat shu ikkita parametrni in'ektsiya
/// qilish YETARLI, `AIGatewayImpl`ning o'zi o'zgarmaydi.
class AIGatewayImpl implements AIGateway {
  AIGatewayImpl({
    required AIRequestDispatcher requestDispatcher,
    AIResponseDispatcher responseDispatcher = const AIResponseDispatcher(),
    AITimeoutPolicy timeoutPolicy = const AITimeoutPolicy(),
    AIRateLimiter? rateLimiter,
    AIUsageQuotaStore? quotaStore,
    AIUsageQuotaPolicy? quotaPolicy,
  }) : _requestDispatcher = requestDispatcher,
       _responseDispatcher = responseDispatcher,
       _timeoutGuard = AITimeoutGuard(timeoutPolicy),
       _rateLimiter = rateLimiter,
       _quotaStore = quotaStore,
       _quotaPolicy = quotaPolicy,
       assert(
         quotaStore == null || quotaPolicy != null,
         'quotaStore berilganda quotaPolicy ham majburiy -- kvota qanday '
         'baholanishini bilmasdan tekshiruvni yoqib bo\'lmaydi',
       );

  final AIRequestDispatcher _requestDispatcher;
  final AIResponseDispatcher _responseDispatcher;
  final AITimeoutGuard _timeoutGuard;

  /// `null` bo'lsa (standart holat), rate-limit tekshiruvi butunlay
  /// o'tkazib yuboriladi -- `docs/adr/ADR-004-ai-cost-governance.md`
  /// aniq sonni hali "mahsulot jamoasi bilan kelishilishi kerak" deb
  /// ochiq qoldirgan, shuning uchun bu xususiyat yashirin yoqilmaydi.
  final AIRateLimiter? _rateLimiter;

  final AIUsageQuotaStore? _quotaStore;
  final AIUsageQuotaPolicy? _quotaPolicy;

  @override
  Stream<AIProtocolStreamEvent> handle({
    required AIRequestEnvelope request,
    required AIAuthContext auth,
  }) async* {
    final receivedAt = DateTime.now();

    if (!auth.isAuthenticated || auth.userId == null) {
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

    final userId = auth.userId!;

    if (_rateLimiter != null) {
      final decision = await _rateLimiter.checkAndConsume(
        userId: userId,
        endpoint: AIBackendEndpointId.sendMessage,
      );
      if (!decision.allowed) {
        yield AIProtocolStreamEventFailed(
          requestId: request.requestId,
          conversationId: request.conversationId,
          error: AIProtocolError(
            code: AIProtocolErrorCode.rateLimited,
            message:
                'Juda ko\'p so\'rov yuborildi -- ${decision.status.resetAt.toIso8601String()} '
                'atrofida qayta urinib ko\'ring',
            retryable: true,
          ),
        );
        return;
      }
    }

    if (_quotaStore != null) {
      final policy = _quotaPolicy!;
      final state = await _quotaStore.getState(userId);
      final decision = evaluateUsageQuota(policy: policy, state: state, now: receivedAt);
      if (!decision.allowed) {
        yield AIProtocolStreamEventFailed(
          requestId: request.requestId,
          conversationId: request.conversationId,
          error: AIProtocolError(
            code: AIProtocolErrorCode.quotaExceeded,
            message:
                'Kunlik so\'rov chegarasiga yetdingiz -- ${decision.resetAt.toIso8601String()} '
                'da qayta urinib ko\'ring',
            retryable: false,
          ),
        );
        return;
      }
      await _quotaStore.recordUsage(userId: userId, at: receivedAt);
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
