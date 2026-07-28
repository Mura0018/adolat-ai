import 'ai_protocol_error.dart';
import 'ai_protocol_version.dart';
import 'ai_response_envelope.dart';

/// Klient ↔ backend oqim (streaming) simli protokolining holatlari --
/// Module 4, Phase 3A talabi: "Streaming Protocol" (faqat holatlar,
/// implementatsiyasiz).
///
/// **`AIStreamEvent` (`domain/entities/ai_stream_event.dart`, Phase 1)
/// bilan ADASHTIRILMASIN:** `AIStreamEvent` -- backend ICHIDA,
/// `AIRepository`/`AIProviderAdapter` orasidagi jarayon-ichi (in-
/// process) shartnoma, faqat 4 holat (`chunk`/`done`/`cancelled`/
/// `error`) -- serializatsiya kerak emas. `AIProtocolStreamEvent` --
/// KLIENT ↔ BACKEND chegarasi, JSON orqali uzatiladi, shuning uchun
/// 5-INCHI holat -- `started` -- qo'shilgan: klient oqim
/// so'ralganidan keyin backend so'rovni QABUL QILGANINI (hali birorta
/// `chunk` kelmasidan oldin) bilishi kerak, aks holda ulanish "jim"
/// (silent) qolganda klient bu tarmoq kechikishimi yoki backend
/// umuman so'rovni olmaganmi -- ajrata olmaydi.
///
/// Har bir variant `toJson()`da `'type'` deb nomlangan ajratuvchi
/// (discriminator) maydonni chiqaradi -- JSON'ning o'zida Dart'ning
/// sealed tur tizimi yo'q, shuning uchun `fromJson()` shu maydon
/// bo'yicha to'g'ri variantni tanlaydi.
///
/// Bu klass ICHKI `AIStreamEvent`ni tashqi `AIProtocolStreamEvent`ga
/// TARJIMA QILMAYDI -- shu tarjima (mapping) kelgusi integratsiya
/// bosqichida, haqiqiy HTTP/WebSocket handler qurilganda qo'shiladi.
sealed class AIProtocolStreamEvent {
  const AIProtocolStreamEvent();

  String get requestId;
  String get conversationId;

  Map<String, dynamic> toJson();

  static AIProtocolStreamEvent fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'started' => AIProtocolStreamEventStarted(
        requestId: json['requestId'] as String,
        conversationId: json['conversationId'] as String,
        protocolVersion: AIProtocolVersion.fromJson(json['protocolVersion']),
      ),
      'chunk' => AIProtocolStreamEventChunk(
        requestId: json['requestId'] as String,
        conversationId: json['conversationId'] as String,
        sequence: json['sequence'] as int,
        deltaContent: json['deltaContent'] as String,
      ),
      'completed' => AIProtocolStreamEventCompleted(
        requestId: json['requestId'] as String,
        response: AIResponseEnvelope.fromJson(json['response'] as Map<String, dynamic>),
      ),
      'cancelled' => AIProtocolStreamEventCancelled(
        requestId: json['requestId'] as String,
        conversationId: json['conversationId'] as String,
      ),
      'failed' => AIProtocolStreamEventFailed(
        requestId: json['requestId'] as String,
        conversationId: json['conversationId'] as String,
        error: AIProtocolError.fromJson(json['error'] as Map<String, dynamic>),
      ),
      _ => throw FormatException('Noma\'lum AIProtocolStreamEvent turi: $type'),
    };
  }
}

/// So'rov backend tomonidan qabul qilindi, oqim boshlanmoqda. Hali
/// hech qanday `chunk` chiqarilmagan.
final class AIProtocolStreamEventStarted extends AIProtocolStreamEvent {
  const AIProtocolStreamEventStarted({
    required this.requestId,
    required this.conversationId,
    this.protocolVersion = AIProtocolVersion.current,
  });

  @override
  final String requestId;
  @override
  final String conversationId;
  final AIProtocolVersion protocolVersion;

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
        (other is AIProtocolStreamEventStarted &&
            other.requestId == requestId &&
            other.conversationId == conversationId &&
            other.protocolVersion == protocolVersion);
  }

  @override
  int get hashCode => Object.hash(requestId, conversationId, protocolVersion);
}

/// Qisman (delta) matn bo'lagi. `sequence` -- 0-asosli, tartibni
/// tekshirish/qayta tartiblash (masalan noaniq yetkazish tartibli
/// transport ustida) uchun.
final class AIProtocolStreamEventChunk extends AIProtocolStreamEvent {
  const AIProtocolStreamEventChunk({
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
        (other is AIProtocolStreamEventChunk &&
            other.requestId == requestId &&
            other.conversationId == conversationId &&
            other.sequence == sequence &&
            other.deltaContent == deltaContent);
  }

  @override
  int get hashCode => Object.hash(requestId, conversationId, sequence, deltaContent);
}

/// Oqim muvaffaqiyatli yakunlandi -- to'liq `AIResponseEnvelope` bilan
/// (`status == AIProtocolStatus.completed`).
final class AIProtocolStreamEventCompleted extends AIProtocolStreamEvent {
  const AIProtocolStreamEventCompleted({required this.requestId, required this.response});

  @override
  final String requestId;
  final AIResponseEnvelope response;

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
        (other is AIProtocolStreamEventCompleted &&
            other.requestId == requestId &&
            other.response == response);
  }

  @override
  int get hashCode => Object.hash(requestId, response);
}

/// Bekor qilindi -- xatolik emas, ataylab to'xtatilgan holat.
final class AIProtocolStreamEventCancelled extends AIProtocolStreamEvent {
  const AIProtocolStreamEventCancelled({required this.requestId, required this.conversationId});

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
        (other is AIProtocolStreamEventCancelled &&
            other.requestId == requestId &&
            other.conversationId == conversationId);
  }

  @override
  int get hashCode => Object.hash(requestId, conversationId);
}

/// Xatolik bilan yakunlandi -- provayderdan mustaqil `AIProtocolError`
/// bilan.
final class AIProtocolStreamEventFailed extends AIProtocolStreamEvent {
  const AIProtocolStreamEventFailed({
    required this.requestId,
    required this.conversationId,
    required this.error,
  });

  @override
  final String requestId;
  @override
  final String conversationId;
  final AIProtocolError error;

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
        (other is AIProtocolStreamEventFailed &&
            other.requestId == requestId &&
            other.conversationId == conversationId &&
            other.error == error);
  }

  @override
  int get hashCode => Object.hash(requestId, conversationId, error);
}
