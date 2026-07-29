import 'ai_attachment_metadata.dart';
import 'ai_protocol_version.dart';

/// Flutter klientdan backendga simli (wire) so'rov. `ai_service/protocol/
/// ai_request_envelope.dart`ning klient tomonidagi mustaqil ko'chirmasi.
///
/// **`providerId` ATAYLAB yo'q:** qaysi AI provayder ishlatilishi
/// klientning emas, backendning qarori (`docs/adr/ADR-005-ai-vendor-
/// fallback.md`).
///
/// **`context` -- `Map<String, dynamic>`:** `AiClientContextAssembler`
/// (`../context/`) natijasi shu maydonga to'g'ridan-to'g'ri joylanadi --
/// simli shartnoma ichki domain modelidan mustaqil bo'lib qolishi kerak.
class AiRequestEnvelope {
  const AiRequestEnvelope({
    required this.requestId,
    required this.conversationId,
    required this.userId,
    required this.message,
    this.context = const {},
    this.attachments = const [],
    required this.requestedAt,
    this.protocolVersion = AiProtocolVersion.current,
  });

  final String requestId;
  final String conversationId;
  final String userId;
  final String message;
  final Map<String, dynamic> context;
  final List<AiAttachmentMetadata> attachments;
  final DateTime requestedAt;
  final AiProtocolVersion protocolVersion;

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'conversationId': conversationId,
    'userId': userId,
    'message': message,
    'context': context,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'requestedAt': requestedAt.toIso8601String(),
    'protocolVersion': protocolVersion.toJson(),
  };

  factory AiRequestEnvelope.fromJson(Map<String, dynamic> json) {
    return AiRequestEnvelope(
      requestId: json['requestId'] as String,
      conversationId: json['conversationId'] as String,
      userId: json['userId'] as String,
      message: json['message'] as String,
      context: Map<String, dynamic>.from(json['context'] as Map? ?? const {}),
      attachments: (json['attachments'] as List? ?? const [])
          .map((a) => AiAttachmentMetadata.fromJson(a as Map<String, dynamic>))
          .toList(),
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      protocolVersion: AiProtocolVersion.fromJson(json['protocolVersion']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AiRequestEnvelope) return false;
    if (other.requestId != requestId ||
        other.conversationId != conversationId ||
        other.userId != userId ||
        other.message != message ||
        other.requestedAt != requestedAt ||
        other.protocolVersion != protocolVersion ||
        other.context.toString() != context.toString() ||
        other.attachments.length != attachments.length) {
      return false;
    }
    for (var i = 0; i < attachments.length; i++) {
      if (other.attachments[i] != attachments[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    requestId,
    conversationId,
    userId,
    message,
    context.toString(),
    Object.hashAll(attachments),
    requestedAt,
    protocolVersion,
  );

  @override
  String toString() =>
      'AiRequestEnvelope(requestId: $requestId, conversationId: $conversationId)';
}
