import 'ai_attachment_metadata.dart';
import 'ai_protocol_version.dart';

/// Flutter klientdan backendga simli (wire) so'rov -- Module 4, Phase
/// 3A talabi: "Request Contract".
///
/// **`AIRequest` (`domain/entities/ai_request.dart`, Phase 1) bilan
/// ADASHTIRILMASIN:** `AIRequest` -- backend ICHIDA, `AIRepository` va
/// `AIProviderAdapter` orasidagi shartnoma, va `providerId`ni o'z
/// ichiga oladi. `AIRequestEnvelope` esa KLIENT ↔ BACKEND chegarasi --
/// va ATAYLAB `providerId`ni O'Z ICHIGA OLMAYDI: qaysi AI provayder
/// (OpenAI/Gemini/Claude/Local) ishlatilishi klientning emas,
/// backendning qarori (`docs/adr/ADR-005-ai-vendor-fallback.md`) --
/// aks holda klient provayder tanlovini "so'rab" provayder
/// mustaqilligini chetlab o'tishi mumkin bo'lardi.
///
/// **`context` nega `AIContext` emas, xom `Map<String, dynamic>`:**
/// simli shartnoma ichki domain modelidan ATAYLAB mustaqil --
/// `ai_service/domain/entities/ai_context.dart` ichki refaktoring
/// natijasida o'zgarsa ham, simli protokol shakli buzilmasligi kerak
/// (va aksincha). Ikkalasi orasidagi tarjima kelgusi integratsiya
/// bosqichida qo'shiladi.
class AIRequestEnvelope {
  const AIRequestEnvelope({
    required this.requestId,
    required this.conversationId,
    required this.userId,
    required this.message,
    this.context = const {},
    this.attachments = const [],
    required this.requestedAt,
    this.protocolVersion = AIProtocolVersion.current,
  });

  final String requestId;
  final String conversationId;
  final String userId;
  final String message;
  final Map<String, dynamic> context;
  final List<AIAttachmentMetadata> attachments;
  final DateTime requestedAt;
  final AIProtocolVersion protocolVersion;

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

  factory AIRequestEnvelope.fromJson(Map<String, dynamic> json) {
    return AIRequestEnvelope(
      requestId: json['requestId'] as String,
      conversationId: json['conversationId'] as String,
      userId: json['userId'] as String,
      message: json['message'] as String,
      context: Map<String, dynamic>.from(json['context'] as Map? ?? const {}),
      attachments: (json['attachments'] as List? ?? const [])
          .map((a) => AIAttachmentMetadata.fromJson(a as Map<String, dynamic>))
          .toList(),
      requestedAt: DateTime.parse(json['requestedAt'] as String),
      protocolVersion: AIProtocolVersion.fromJson(json['protocolVersion']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AIRequestEnvelope) return false;
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
      'AIRequestEnvelope(requestId: $requestId, conversationId: $conversationId, protocolVersion: $protocolVersion)';
}
