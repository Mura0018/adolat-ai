import '../domain/entities/ai_context.dart';
import '../domain/entities/ai_conversation.dart';
import '../domain/entities/ai_provider_id.dart';
import '../domain/entities/ai_stream_event.dart';
import '../domain/usecases/cancel_conversation_usecase.dart';
import '../domain/usecases/close_conversation_usecase.dart';
import '../domain/usecases/send_conversation_message_usecase.dart';
import '../domain/usecases/start_conversation_usecase.dart';

/// "Presentation" qatlamining backend-kontekstidagi analogi — bu
/// klass UI emas, balki **tashqi chaqiruvchiga ochilgan kirish nuqtasi**
/// (masalan Supabase Edge Function yoki alohida Dart xizmatining HTTP
/// handler'i shu klassni chaqiradi). Flutter'dagi "ekran" tushunchasi
/// bu yerda yo'q — buning o'rniga "so'rovni qabul qilib, domain
/// qatlamiga uzatish" mas'uliyati bor, xuddi Flutter'dagi
/// `presentation/providers/`ning domain use case'larni chaqirishiga
/// o'xshash (`docs/AI_ARCHITECTURE.md`, "Component Diagram").
///
/// **Phase 2C'dan beri qasddan "yupqa" (thin):** suhbat tarixi bilan
/// bog'lanish, qayta urinish, xatolikni turlash kabi biznes qoidalari
/// endi `domain/usecases/`da — bu klass faqat kirish parametrlarini
/// mos usecase'ga uzatadi, hech qanday qaror qabul qilmaydi.
///
/// **Muhim:** bu klass hech qachon Flutter ilovasi (`lib/`) tomonidan
/// chaqirilmaydi — faqat backend/serverless muhitda ishlaydi.
class AIServiceHandler {
  const AIServiceHandler({
    required StartConversationUseCase startConversationUseCase,
    required SendConversationMessageUseCase sendConversationMessageUseCase,
    required CancelConversationUseCase cancelConversationUseCase,
    required CloseConversationUseCase closeConversationUseCase,
  }) : _startConversationUseCase = startConversationUseCase,
       _sendConversationMessageUseCase = sendConversationMessageUseCase,
       _cancelConversationUseCase = cancelConversationUseCase,
       _closeConversationUseCase = closeConversationUseCase;

  final StartConversationUseCase _startConversationUseCase;
  final SendConversationMessageUseCase _sendConversationMessageUseCase;
  final CancelConversationUseCase _cancelConversationUseCase;
  final CloseConversationUseCase _closeConversationUseCase;

  /// Yangi suhbat boshlaydi va uning identifikatorini qaytaradi.
  String startConversation() => _startConversationUseCase();

  /// Mavjud suhbatga foydalanuvchi xabarini yozadi, AI so'rovini
  /// yuboradi va natijani oqim sifatida qaytaradi. To'liq orkestratsiya
  /// mantig'i: `domain/usecases/send_conversation_message_usecase.dart`.
  Stream<AIStreamEvent> handleRequest({
    required String conversationId,
    required String userMessageContent,
    required AIContext context,
    required AIProviderId providerId,
  }) {
    return _sendConversationMessageUseCase(
      conversationId: conversationId,
      userMessageContent: userMessageContent,
      context: context,
      providerId: providerId,
    );
  }

  /// Joriy davom etayotgan so'rovni bekor qiladi (Module 4 talabi:
  /// "Cancellation support").
  void cancelRequest(String conversationId) {
    _cancelConversationUseCase(conversationId);
  }

  /// Suhbatni yopadi.
  AIConversation closeConversation(String conversationId) {
    return _closeConversationUseCase(conversationId);
  }
}
