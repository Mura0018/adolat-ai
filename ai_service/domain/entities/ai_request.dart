import 'ai_context.dart';
import 'ai_provider_id.dart';

/// `AIRepository`ga yuboriladigan so'rov — qaysi suhbatga, qaysi
/// tarkib (context) bilan, qaysi provayder orqali.
///
/// `providerId` so'rovning o'zida yuriladi (data qatlamidagi
/// `AIProviderAdapter`ni tanlash uchun), lekin domain qatlami bu
/// qiymatning ORTIDA nima borligini (API kaliti, HTTP endpoint)
/// bilmaydi — faqat identifikator (`docs/AI_ARCHITECTURE.md`, "Provider
/// Abstraction").
///
/// Freezed ishlatilmagan sababi: `ai_message.dart`dagi izohga qarang.
class AIRequest {
  const AIRequest({
    required this.conversationId,
    required this.context,
    required this.providerId,
  });

  final String conversationId;
  final AIContext context;
  final AIProviderId providerId;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIRequest &&
            other.conversationId == conversationId &&
            other.context == context &&
            other.providerId == providerId);
  }

  @override
  int get hashCode => Object.hash(conversationId, context, providerId);

  @override
  String toString() =>
      'AIRequest(conversationId: $conversationId, providerId: $providerId)';
}
