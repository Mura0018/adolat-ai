import 'ai_protocol_error.dart';
import 'ai_protocol_version.dart';
import 'ai_response_envelope.dart';

/// Klient ↔ backend oqim (streaming) simli protokolining holatlari.
/// `ai_service/protocol/ai_protocol_stream_event.dart`ning klient
/// tomonidagi mustaqil ko'chirmasi -- aynan bir xil 5 holat.
///
/// `mapping/ai_response_mapper.dart` bu turni ilova domenidagi
/// `domain/ai_client_stream_event.dart`ga tarjima qiladi -- qolgan
/// butun ilova (presentation qatlami) bu simli turni to'g'ridan-to'g'ri
/// ko'rmaydi.
sealed class AiProtocolStreamEvent {
  const AiProtocolStreamEvent();

  String get requestId;
  String get conversationId;

  Map<String, dynamic> toJson();

  static AiProtocolStreamEvent fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'started' => AiProtocolStreamEventStarted(
        requestId: json['requestId'] as String,
        conversationId: json['conversationId'] as String,
        protocolVersion: AiProtocolVersion.fromJson(json['protocolVersion']),
      ),
      'chunk' => AiProtocolStreamEventChunk(
        requestId: json['requestId'] as String,
        conversationId: json['conversationId'] as String,
        sequence: json['sequence'] as int,
        deltaContent: json['deltaContent'] as String,
      ),
      'completed' => AiProtocolStreamEventCompleted(
        requestId: json['requestId'] as String,
        response: AiResponseEnvelope.fromJson(json['response'] as Map<String, dynamic>),
      ),
      'cancelled' => AiProtocolStreamEventCancelled(
        requestId: json['requestId'] as String,
        conversationId: json['conversationId'] as String,
      ),
      'failed' => AiProtocolStreamEventFailed(
        requestId: json['requestId'] as String,
        conversationId: json['conversationId'] as String,
        error: AiProtocolError.fromJson(json['error'] as Map<String, dynamic>),
      ),
      _ => throw FormatException('Noma\'lum AiProtocolStreamEvent turi: $type'),
    };
  }
}

/// So'rov backend tomonidan qabul qilindi, oqim boshlanmoqda.
final class AiProtocolStreamEventStarted extends AiProtocolStreamEvent {
  const AiProtocolStreamEventStarted({
    required this.requestId,
    required this.conversationId,
    this.protocolVersion = AiProtocolVersion.current,
  });

  @override
  final String requestId;
  @override
  final String conversationId;
  final AiProtocolVersion protocolVersion;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'started',
    'requestId': requestId,
    'conversationId': conversationId,
    'protocolVersion': protocolVersion.toJson(),
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AiProtocolStreamEventStarted &&
            other.requestId == requestId &&
            other.conversationId == conversationId &&
            other.protocolVersion == protocolVersion);
  }

  @override
  int get hashCode => Object.hash(requestId, conversationId, protocolVersion);
}

/// Qisman (delta) matn bo'lagi. `sequence` -- 0-asosli.
final class AiProtocolStreamEventChunk extends AiProtocolStreamEvent {
  const AiProtocolStreamEventChunk({
    required this.requestId,
    required this.conversationId,
    required this.sequence,
    required this.deltaContent,
  });

  @override
  final String requestId;
  @override
  final String conversationId;
  final int sequence;
  final String deltaContent;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'chunk',
    'requestId': requestId,
    'conversationId': conversationId,
    'sequence': sequence,
    'deltaContent': deltaContent,
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AiProtocolStreamEventChunk &&
            other.requestId == requestId &&
            other.conversationId == conversationId &&
            other.sequence == sequence &&
            other.deltaContent == deltaContent);
  }

  @override
  int get hashCode => Object.hash(requestId, conversationId, sequence, deltaContent);
}

/// Oqim muvaffaqiyatli yakunlandi -- to'liq `AiResponseEnvelope` bilan.
final class AiProtocolStreamEventCompleted extends AiProtocolStreamEvent {
  const AiProtocolStreamEventCompleted({required this.requestId, required this.response});

  @override
  final String requestId;
  final AiResponseEnvelope response;

  @override
  String get conversationId => response.conversationId;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'completed',
    'requestId': requestId,
    'response': response.toJson(),
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AiProtocolStreamEventCompleted &&
            other.requestId == requestId &&
            other.response == response);
  }

  @override
  int get hashCode => Object.hash(requestId, response);
}

/// Bekor qilindi -- xatolik emas, ataylab to'xtatilgan holat.
final class AiProtocolStreamEventCancelled extends AiProtocolStreamEvent {
  const AiProtocolStreamEventCancelled({required this.requestId, required this.conversationId});

  @override
  final String requestId;
  @override
  final String conversationId;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'cancelled',
    'requestId': requestId,
    'conversationId': conversationId,
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AiProtocolStreamEventCancelled &&
            other.requestId == requestId &&
            other.conversationId == conversationId);
  }

  @override
  int get hashCode => Object.hash(requestId, conversationId);
}

/// Xatolik bilan yakunlandi -- provayderdan mustaqil `AiProtocolError` bilan.
final class AiProtocolStreamEventFailed extends AiProtocolStreamEvent {
  const AiProtocolStreamEventFailed({
    required this.requestId,
    required this.conversationId,
    required this.error,
  });

  @override
  final String requestId;
  @override
  final String conversationId;
  final AiProtocolError error;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'failed',
    'requestId': requestId,
    'conversationId': conversationId,
    'error': error.toJson(),
  };

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AiProtocolStreamEventFailed &&
            other.requestId == requestId &&
            other.conversationId == conversationId &&
            other.error == error);
  }

  @override
  int get hashCode => Object.hash(requestId, conversationId, error);
}
