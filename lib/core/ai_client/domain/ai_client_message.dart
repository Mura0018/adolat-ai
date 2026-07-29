import 'ai_client_message_role.dart';

/// Klient tomonidagi suhbat tarixidagi bitta xabar -- backend `AIMessage`
/// bilan kontseptual mos (`ai_protocol_version.dart`dagi mustaqillik
/// izohiga qarang), lekin `AiResponseMapper` tomonidan `AiResponseEnvelope`
/// asosida ham qurilishi mumkin (assistant javobi).
///
/// `Failure`/`Result<T>` konventsiyasi (`core/error/`) bilan bir xil
/// ruhda -- oddiy, o'zgarmas (immutable) qiymat turi.
class AiClientMessage {
  const AiClientMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  final String id;
  final AiClientMessageRole role;
  final String content;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AiClientMessage &&
            other.id == id &&
            other.role == role &&
            other.content == content &&
            other.createdAt == createdAt);
  }

  @override
  int get hashCode => Object.hash(id, role, content, createdAt);

  @override
  String toString() => 'AiClientMessage(id: $id, role: $role)';
}
