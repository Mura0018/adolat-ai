import '../data/session/ai_session_manager.dart';
import '../domain/entities/ai_context.dart';
import '../domain/entities/ai_provider_id.dart';
import '../domain/entities/ai_stream_event.dart';
import '../domain/repositories/ai_repository.dart';

/// "Presentation" qatlamining backend-kontekstidagi analogi — bu
/// klass UI emas, balki **tashqi chaqiruvchiga ochilgan kirish nuqtasi**
/// (masalan Supabase Edge Function yoki alohida Dart xizmatining HTTP
/// handler'i shu klassni chaqiradi). Flutter'dagi "ekran" tushunchasi
/// bu yerda yo'q — buning o'rniga "so'rovni qabul qilib, domain
/// qatlamiga uzatish" mas'uliyati bor, xuddi Flutter'dagi
/// `presentation/providers/`ning domain use case'larni chaqirishiga
/// o'xshash (`docs/AI_ARCHITECTURE.md`, "Component Diagram").
///
/// **Muhim:** bu klass hech qachon Flutter ilovasi (`lib/`) tomonidan
/// chaqirilmaydi — faqat backend/serverless muhitda ishlaydi.
class AIServiceHandler {
  AIServiceHandler({
    required AIRepository repository,
    required AISessionManager sessionManager,
  }) : _repository = repository,
       _sessionManager = sessionManager;

  final AIRepository _repository;
  final AISessionManager _sessionManager;

  /// Yangi suhbat boshlaydi va uning identifikatorini qaytaradi.
  String startConversation() {
    return _sessionManager.startConversation().id;
  }

  /// Mavjud suhbatga so'rov yuboradi (Module 4 talabi: "Streaming-ready
  /// design" — natija oqim sifatida qaytariladi).
  Stream<AIStreamEvent> handleRequest({
    required String conversationId,
    required AIContext context,
    required AIProviderId providerId,
  }) async* {
    final conversation = _sessionManager.getConversation(conversationId);
    if (conversation == null) {
      yield AIStreamEventError(
        message: 'Suhbat topilmadi: $conversationId',
      );
      return;
    }

    final cancellationToken = _sessionManager.beginCancellableOperation(
      conversationId,
    );

    yield* _repository
        .sendMessage(
          conversation: conversation,
          context: context,
          providerId: providerId,
          cancellationToken: cancellationToken,
        )
        .map((event) {
          if (event is AIStreamEventDone || event is AIStreamEventError) {
            _sessionManager.endOperation(conversationId);
          }
          return event;
        });
  }

  /// Joriy davom etayotgan so'rovni bekor qiladi (Module 4 talabi:
  /// "Cancellation support").
  void cancelRequest(String conversationId) {
    _sessionManager.cancel(conversationId);
  }
}
