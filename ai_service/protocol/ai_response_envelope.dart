import 'ai_protocol_error.dart';
import 'ai_protocol_status.dart';
import 'ai_protocol_version.dart';
import 'ai_token_usage.dart';

/// Backenddan Flutter klientga simli (wire) yakuniy javob -- Module 4,
/// Phase 3A talabi: "Response Contract".
///
/// **`AIResponse` (`domain/entities/ai_response.dart`, Phase 1) bilan
/// ADASHTIRILMASIN:** `AIResponse` -- backend ICHIDA, providerdan
/// olingan xom natija. `AIResponseEnvelope` -- KLIENT ↔ BACKEND
/// chegarasidagi, JSON orqali uzatiladigan yakuniy shakl (`docs/
/// AI_ARCHITECTURE.md`, "Xatolik Abstraksiyasi"dagi bir xil sabab
/// bilan `providerId`/ichki turlardan mustaqil).
///
/// **`requestId`:** talab ro'yxatida aniq sanalmagan, lekin qo'shilgan
/// -- `conversationId` bir nechta so'rovni qamrab oladi (bitta
/// suhbatda ko'p xabar), shuning uchun `requestId` bo'lmasa klient bir
/// vaqtning o'zida jo'natilgan bir nechta so'rovdan qaysi biriga shu
/// javob tegishli ekanligini aniqlay olmaydi (masalan foydalanuvchi
/// tezkor ketma-ket ikkita savol yuborsa).
class AIResponseEnvelope {
  AIResponseEnvelope({
    required this.responseId,
    required this.requestId,
    required this.conversationId,
    this.assistantMessage,
    required this.status,
    this.tokenUsage = const AITokenUsage(),
    this.latencyMs,
    required this.receivedAt,
    required this.respondedAt,
    this.protocolVersion = AIProtocolVersion.current,
    this.error,
  }) : assert(
         status != AIProtocolStatus.failed || error != null,
         'status == failed bo\'lsa, error majburiy',
       ),
       assert(
         status == AIProtocolStatus.completed || assistantMessage == null,
         'assistantMessage faqat status == completed bo\'lganda berilishi mumkin -- '
         'ichki AIServiceHandler/SendConversationMessageUseCase konventsiyasi bilan '
         'bir xil: muvaffaqiyatsiz/bekor qilingan javob mazmun olib yurmaydi',
       );

  final String responseId;
  final String requestId;
  final String conversationId;
  final String? assistantMessage;
  final AIProtocolStatus status;
  final AITokenUsage tokenUsage;

  /// Joy ajratilgan (placeholder) -- hozircha har doim `null`.
  final int? latencyMs;

  final DateTime receivedAt;
  final DateTime respondedAt;
  final AIProtocolVersion protocolVersion;

  /// `status == failed` bo'lganda majburiy (yuqoridagi `assert`ga
  /// qarang), aks holda `null`.
  final AIProtocolError? error;

  Map<String, dynamic> toJson() => {
    'responseId': responseId,
    'requestId': requestId,
    'conversationId': conversationId,
    if (assistantMessage != null) 'assistantMessage': assistantMessage,
    'status': status.name,
    'tokenUsage': tokenUsage.toJson(),
    if (latencyMs != null) 'latencyMs': latencyMs,
    'receivedAt': receivedAt.toIso8601String(),
    'respondedAt': respondedAt.toIso8601String(),
    'protocolVersion': protocolVersion.toJson(),
    if (error != null) 'error': error!.toJson(),
  };

  factory AIResponseEnvelope.fromJson(Map<String, dynamic> json) {
    return AIResponseEnvelope(
      responseId: json['responseId'] as String,
      requestId: json['requestId'] as String,
      conversationId: json['conversationId'] as String,
      assistantMessage: json['assistantMessage'] as String?,
      status: AIProtocolStatus.values.byName(json['status'] as String),
      tokenUsage: json['tokenUsage'] == null
          ? const AITokenUsage()
          : AITokenUsage.fromJson(json['tokenUsage'] as Map<String, dynamic>),
      latencyMs: json['latencyMs'] as int?,
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      respondedAt: DateTime.parse(json['respondedAt'] as String),
      protocolVersion: AIProtocolVersion.fromJson(json['protocolVersion']),
      error: json['error'] == null
          ? null
          : AIProtocolError.fromJson(json['error'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AIResponseEnvelope &&
            other.responseId == responseId &&
            other.requestId == requestId &&
            other.conversationId == conversationId &&
            other.assistantMessage == assistantMessage &&
            other.status == status &&
            other.tokenUsage == tokenUsage &&
            other.latencyMs == latencyMs &&
            other.receivedAt == receivedAt &&
            other.respondedAt == respondedAt &&
            other.protocolVersion == protocolVersion &&
            other.error == error);
  }

  @override
  int get hashCode => Object.hash(
    responseId,
    requestId,
    conversationId,
    assistantMessage,
    status,
    tokenUsage,
    latencyMs,
    receivedAt,
    respondedAt,
    protocolVersion,
    error,
  );

  @override
  String toString() =>
      'AIResponseEnvelope(responseId: $responseId, requestId: $requestId, status: $status)';
}
