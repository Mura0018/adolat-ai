import 'ai_provider_id.dart';

/// AI provayderdan olingan yakuniy javob (streaming tugagandan keyingi
/// to'liq natija — `AIStreamEvent.done`ga qarang).
///
/// `modelVersion` majburiy — `docs/DATABASE.md`, 8-jadval
/// (`ai_analyses.model_version`) bilan bir xil audit talabini aks
/// ettiradi: qaysi model versiyasi javob berganini har doim bilish
/// kerak.
///
/// Freezed ishlatilmagan sababi: `ai_message.dart`dagi izohga qarang.
class AIResponse {
  const AIResponse({
    required this.id,
    required this.conversationId,
    required this.content,
    required this.providerId,
    required this.modelVersion,
    required this.completedAt,
  });

  final String id;
  final String conversationId;
  final String content;
  final AIProviderId providerId;
  final String modelVersion;
  final DateTime completedAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIResponse &&
            other.id == id &&
            other.conversationId == conversationId &&
            other.content == content &&
            other.providerId == providerId &&
            other.modelVersion == modelVersion &&
            other.completedAt == completedAt);
  }

  @override
  int get hashCode => Object.hash(
    id,
    conversationId,
    content,
    providerId,
    modelVersion,
    completedAt,
  );

  @override
  String toString() =>
      'AIResponse(id: $id, conversationId: $conversationId, providerId: $providerId)';
}
