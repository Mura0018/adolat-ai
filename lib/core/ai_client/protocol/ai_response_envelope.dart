import 'ai_protocol_error.dart';
import 'ai_protocol_status.dart';
import 'ai_protocol_version.dart';
import 'ai_token_usage.dart';

/// Backenddan Flutter klientga simli (wire) yakuniy javob. `ai_service/
/// protocol/ai_response_envelope.dart`ning klient tomonidagi mustaqil
/// ko'chirmasi -- bir xil ikkita invariant (`assert`) bilan.
class AiResponseEnvelope {
  AiResponseEnvelope({
    required this.responseId,
    required this.requestId,
    required this.conversationId,
    this.assistantMessage,
    required this.status,
    this.tokenUsage = const AiTokenUsage(),
    this.latencyMs,
    required this.receivedAt,
    required this.respondedAt,
    this.protocolVersion = AiProtocolVersion.current,
    this.error,
  }) : assert(
         status != AiProtocolStatus.failed || error != null,
         'status == failed bo\'lsa, error majburiy',
       ),
       assert(
         status == AiProtocolStatus.completed || assistantMessage == null,
         'assistantMessage faqat status == completed bo\'lganda berilishi mumkin',
       );

  final String responseId;
  final String requestId;
  final String conversationId;
  final String? assistantMessage;
  final AiProtocolStatus status;
  final AiTokenUsage tokenUsage;
  final int? latencyMs;
  final DateTime receivedAt;
  final DateTime respondedAt;
  final AiProtocolVersion protocolVersion;
  final AiProtocolError? error;

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

  factory AiResponseEnvelope.fromJson(Map<String, dynamic> json) {
    return AiResponseEnvelope(
      responseId: json['responseId'] as String,
      requestId: json['requestId'] as String,
      conversationId: json['conversationId'] as String,
      assistantMessage: json['assistantMessage'] as String?,
      status: AiProtocolStatus.values.byName(json['status'] as String),
      tokenUsage: json['tokenUsage'] == null
          ? const AiTokenUsage()
          : AiTokenUsage.fromJson(json['tokenUsage'] as Map<String, dynamic>),
      latencyMs: json['latencyMs'] as int?,
      receivedAt: DateTime.parse(json['receivedAt'] as String),
      respondedAt: DateTime.parse(json['respondedAt'] as String),
      protocolVersion: AiProtocolVersion.fromJson(json['protocolVersion']),
      error: json['error'] == null
          ? null
          : AiProtocolError.fromJson(json['error'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AiResponseEnvelope &&
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
  String toString() => 'AiResponseEnvelope(responseId: $responseId, status: $status)';
}
