import '../entities/ai_cancellation_token.dart';
import '../entities/ai_conversation.dart';
import '../entities/ai_context.dart';
import '../entities/ai_provider_id.dart';
import '../entities/ai_stream_event.dart';

/// AI so'rovlari ustidagi yagona abstrakt shartnoma — `ai_service/data/`
/// qatlamidagi implementatsiya qaysi provayder (OpenAI/Gemini/Claude/
/// Local LLM) ishlatilishini butunlay yashiradi
/// (`docs/AI_ARCHITECTURE.md`, "Provider Abstraction").
///
/// **Muhim (loyiha xavfsizlik chegarasi):** bu interfeys va uning
/// implementatsiyasi `ai_service/` papkasida — Flutter mobil ilova
/// (`lib/`) qismi EMAS va hech qachon import qilinmasligi kerak
/// (`docs/ARCHITECTURE.md`, "AI Service": "AI Service klient tomonidan
/// to'g'ridan-to'g'ri chaqirilmaydi"). Bu kod kelgusida backend/
/// serverless muhitda (masalan Supabase Edge Function yoki alohida
/// Dart xizmati) joylashtirilishi mo'ljallangan.
abstract interface class AIRepository {
  /// Berilgan suhbatga (`AIConversation`) yangi so'rov yuboradi va
  /// natijani oqim sifatida qaytaradi (streaming-ready — Module 4
  /// talabi). Bitta yakuniy javob beruvchi provayderlar uchun ham
  /// oqim ishlatiladi — u holda faqat bitta `AIStreamEvent.done`
  /// chiqariladi.
  ///
  /// [cancellationToken] berilsa va bekor qilinsa, oqim
  /// `AIStreamEvent.cancelled()` bilan yakunlanadi.
  Stream<AIStreamEvent> sendMessage({
    required AIConversation conversation,
    required AIContext context,
    required AIProviderId providerId,
    AICancellationToken? cancellationToken,
  });
}
